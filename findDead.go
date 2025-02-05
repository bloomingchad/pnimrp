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
	"sort"
	"strings"
	"sync"
	"time"
)

type LinkCheckResult struct {
	StationName string `json:"stationName"`
	URL         string `json:"url"`
	Valid       bool   `json:"valid"`
	Error       string `json:"error"`
	ContentType string `json:"contentType"` // Add Content-Type
}

const (
	maxRetries       = 1
	initialBackoff   = 1 * time.Second
	maxBackoff       = 10 * time.Second
	concurrencyLimit = 75
	logFileName      = "finddead.log"
)

var (
	disableEmoji bool
	logger       *log.Logger
	verbose      bool // Verbose flag
)

type ErrorDetail struct {
	FullError string
	Count     int
}

type Summary struct {
	TotalStations    int
	TotalURLs        int
	SuccessfulChecks int
	FailedChecks     int
	PlaylistCount    int // Count of playlist files processed
	EmptyPlaylists   int
	TLSErrors        int // Specific error counts
	TimeoutErrors    int
	HTTPErrorCounts  map[int]int            // HTTP status code -> count (e.g., 404: 2, 500: 1)
	OtherErrors      map[string]ErrorDetail //To store count of the other errors
	ICYStreamCount   int
}

func init() {
	// Command-line flags
	flag.BoolVar(&disableEmoji, "disable-emoji", false, "Disable emoji in output")
	flag.BoolVar(&verbose, "verbose", false, "Enable verbose error output") // Add verbose flag
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

// tryTLSConfigs attempts to connect with different TLS configurations
func tryTLSConfigs(urlStr string, stationName string, summary *Summary) *LinkCheckResult {
	// Different TLS configurations to try, from most secure to least secure
	tlsConfigs := []struct {
		name   string
		config *tls.Config
	}{
		{
			name: "Modern TLS",
			config: &tls.Config{
				MinVersion: tls.VersionTLS12,
				MaxVersion: tls.VersionTLS13,
				CipherSuites: []uint16{
					tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
					tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
					tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
					tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
				},
			},
		},
		{
			name: "TLS 1.2 Only",
			config: &tls.Config{
				MinVersion: tls.VersionTLS12,
				MaxVersion: tls.VersionTLS12,
			},
		},
		{
			name: "Legacy TLS",
			config: &tls.Config{
				MinVersion: tls.VersionTLS10,
				MaxVersion: tls.VersionTLS12,
			},
		},
		{
			name: "Insecure Legacy",
			config: &tls.Config{
				MinVersion:         tls.VersionTLS10,
				MaxVersion:         tls.VersionTLS12,
				InsecureSkipVerify: true,
			},
		},
	}

	var lastResult *LinkCheckResult

	for _, tlsCfg := range tlsConfigs {
		result := tryWithConfig(urlStr, stationName, tlsCfg.config, tlsCfg.name, summary)
		if result.Valid {
			return result
		}
		lastResult = result
		// If it's not a TLS error, no need to try other configs
		if result.Error != "" && !strings.Contains(strings.ToLower(result.Error), "tls") {
			return result
		}
	}

	if lastResult != nil {
		return lastResult
	}

	return &LinkCheckResult{
		StationName: stationName,
		URL:         urlStr,
		Valid:       false,
		Error:       "Failed all TLS configurations",
	}
}

func tryWithConfig(urlStr string, stationName string, tlsConfig *tls.Config, configName string, summary *Summary) *LinkCheckResult {
	result := &LinkCheckResult{URL: urlStr, StationName: stationName}
	redirectCount := 0 // Keep track of redirects

	tr := &http.Transport{
		TLSClientConfig: tlsConfig,
		// Add additional transport configurations
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		ForceAttemptHTTP2:     true,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
	}

	client := &http.Client{
		Transport: tr,
		Timeout:   15 * time.Second,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("too many redirects")
			}
			redirectCount++
			result.URL = req.URL.String() // Update to the redirected URL
			return nil
		},
	}

	currentURL := urlStr // Start with the initial URL

	for attempt := 0; attempt < maxRetries; attempt++ {
		if redirectCount > 0 {
			// Re-evaluate after redirect
			if isLikelyICY(result.URL) {
				logger.Printf("Likely ICY stream detected after redirect, using specialized check: %s", result.URL)
				icyResult := checkICYStream(result.URL, stationName, summary)
				if icyResult.Valid {
					return icyResult
				}
				logger.Printf("ICY check failed after redirect for %s: %s", result.URL, icyResult.Error)
			}
		}

		logger.Printf("Checking URL with %s config (attempt %d): %s", configName, attempt+1, currentURL)

		req, err := http.NewRequest("GET", currentURL, nil)
		if err != nil {
			result.Error = "Invalid URL - " + err.Error()
			logger.Printf("Invalid URL: %s - Error: %v", currentURL, err)
			return result
		}

		// Set headers
		req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36")
		req.Header.Set("Accept", "*/*")
		req.Header.Set("Connection", "keep-alive")
		req.Header.Set("Icy-MetaData", "1")

		resp, err := client.Do(req)
		if err != nil {
			if urlErr, ok := err.(*url.Error); ok {
				if urlErr.Timeout() {
					result.Error = "Timeout"
					summary.TimeoutErrors++
				} else if strings.Contains(urlErr.Error(), "unsupported protocol scheme") {
					result.Error = fmt.Sprintf("Unsupported protocol: %s", urlErr.URL)
					updateOtherErrors(summary, "Unsupported Protocol", urlErr.Error())
				} else if strings.Contains(urlErr.Error(), "tls") {
					result.Error = "TLS error: " + urlErr.Error()
					summary.TLSErrors++
				} else {
					result.Error = urlErr.Error()
					updateOtherErrors(summary, summarizeError(urlErr.Error()), urlErr.Error())
				}
			} else {
				result.Error = err.Error()
				updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
			}

			logger.Printf("Error during GET request with %s config: %s - Error: %v", configName, currentURL, err)
			time.Sleep(getBackoffTime(attempt))

			// Update currentURL for next attempt
			currentURL = result.URL
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode < 400 {
			result.Valid = true
			result.ContentType = resp.Header.Get("Content-Type") // Get Content-Type
			logger.Printf("Valid stream found with %s config: %s", configName, currentURL)
			return result
		} else {
			result.Error = fmt.Sprintf("HTTP %d", resp.StatusCode)
			summary.HTTPErrorCounts[resp.StatusCode]++
			logger.Printf("HTTP error with %s config: %s - %s", configName, currentURL, result.Error)
			time.Sleep(getBackoffTime(attempt))

			// Update currentURL for next attempt
			currentURL = result.URL
			continue
		}
	}

	return result
}

