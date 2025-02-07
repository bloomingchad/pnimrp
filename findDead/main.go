// main.go
package main

import (
	"findDead/internal"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

var (
	disableEmoji bool
	verbose      bool
	scanDir      string // New flag for the directory to scan
)

func init() {
	// Command-line flags
	flag.BoolVar(&disableEmoji, "disable-emoji", false, "Disable emoji in output")
	flag.BoolVar(&verbose, "verbose", false, "Enable verbose error output")
	flag.StringVar(&scanDir, "dir", ".", "Directory to scan for JSON files") // Default to current directory
	flag.Parse()

	// Ensure scanDir is an absolute path
	absDir, err := filepath.Abs(scanDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: Could not resolve absolute path for %s: %v\n", scanDir, err)
		os.Exit(1) // Exit with an error code
	}
	scanDir = absDir

}

func main() {
	fmt.Println("Checking stations...")

	resultsChan := make(chan *internal.LinkCheckResult)
	var wg sync.WaitGroup

	limiter := make(chan struct{}, internal.ConcurrencyLimit)

	// Initialize Summary
	summary := internal.Summary{
		HTTPErrorCounts: make(map[int]int),
		OtherErrors:     make(map[string]internal.ErrorDetail),
	}

	// Set up logging.
	file, err := os.OpenFile(internal.LogFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Println("Failed to open log file, using default stderr")
		internal.SetLogger(log.New(os.Stderr, "", log.LstdFlags))
	} else {
		internal.SetLogger(log.New(file, "", log.LstdFlags))
	}

	// Walk the specified directory
	err = filepath.Walk(scanDir, func(path string, info os.FileInfo, err error) error { // Use scanDir
		if err != nil {
			return err
		}

		// Skip the "deadStations" directory (relative to scanDir)
		if info.IsDir() && info.Name() == "deadStation" {
			if path == filepath.Join(scanDir, "deadStation") || //absolute path, to prevent the check skip a subdirectory with the same name, of another station
				strings.HasPrefix(path, filepath.Join(scanDir, "deadStation")+string(filepath.Separator)) {
				return filepath.SkipDir
			}
		}

		if !info.IsDir() && filepath.Ext(path) == ".json" {
			wg.Add(1)
			go internal.ProcessJSONFile(path, &wg, resultsChan, limiter, &summary)
		}
		return nil
	})

	if err != nil {
		internal.Logger().Printf("Error walking directory: %v", err)
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
	internal.PrintSummary(&summary, disableEmoji, verbose)
	fmt.Println("\n---------------")
	fmt.Println("✨ Done!")
	wg.Wait()
}
