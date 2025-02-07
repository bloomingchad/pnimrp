// internal/playlist.go
package internal

import (
	"bufio"
	"io"
	"net/http"
	"regexp"
	"strings"
)

// extractURLsFromM3U parses an M3U/M3U8 file.
func extractURLsFromM3U(m3uContent string) []string {
	var urls []string
	scanner := bufio.NewScanner(strings.NewReader(m3uContent))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "http") {
			urls = append(urls, line)
		}
	}
	return urls
}

// extractURLsFromPLS parses a PLS file.
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

// downloadAndExtractPlaylist downloads and extracts URLs from a playlist.
func downloadAndExtractPlaylist(urlStr string, name string) ([]string, *LinkCheckResult) {
	var urls []string
	// No var err declaration here

	if strings.HasSuffix(strings.ToLower(urlStr), ".pls") {
		resp, err := http.Get(urlStr) // Get the response
		if err != nil {               // Check for error IMMEDIATELY
			Logger().Printf("Error downloading PLS: %s - Error: %v", urlStr, err)
			return nil, &LinkCheckResult{
				StationName: name,
				URL:         urlStr,
				Valid:       false,
				Error:       "Error downloading PLS",
			}
		}
		defer resp.Body.Close() // Safe to defer now

		body, err := io.ReadAll(resp.Body) // Read body, check err AFTER
		if err != nil {                    // NOW check for read error
			Logger().Printf("Error reading PLS body: %s - Error: %v", urlStr, err)
			return nil, &LinkCheckResult{
				StationName: name,
				URL:         urlStr,
				Valid:       false,
				Error:       "Error reading PLS body", // More specific error
			}
		}
		urls = extractURLsFromPLS(string(body))

	} else { // M3U/M3U8 case
		resp, err := http.Get(urlStr) // Get response
		if err != nil {               // Check for error IMMEDIATELY
			Logger().Printf("Error downloading M3U/M3U8: %s - Error: %v", urlStr, err)
			return nil, &LinkCheckResult{
				StationName: name,
				URL:         urlStr,
				Valid:       false,
				Error:       "Error downloading M3U/M3U8",
			}
		}
		defer resp.Body.Close() // Safe to defer now

		body, err := io.ReadAll(resp.Body) // Read body, check err AFTER
		if err != nil {
			Logger().Printf("Error reading M3U/M3U8 body: %s - Error: %v", urlStr, err)
			return nil, &LinkCheckResult{
				StationName: name,
				URL:         urlStr,
				Valid:       false,
				Error:       "Error reading M3U/M3U8 body", // More specific error
			}
		}
		urls = extractURLsFromM3U(string(body))
	}

	// No more error check here.  Errors are handled above.
	return urls, nil
}