// checkURL performs a GET request to check the URL, handling redirects and ICY streams
func checkURL(urlStr string, stationName string, summary *Summary) *LinkCheckResult {
	summary.TotalURLs++
	result := &LinkCheckResult{URL: urlStr, StationName: stationName}

	if urlStr == "" {
		result.Error = "Empty URL"
		updateOtherErrors(summary, "Empty URL", "Empty URL")
		logger.Printf("Empty URL provided for station: %s", stationName)
		return result
	}

	if !strings.HasPrefix(strings.ToLower(urlStr), "http://") && !strings.HasPrefix(strings.ToLower(urlStr), "https://") {
		logger.Printf("No protocol specified for %s, defaulting to http://", urlStr)
		result.URL = "http://" + urlStr
	} else {
		result.URL = urlStr
	}

	if isLikelyICY(result.URL) {
		logger.Printf("Likely ICY stream detected, using specialized check: %s", result.URL)
		icyResult := checkICYStream(result.URL, stationName, summary)
		if icyResult.Valid {
			return icyResult
		}
		logger.Printf("ICY check failed for %s: %s", result.URL, icyResult.Error)
	}

	// For HTTPS URLs, try different TLS configurations
	if strings.HasPrefix(strings.ToLower(result.URL), "https://") {
		return tryTLSConfigs(result.URL, stationName, summary)
	}

	return tryWithConfig(result.URL, stationName, nil, "HTTP", summary)
}

