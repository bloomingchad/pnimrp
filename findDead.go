package main

import (
	"bufio"
	"crypto/tls"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"
)

type LinkCheckResult struct {
	StationName string `json:"stationName"`
	URL         string `json:"url"`
	Valid       bool   `json:"valid"`
	Error       string `json:"error"`
}

const (
	maxRetries       = 3
	initialBackoff   = 1 * time.Second
	maxBackoff       = 10 * time.Second
	concurrencyLimit = 20
	logFileName      = "finddead.log"
)

var (
	disableEmoji bool
	logger       *log.Logger
)

func init() {
	// Command-line flags
	flag.BoolVar(&disableEmoji, "disable-emoji", false, "Disable emoji in output")
	flag.Parse()

	// Set up logging
	file, err := os.OpenFile(logFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Println("Failed to open log file, using default stderr")
		logger = log.New(os.Stderr, "", log.LstdFlags)
	} else {
		logger = log.New(file, "", log.LstdFlags)
	}
}

// isLikelyICY checks if the URL is likely to be an ICY stream based on heuristics
func isLikelyICY(urlStr string) bool {
	// Check if the URL path ends with /; or has no extension
	lowerURL := strings.ToLower(urlStr)
	return strings.HasSuffix(lowerURL, "/;") || !strings.Contains(filepath.Base(lowerURL), ".")
}

// checkURL performs a GET request to check the URL, handling redirects and ICY streams
func checkURL(urlStr string, stationName string) *LinkCheckResult {
	result := &LinkCheckResult{URL: urlStr, StationName: stationName}

	// Handle empty URL string
	if urlStr == "" {
		result.Error = "Empty URL"
		logger.Printf("Empty URL provided for station: %s", stationName)
		return result
	}

	// Force HTTP if no protocol is specified
	if !strings.HasPrefix(strings.ToLower(urlStr), "http://") && !strings.HasPrefix(strings.ToLower(urlStr), "https://") {
		logger.Printf("No protocol specified for %s, defaulting to http://", urlStr)
		result.URL = "http://" + urlStr
	} else {
		result.URL = urlStr
	}

	// Check if the URL is likely an ICY stream
	if isLikelyICY(result.URL) {
		logger.Printf("Likely ICY stream detected, using specialized check: %s", result.URL)
		icyResult := checkICYStream(result.URL, stationName)
		if icyResult.Valid {
			// It's a valid ICY stream
			return icyResult
		} else {
			// It's not a valid ICY stream, log the error and fall back to regular HTTP check
			logger.Printf("ICY check failed for %s: %s", result.URL, icyResult.Error)
		}
	}

	// Create a custom transport that skips TLS verification
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}

	client := &http.Client{
		Transport: tr,
		Timeout:   15 * time.Second,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("too many redirects")
			}
			// Update the URL in the result to the redirected URL
			result.URL = req.URL.String()
			return nil
		},
	}

	for attempt := 0; attempt < maxRetries; attempt++ {
		logger.Printf("Checking URL (attempt %d): %s", attempt+1, result.URL)

		req, err := http.NewRequest("GET", result.URL, nil)
		if err != nil {
			result.Error = "Invalid URL - " + err.Error()
			logger.Printf("Invalid URL: %s - Error: %v", result.URL, err)
			return result
		}

		// Set headers
		req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36")
		req.Header.Set("Accept", "*/*")
		req.Header.Set("Connection", "keep-alive")
		req.Header.Set("Icy-MetaData", "1")

		resp, err := client.Do(req)
		if err != nil {
			// Handle errors, including timeouts and protocol scheme errors
			if urlErr, ok := err.(*url.Error); ok {
				if urlErr.Timeout() {
					result.Error = "Timeout"
				} else if strings.Contains(urlErr.Error(), "unsupported protocol scheme") {
					result.Error = fmt.Sprintf("Unsupported protocol: %s", urlErr.URL)
				} else if strings.Contains(urlErr.Error(), "tls: handshake failure") {
					result.Error = "TLS handshake failure"
				} else {
					result.Error = urlErr.Error()
				}
			} else {
				result.Error = err.Error()
			}

			logger.Printf("Error during GET request: %s - Error: %v", result.URL, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}
		defer resp.Body.Close()

		// Check for successful HTTP status codes
		if resp.StatusCode >= 200 && resp.StatusCode < 400 {
			result.Valid = true
			logger.Printf("Valid stream found: %s", result.URL)
			return result
		} else {
			result.Error = fmt.Sprintf("HTTP %d", resp.StatusCode)
			logger.Printf("HTTP error: %s - %s", result.URL, result.Error)
			time.Sleep(getBackoffTime(attempt))
			continue
		}
	}

	return result
}

