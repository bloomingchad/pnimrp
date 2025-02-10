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

	// Use a single attempt with a timeout, prioritizing speed.
	conn, err := net.DialTimeout("tcp", getHostAndPort(urlStr), 10*time.Second) // 10-second timeout
	if err != nil {
		result.Error = "Connection error: " + err.Error()
		updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
		Logger().Printf("Error connecting to %s: %v", urlStr, err)
		return result
	}
	defer conn.Close()

	// Set a deadline for the entire connection.
	conn.SetDeadline(time.Now().Add(15 * time.Second)) // 15-second deadline for the entire process

	request := fmt.Sprintf("GET / HTTP/1.0\r\nHost: %s\r\nIcy-MetaData: 1\r\nConnection: close\r\n\r\n", getHost(urlStr))
	if _, err = conn.Write([]byte(request)); err != nil {
		result.Error = "Error sending request: " + err.Error()
		updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
		Logger().Printf("Error sending request to %s: %v", urlStr, err)
		return result
	}

	reader := bufio.NewReader(conn)
	response, err := reader.ReadString('\n')
	if err != nil {
		result.Error = "Error reading response: " + err.Error()
		updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
		Logger().Printf("Error reading response from %s: %v", urlStr, err)
		return result
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
				break // Stop reading headers after finding Content-Type
			}
		}
		return result
	} else {
		result.Error = "Not a valid ICY stream"
		Logger().Printf("Not a valid ICY stream: %s", urlStr)
		return result
	}
}