// checkICYStream performs a specialized check for ICY streams
func checkICYStream(urlStr string, stationName string, summary *Summary) *LinkCheckResult {
	result := &LinkCheckResult{URL: urlStr, StationName: stationName}

	for attempt := 0; attempt < maxRetries; attempt++ {
		// Use net.Dial to establish a raw TCP connection
		conn, err := net.Dial("tcp", getHostAndPort(urlStr))
		if err != nil {
			result.Error = "Connection error: " + err.Error()
			updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
			logger.Printf("Error connecting to %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}
		defer conn.Close()

		// Send a custom GET request with Icy-MetaData
		request := fmt.Sprintf("GET / HTTP/1.0\r\nHost: %s\r\nIcy-MetaData: 1\r\nConnection: close\r\n\r\n", getHost(urlStr))
		if _, err = conn.Write([]byte(request)); err != nil {
			result.Error = "Error sending request: " + err.Error()
			updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
			logger.Printf("Error sending request to %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}

		// Read the response
		reader := bufio.NewReader(conn)
		response, err := reader.ReadString('\n')
		if err != nil {
			result.Error = "Error reading response: " + err.Error()
			updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
			logger.Printf("Error reading response from %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}

		// Check if it's an ICY response
		if strings.HasPrefix(response, "ICY") {
			logger.Printf("ICY stream detected (valid): %s", urlStr)
			result.Valid = true
			summary.ICYStreamCount++

			// Attempt to read headers to find Content-Type
			for {
				line, err := reader.ReadString('\n')
				if err != nil || line == "\r\n" {
					break
				}
				if strings.HasPrefix(strings.ToLower(line), "content-type:") {
					result.ContentType = strings.TrimSpace(line[len("content-type:"):])
				}
			}

			return result
		} else {
			result.Error = "Not a valid ICY stream"
			// critically remove from here updateOtherErrors(summary, "Not a valid ICY stream", "Not a valid ICY stream")
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

func processJSONFile(filePath string, wg *sync.WaitGroup, resultsChan chan<- *LinkCheckResult, limiter chan struct{}, summary *Summary) {
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
		summary.TotalStations++
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
				summary.PlaylistCount++
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
					summary.EmptyPlaylists++
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
					result := checkURL(u, name, summary)
					resultsChan <- result
				}
			} else {
				result := checkURL(urlStr, name, summary)
				resultsChan <- result
			}
		}(name, urlStr)
	}
	innerWg.Wait()
}

func summarizeError(errString string) string {
	lowerErr := strings.ToLower(errString)

	// Prioritize "connection refused"
	if strings.Contains(lowerErr, "connection refused") {
		return "Connection Refused"
	}

	// General network errors (excluding "connection refused")
	if strings.Contains(lowerErr, "network is unreachable") ||
		strings.Contains(lowerErr, "no route to host") ||
		strings.Contains(lowerErr, "i/o timeout") { // Catch general I/O timeouts
		return "Network Error"
	}

	if strings.Contains(lowerErr, "invalid header") {
		return "Invalid Header"
	}

	// DNS errors
	if strings.Contains(lowerErr, "no such host") ||
		strings.Contains(lowerErr, "server misbehaving") || //Another DNS error
		strings.Contains(lowerErr, "lookup") {
		return "DNS Error"
	}

	// Certificate errors
	if strings.Contains(lowerErr, "certificate") ||
		strings.Contains(lowerErr, "x509") {
		return "Certificate Error"
	}
	//  errors
	if strings.Contains(lowerErr, "too many open files") {
		return "Too Many Open Files"
	}
	if strings.Contains(lowerErr, "unexpected EOF") {
		return "Unexpected EOF"
	}
	//read tcp errors
	if strings.HasPrefix(lowerErr, "read tcp") {
		return "read tcp"
	}

	// Fallback: return first 3 words for other errors
	words := strings.Fields(errString)
	if len(words) >= 3 {
		return strings.Join(words[:3], " ")
	}
	return errString // Return the original if less than 3 words

}

func updateOtherErrors(summary *Summary, summarizedError string, fullError string) {
	if existingDetail, ok := summary.OtherErrors[summarizedError]; ok {
		existingDetail.Count++
		existingDetail.FullError = fullError //always keep most recent error.
		summary.OtherErrors[summarizedError] = existingDetail
	} else {
		summary.OtherErrors[summarizedError] = ErrorDetail{Count: 1, FullError: fullError}
	}
}

func main() {
	fmt.Println("Checking stations...")

	resultsChan := make(chan *LinkCheckResult)
	var wg sync.WaitGroup

	limiter := make(chan struct{}, concurrencyLimit)

	// Initialize Summary
	summary := Summary{
		HTTPErrorCounts: make(map[int]int),
		OtherErrors:     make(map[string]ErrorDetail),
	}

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
			go processJSONFile(path, &wg, resultsChan, limiter, &summary)
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
			summary.SuccessfulChecks++
			if disableEmoji {
				fmt.Println("OK", result.StationName, "-", result.ContentType)
			} else {
				fmt.Printf("✅ OK %s - %s \n", result.StationName, result.ContentType)
			}
		} else {
			summary.FailedChecks++
			if disableEmoji {
				fmt.Println("BAD", result.StationName, "-", result.Error, "-", result.URL)
			} else {
				fmt.Printf("❌ BAD %s - %s - %s\n", result.StationName, result.Error, result.URL)
			}
		}
	}
	fmt.Println("\n--- Summary ---")

	// Use a consistent way to add emoji based on disableEmoji
	maybeEmoji := func(e string) string {
		if disableEmoji {
			return ""
		}
		return e
	}

	// Print summary in a structured format
	fmt.Printf("%s Total Stations Processed: %d\n", maybeEmoji("📊"), summary.TotalStations)
	fmt.Printf("%s Total URLs Checked: %d\n", maybeEmoji("🔗"), summary.TotalURLs)
	fmt.Printf("%s Successful Checks: %d\n", maybeEmoji("✅"), summary.SuccessfulChecks)
	fmt.Printf("%s Failed Checks: %d\n", maybeEmoji("❌"), summary.FailedChecks)
	fmt.Printf("%s ICY Streams Detected: %d\n", maybeEmoji("📻"), summary.ICYStreamCount)
	fmt.Printf("%s Playlists Processed: %d\n", maybeEmoji("📃"), summary.PlaylistCount)
	fmt.Printf("%s Empty Playlists: %d\n", maybeEmoji("0️⃣ "), summary.EmptyPlaylists)
	fmt.Printf("%s Timeout Errors: %d\n", maybeEmoji("⏱️ "), summary.TimeoutErrors)
	fmt.Printf("%s TLS Errors: %d\n", maybeEmoji("🔒"), summary.TLSErrors)

	// Print HTTP Error Counts in a table-like format
	fmt.Println("\nHTTP Error Counts:")
	fmt.Println("  -------------------")
	fmt.Println("  Status Code | Count")
	fmt.Println("  -------------------")
	for code, count := range summary.HTTPErrorCounts {
		fmt.Printf("  %11d | %5d\n", code, count)
	}
	fmt.Println("  -------------------")

	// Print Other Errors in a structured format
	fmt.Println("\nOther Errors:")
	fmt.Println("  -----------------------------------------")
	fmt.Println("  Error Type                 | Count")
	fmt.Println("  -----------------------------------------")

	readTCPCount := 0
	// Use ErrorDetail to also capture full errors for verbose mode
	nonReadTCPErrors := make(map[string]ErrorDetail)

	for summarizedErr, detail := range summary.OtherErrors {
		if summarizedErr == "read tcp" {
			readTCPCount += detail.Count // Accumulate count
		} else {
			nonReadTCPErrors[summarizedErr] = detail // Keep other errors separate
		}
	}
	// Print "read tcp" summary.
	if readTCPCount > 0 {
		fmt.Printf("  %-27s | %5d\n", "read tcp (consolidated)", readTCPCount)
	}

	//Create slice to hold keys
	keys := make([]string, 0, len(nonReadTCPErrors))
	for k := range nonReadTCPErrors {
		keys = append(keys, k)
	}

	//Sort slice
	sort.Strings(keys)

	// Print other errors, consolidated, but with verbose option
	for _, summarizedErr := range keys {
		detail := nonReadTCPErrors[summarizedErr] // Get the ErrorDetail
		if verbose {
			fmt.Printf("  %-27s | %5d\n", detail.FullError, detail.Count) // Full error in verbose
		} else {
			fmt.Printf("  %-27s | %5d\n", summarizedErr, detail.Count) // Summarized
		}
	}

	fmt.Println("  -----------------------------------------")

	fmt.Println("\n---------------")
	fmt.Println("✨ Done!")
	wg.Wait()
}