// checkICYStream performs a specialized check for ICY streams
func checkICYStream(urlStr string, stationName string) *LinkCheckResult {
	result := &LinkCheckResult{URL: urlStr, StationName: stationName}

	for attempt := 0; attempt < maxRetries; attempt++ {
		// Use net.Dial to establish a raw TCP connection
		conn, err := net.Dial("tcp", getHostAndPort(urlStr))
		if err != nil {
			result.Error = "Connection error: " + err.Error()
			logger.Printf("Error connecting to %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}
		defer conn.Close()

		// Send a custom GET request with Icy-MetaData
		request := fmt.Sprintf("GET / HTTP/1.0\r\nHost: %s\r\nIcy-MetaData: 1\r\nConnection: close\r\n\r\n", getHost(urlStr))
		if _, err = conn.Write([]byte(request)); err != nil {
			result.Error = "Error sending request: " + err.Error()
			logger.Printf("Error sending request to %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}

		// Read the response
		reader := bufio.NewReader(conn)
		response, err := reader.ReadString('\n')
		if err != nil {
			result.Error = "Error reading response: " + err.Error()
			logger.Printf("Error reading response from %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}

		// Check if it's an ICY response
		if strings.HasPrefix(response, "ICY") {
			logger.Printf("ICY stream detected (valid): %s", urlStr)
			result.Valid = true

			// Optionally, you could read and discard headers here if needed

			return result
		} else {
			result.Error = "Not a valid ICY stream"
			logger.Printf("Not a valid ICY stream: %s", urlStr)
			time.Sleep(getBackoffTime(attempt))
			// Don't return immediately, allow fallback to HTTP check
			break
		}
	}

	return result
}

// getHostAndPort extracts the host and port from a URL
func getHostAndPort(urlStr string) string {
	u, err := url.Parse(urlStr)
	if err != nil {
		return ""
	}
	if u.Port() == "" {
		if u.Scheme == "https" {
			return u.Host + ":443"
		}
		return u.Host + ":80"
	}
	return u.Host
}

// getHost extracts the host from a URL
func getHost(urlStr string) string {
	u, err := url.Parse(urlStr)
	if err != nil {
		return ""
	}
	return u.Host
}

// parseInt converts a string to an integer
func parseInt(str string) (int, error) {
	var result int
	_, err := fmt.Sscan(str, &result)
	return result, err
}

// getBackoffTime calculates the exponential backoff time
func getBackoffTime(attempt int) time.Duration {
	backoff := initialBackoff * time.Duration(1<<attempt)
	if backoff > maxBackoff {
		return maxBackoff
	}
	return backoff
}

// extractURLsFromM3U parses an M3U/M3U8 file and returns a list of URLs
func extractURLsFromM3U(m3uContent string) []string {
	var urls []string
	scanner := bufio.NewScanner(strings.NewReader(m3uContent))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "#") {
			continue // Skip comments
		}
		if strings.HasPrefix(line, "http") {
			urls = append(urls, line)
		}
	}
	return urls
}

// extractURLsFromPLS parses a PLS file and returns a list of URLs
func extractURLsFromPLS(plsContent string) []string {
	var urls []string
	scanner := bufio.NewScanner(strings.NewReader(plsContent))
	re := regexp.MustCompile(`File\d+=(.*)`)
	for scanner.Scan() {
		line := scanner.Text()
		matches := re.FindStringSubmatch(line)
		if len(matches) > 1 {
			urls = append(urls, matches[1])
		}
	}
	return urls
}

func processJSONFile(filePath string, wg *sync.WaitGroup, resultsChan chan<- *LinkCheckResult, limiter chan struct{}) {
	defer wg.Done()

	logger.Printf("Processing JSON file: %s", filePath)

	fileData, err := os.ReadFile(filePath)
	if err != nil {
		logger.Printf("Error reading file: %s - Error: %v", filePath, err)
		return
	}

	var jsonData map[string]interface{}
	err = json.Unmarshal(fileData, &jsonData)
	if err != nil {
		logger.Printf("Error parsing JSON: %s - Error: %v", filePath, err)
		return
	}

	stations, ok := jsonData["stations"].(map[string]interface{})
	if !ok {
		logger.Printf("No stations found in %s", filePath)
		return
	}

	var innerWg sync.WaitGroup
	for name, urlInterface := range stations {
		urlStr, ok := urlInterface.(string)
		if !ok {
			logger.Printf("Invalid URL format for %s", name)
			continue
		}

		innerWg.Add(1)
		go func(name string, urlStr string) {
			defer innerWg.Done()
			limiter <- struct{}{}
			defer func() { <-limiter }()

			// Check if the URL is a playlist
			if strings.HasSuffix(strings.ToLower(urlStr), ".m3u") || strings.HasSuffix(strings.ToLower(urlStr), ".m3u8") || strings.HasSuffix(strings.ToLower(urlStr), ".pls") {
				logger.Printf("Playlist detected: %s", urlStr)
				var urls []string
				var err error

				if strings.HasSuffix(strings.ToLower(urlStr), ".pls") {
					resp, err := http.Get(urlStr)
					if err != nil {
						logger.Printf("Error downloading PLS: %s - Error: %v", urlStr, err)
						result := &LinkCheckResult{
							StationName: name,
							URL:         urlStr,
							Valid:       false,
							Error:       "Error downloading PLS",
						}
						resultsChan <- result
						return
					}
					defer resp.Body.Close()

					body, _ := io.ReadAll(resp.Body)
					urls = extractURLsFromPLS(string(body))
				} else {
					resp, err := http.Get(urlStr)
					if err != nil {
						logger.Printf("Error downloading M3U/M3U8: %s - Error: %v", urlStr, err)
						result := &LinkCheckResult{
							StationName: name,
							URL:         urlStr,
							Valid:       false,
							Error:       "Error downloading M3U/M3U8",
						}
						resultsChan <- result
						return
					}
					defer resp.Body.Close()

					body, _ := io.ReadAll(resp.Body)
					urls = extractURLsFromM3U(string(body))
				}

				if err != nil {
					logger.Printf("Error getting playlist content: %s - Error: %v", urlStr, err)
					resultsChan <- &LinkCheckResult{
						StationName: name,
						URL:         urlStr,
						Valid:       false,
						Error:       "Error getting playlist content",
					}
					return
				}

				if len(urls) == 0 {
					logger.Printf("No URLs found in playlist: %s", urlStr)
					resultsChan <- &LinkCheckResult{
						StationName: name,
						URL:         urlStr,
						Valid:       false,
						Error:       "Empty playlist",
					}
					return
				}

				for _, u := range urls {
					result := checkURL(u, name)
					resultsChan <- result
				}
			} else {
				result := checkURL(urlStr, name)
				resultsChan <- result
			}
		}(name, urlStr)
	}
	innerWg.Wait()
}

func main() {
	fmt.Println("Checking stations...")

	resultsChan := make(chan *LinkCheckResult)
	var wg sync.WaitGroup

	limiter := make(chan struct{}, concurrencyLimit)

	// Walk the directory tree, excluding the "deadStations" directory
	err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip the "deadStations" directory
		if info.IsDir() && info.Name() == "deadStation" {
			return filepath.SkipDir
		}

		if !info.IsDir() && filepath.Ext(path) == ".json" {
			wg.Add(1)
			go processJSONFile(path, &wg, resultsChan, limiter)
		}
		return nil
	})

	if err != nil {
		logger.Printf("Error walking directory: %v", err)
		return
	}

	go func() {
		wg.Wait()
		close(resultsChan)
	}()

	for result := range resultsChan {
		if result.Valid {
			if disableEmoji {
				fmt.Println("OK", result.StationName)
			} else {
				fmt.Println("✅", "OK", result.StationName)
			}
		} else {
			if disableEmoji {
				fmt.Println("BAD", result.StationName, "-", result.Error)
			} else {
				fmt.Println("❌", "BAD", result.StationName, "-", result.Error)
			}
		}
	}

	fmt.Println("✨ Done!")
}
