// internal/playlist.go
package internal

import (
	"bufio"
	"fmt"
	"io"
	"net" // Import the 'net' package
	"net/http"
	"net/url"
	"strings"
	"time"
)

// PLSEntry represents a single entry in a PLS playlist.
type PLSEntry struct {
	File   string
	Title  string
	Length int // -1 if not specified
}

// M3UEntry represents a single entry in an M3U/M3U8 playlist.
type M3UEntry struct {
	URL      string
	Duration int // Duration in seconds (-1 if not specified)
	Title    string
}

// downloadAndExtractPlaylist downloads and extracts URLs from a playlist.
func downloadAndExtractPlaylist(urlStr string, name string) ([]string, *LinkCheckResult) {
	const maxRetries = 3 // Local constant for playlist retries
	initialBackoff := 1 * time.Second
	maxBackoff := 10 * time.Second
	var parseErr error // Declare parseErr outside the loop
	var urls []string  // Declare urls outside the loop

	// Create a dialer with the same settings as in checkURL
	dialer := &net.Dialer{
		Timeout:   30 * time.Second, // Match checkURL's timeout
		KeepAlive: 30 * time.Second, // Match checkURL's keep-alive
	}

	// Create a custom transport that uses our dialer.
	transport := &http.Transport{
		DialContext: dialer.DialContext, // Use the dialer
		// other setting, taken from  tryWithConfig
		Proxy:                 http.ProxyFromEnvironment,
		ForceAttemptHTTP2:     true,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
	}

	// Create a custom client that uses transport.
	client := &http.Client{
		Transport: transport,
		Timeout:   15 * time.Second, //match with tryWithConfig
	}

	for attempt := 0; attempt < maxRetries; attempt++ {
		Logger().Printf("Downloading playlist (attempt %d): %s", attempt+1, urlStr)

		// Add this for debugging the BBC URL issue:
		Logger().Printf("Attempting to download playlist from: %s", urlStr)

		req, err := http.NewRequest("GET", urlStr, nil)
		if err != nil {
			Logger().Printf("Error creating request for playlist: %s - Error: %v", urlStr, err)
			return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Failed to create request for playlist"}
		}

		// Set headers to mimic a browser request.  This is VERY important
		// to avoid being blocked by servers that reject requests without
		// a User-Agent.
		req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36")
		req.Header.Set("Accept", "*/*")
		req.Header.Set("Connection", "keep-alive") // Add keep-alive

		resp, err := client.Do(req) // Use client and req
		if err != nil {
			Logger().Printf("Error downloading playlist: %s - Error: %v", urlStr, err)
			time.Sleep(getBackoffTimePlaylist(attempt, initialBackoff, maxBackoff))
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			Logger().Printf("Error downloading playlist: %s - Status code: %d", urlStr, resp.StatusCode)
			time.Sleep(getBackoffTimePlaylist(attempt, initialBackoff, maxBackoff))
			return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: fmt.Sprintf("Playlist download error. HTTP %d", resp.StatusCode)} //add this

		}
		// Add this HLS detection BEFORE parsing the content type.
		if strings.HasSuffix(strings.ToLower(urlStr), ".m3u8") || strings.Contains(strings.ToLower(resp.Header.Get("Content-Type")), "mpegurl") {
			Logger().Printf("Detected HLS playlist, skipping segment checks: %s", urlStr)
			return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: true, ContentType: resp.Header.Get("Content-Type"), Error: "HLS Playlist (Needs Proper Handling)"}
		}

		contentType := resp.Header.Get("Content-Type")
		//var urls []string  // Moved outside the loop
		//var parseErr error // Moved outside the loop

		if strings.Contains(contentType, "audio/x-mpegurl") || strings.Contains(contentType, "application/vnd.apple.mpegurl") || strings.HasSuffix(strings.ToLower(urlStr), ".m3u") || strings.HasSuffix(strings.ToLower(urlStr), ".m3u8") {
			Logger().Printf("Parsing playlist as M3U: %s", urlStr)
			bodyBytes, err := io.ReadAll(resp.Body)
			if err != nil {
				return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Failed to read playlist content"}
			}
			urls, parseErr = extractURLsFromM3U(string(bodyBytes))
			//NO SUM: summary.PlaylistCount++ // Increment playlist count only if successfully parsed
		} else if strings.Contains(contentType, "audio/x-scpls") || strings.HasSuffix(strings.ToLower(urlStr), ".pls") {
			Logger().Printf("Parsing playlist as PLS: %s", urlStr)
			bodyBytes, err := io.ReadAll(resp.Body)
			if err != nil {
				return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Failed to read playlist content"}
			}
			urls, parseErr = extractURLsFromPLS(string(bodyBytes))
			//NO SUM: summary.PlaylistCount++  // Increment playlist count only if successfully parsed

		} else {
			// Attempt to auto-detect by reading the first few lines
			Logger().Printf("Attempting auto-detection of playlist type: %s", urlStr)
			reader := bufio.NewReader(resp.Body)
			var firstLines []string
			for i := 0; i < 5; i++ { // Read up to 5 lines for detection
				line, err := reader.ReadString('\n')
				if err != nil && err != io.EOF {
					return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Failed to read playlist content for auto-detection"}
				}
				if line != "" {
					firstLines = append(firstLines, line)
				}
				if err == io.EOF {
					break
				}
			}
			content := strings.Join(firstLines, "\n")

			if strings.HasPrefix(content, "#EXTM3U") {
				Logger().Printf("Auto-detected M3U playlist: %s", urlStr)
				// Re-read the entire body since bufio.Reader consumed some data
				resp.Body.Close() // Close previous body before re-requesting
				//NO SUM: summary.PlaylistCount++

				resp, err = http.Get(urlStr) // Re-download the body
				if err != nil {
					Logger().Printf("Error re-downloading for auto-detected M3U: %v", err)
					return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Error re-downloading auto-detected M3U"}
				}
				defer resp.Body.Close()

				bodyBytes, err := io.ReadAll(resp.Body)
				if err != nil {
					return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Failed to read auto-detected M3U content"}
				}
				urls, parseErr = extractURLsFromM3U(string(bodyBytes))

			} else if strings.Contains(content, "[playlist]") {
				Logger().Printf("Auto-detected PLS playlist: %s", urlStr)
				// Re-read the entire body.
				resp.Body.Close()
				//NO SUM: summary.PlaylistCount++
				resp, err = http.Get(urlStr)
				if err != nil {
					Logger().Printf("Error re-downloading for auto-detected PLS: %v", err)
					return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Error re-downloading auto-detected PLS"}
				}
				defer resp.Body.Close()

				bodyBytes, err := io.ReadAll(resp.Body)
				if err != nil {
					return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Failed to read auto-detected PLS content"}
				}
				urls, parseErr = extractURLsFromPLS(string(bodyBytes))
			} else {
				Logger().Printf("Unsupported playlist format: %s", urlStr)
				//NO SUM: summary.FailedChecks++ // Increment failed checks count here
				return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Unsupported playlist format"}
			}
		}

		if parseErr != nil {
			Logger().Printf("Error parsing playlist: %s - Error: %v", urlStr, parseErr)
			time.Sleep(getBackoffTimePlaylist(attempt, initialBackoff, maxBackoff))
			continue
		}

		if len(urls) == 0 {
			Logger().Printf("Empty playlist: %s", urlStr)
			return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Empty playlist"}
		}

		// Resolve relative URLs
		resolvedURLs := make([]string, 0, len(urls))
		for _, u := range urls {
			resolvedURL, err := resolveRelativeURL(urlStr, u)
			if err != nil {
				Logger().Printf("Error resolving URL %s in playlist %s: %v", u, urlStr, err)
				// Don't add unresolved URL
				continue
			}
			resolvedURLs = append(resolvedURLs, resolvedURL)

		}

		return resolvedURLs, nil //Return after a successful attempt
	}

	return nil, &LinkCheckResult{StationName: name, URL: urlStr, Valid: false, Error: "Failed to download playlist after multiple retries"}
}

