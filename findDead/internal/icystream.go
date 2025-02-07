// internal/icystream.go
package internal

import (
	"bufio"
	"fmt"
	"net"
	"path/filepath"
	"strings"
	"time"
)

// isLikelyICY checks if the URL is likely to be an ICY stream.
func isLikelyICY(urlStr string) bool {
	lowerURL := strings.ToLower(urlStr)
	return strings.HasSuffix(lowerURL, "/;") || !strings.Contains(filepath.Base(lowerURL), ".")
}

// checkICYStream performs a specialized check for ICY streams.
func checkICYStream(urlStr string, stationName string, summary *Summary) *LinkCheckResult {
	result := &LinkCheckResult{URL: urlStr, StationName: stationName}

	for attempt := 0; attempt < MaxRetries; attempt++ {
		conn, err := net.Dial("tcp", getHostAndPort(urlStr))
		if err != nil {
			result.Error = "Connection error: " + err.Error()
			updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
			Logger().Printf("Error connecting to %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}
		defer conn.Close()

		request := fmt.Sprintf("GET / HTTP/1.0\r\nHost: %s\r\nIcy-MetaData: 1\r\nConnection: close\r\n\r\n", getHost(urlStr))
		if _, err = conn.Write([]byte(request)); err != nil {
			result.Error = "Error sending request: " + err.Error()
			updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
			Logger().Printf("Error sending request to %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}

		reader := bufio.NewReader(conn)
		response, err := reader.ReadString('\n')
		if err != nil {
			result.Error = "Error reading response: " + err.Error()
			updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
			Logger().Printf("Error reading response from %s: %v", urlStr, err)
			time.Sleep(getBackoffTime(attempt))
			continue
		}

		if strings.HasPrefix(response, "ICY") {
			Logger().Printf("ICY stream detected (valid): %s", urlStr)
			result.Valid = true
			summary.ICYStreamCount++

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
			Logger().Printf("Not a valid ICY stream: %s", urlStr)
			time.Sleep(getBackoffTime(attempt))
			// DON'T break here; continue to the next attempt
			continue
		}
	}
	return result // Return the result after all retries
}
