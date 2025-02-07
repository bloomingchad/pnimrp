// internal/summary.go
package internal

import (
	"fmt"
	"log"
	"sort"
	"time"
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
	PlaylistCount    int
	EmptyPlaylists   int
	TLSErrors        int
	TimeoutErrors    int
	HTTPErrorCounts  map[int]int
	OtherErrors      map[string]ErrorDetail
	ICYStreamCount   int
}

type LinkCheckResult struct {
	StationName string `json:"stationName"`
	URL         string `json:"url"`
	Valid       bool   `json:"valid"`
	Error       string `json:"error"`
	ContentType string `json:"contentType"`
}

const (
	MaxRetries       = 1
	InitialBackoff   = 1 * time.Second
	MaxBackoff       = 10 * time.Second
	ConcurrencyLimit = 75
	LogFileName      = "finddead.log"
)

var logger *log.Logger

// SetLogger allows external packages (like main) to set the logger.
func SetLogger(l *log.Logger) {
	logger = l
}

// Logger provides access to the logger for internal use.
func Logger() *log.Logger {
	return logger
}

func PrintSummary(summary *Summary, disableEmoji, verbose bool) { // Add arguments
	fmt.Println("\n--- Summary ---")
	maybeEmoji := func(e string) string {
		if disableEmoji {
			return ""
		}
		return e
	}

	fmt.Printf("%s Total Stations Processed: %d\n", maybeEmoji("📊"), summary.TotalStations)
	fmt.Printf("%s Total URLs Checked: %d\n", maybeEmoji("🔗"), summary.TotalURLs)
	fmt.Printf("%s Successful Checks: %d\n", maybeEmoji("✅"), summary.SuccessfulChecks)
	fmt.Printf("%s Failed Checks: %d\n", maybeEmoji("❌"), summary.FailedChecks)
	fmt.Printf("%s ICY Streams Detected: %d\n", maybeEmoji("📻"), summary.ICYStreamCount)
	fmt.Printf("%s Playlists Processed: %d\n", maybeEmoji("📃"), summary.PlaylistCount)
	fmt.Printf("%s Empty Playlists: %d\n", maybeEmoji("0️⃣ "), summary.EmptyPlaylists)
	fmt.Printf("%s Timeout Errors: %d\n", maybeEmoji("⏱️ "), summary.TimeoutErrors)
	fmt.Printf("%s TLS Errors: %d\n", maybeEmoji("🔒"), summary.TLSErrors)

	fmt.Println("\nHTTP Error Counts:")
	fmt.Println("  -------------------")
	fmt.Println("  Status Code | Count")
	fmt.Println("  -------------------")
	for code, count := range summary.HTTPErrorCounts {
		fmt.Printf("  %11d | %5d\n", code, count)
	}
	fmt.Println("  -------------------")

	fmt.Println("\nOther Errors:")
	fmt.Println("  -----------------------------------------")
	fmt.Println("  Error Type                 | Count")
	fmt.Println("  -----------------------------------------")

	readTCPCount := 0
	nonReadTCPErrors := make(map[string]ErrorDetail)

	for summarizedErr, detail := range summary.OtherErrors {
		if summarizedErr == "read tcp" {
			readTCPCount += detail.Count
		} else {
			nonReadTCPErrors[summarizedErr] = detail
		}
	}

	if readTCPCount > 0 {
		fmt.Printf("  %-27s | %5d\n", "read tcp (consolidated)", readTCPCount)
	}

	keys := make([]string, 0, len(nonReadTCPErrors))
	for k := range nonReadTCPErrors {
		keys = append(keys, k)
	}

	sort.Strings(keys)

	for _, summarizedErr := range keys {
		detail := nonReadTCPErrors[summarizedErr]
		if verbose {
			fmt.Printf("  %-27s | %5d\n", detail.FullError, detail.Count)
		} else {
			fmt.Printf("  %-27s | %5d\n", summarizedErr, detail.Count)
		}
	}
	fmt.Println("  -----------------------------------------")
}