// getBackoffTimePlaylist calculates the backoff time for playlist retries.
func getBackoffTimePlaylist(attempt int, initialBackoffPlaylist time.Duration, maxBackoffPlaylist time.Duration) time.Duration {
	backoff := initialBackoffPlaylist * time.Duration(1<<attempt)
	if backoff > maxBackoffPlaylist {
		return maxBackoffPlaylist
	}
	return backoff
}

// extractURLsFromPLS parses a PLS file and returns a slice of URLs.
func extractURLsFromPLS(plsContent string) ([]string, error) {
	var urls []string
	scanner := bufio.NewScanner(strings.NewReader(plsContent))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(strings.ToLower(line), "file") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				urls = append(urls, strings.TrimSpace(parts[1]))
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return urls, nil
}

// extractURLsFromM3U parses an M3U/M3U8 file and returns a slice of URLs.
func extractURLsFromM3U(m3uContent string) ([]string, error) {
	var urls []string
	scanner := bufio.NewScanner(strings.NewReader(m3uContent))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "#") && !strings.HasPrefix(line, "#EXTINF") {
			continue // Skip comments, but not #EXTINF lines
		}
		if strings.HasPrefix(line, "#EXTINF") {
			// Get next line - it is URL
			if scanner.Scan() {
				urlLine := scanner.Text()
				urls = append(urls, strings.TrimSpace(urlLine))
			}
		} else if strings.HasPrefix(line, "http") || strings.HasPrefix(line, "/") { //for relative path
			// Assume it's a URL if it starts with http, https
			urls = append(urls, strings.TrimSpace(line))
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return urls, nil
}

// resolveRelativeURL resolves a relative URL against a base URL.
func resolveRelativeURL(baseURLStr, relativeURLStr string) (string, error) {
	baseURL, err := url.Parse(baseURLStr)
	if err != nil {
		return "", fmt.Errorf("invalid base URL: %w", err)
	}

	relativeURL, err := url.Parse(relativeURLStr)
	if err != nil {
		return "", fmt.Errorf("invalid relative URL: %w", err)
	}

	resolvedURL := baseURL.ResolveReference(relativeURL)
	return resolvedURL.String(), nil
}
