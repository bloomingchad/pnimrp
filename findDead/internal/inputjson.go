// internal/inputjson.go
package internal

import (
	"encoding/json"
	"os"
	"strings"
	"sync"
)

func ProcessJSONFile(filePath string, wg *sync.WaitGroup, resultsChan chan<- *LinkCheckResult, limiter chan struct{}, summary *Summary) {
	defer wg.Done()

	Logger().Printf("Processing JSON file: %s", filePath)

	fileData, err := os.ReadFile(filePath)
	if err != nil {
		Logger().Printf("Error reading file: %s - Error: %v", filePath, err)
		return
	}

	var jsonData map[string]interface{}
	err = json.Unmarshal(fileData, &jsonData)
	if err != nil {
		Logger().Printf("Error parsing JSON: %s - Error: %v", filePath, err)
		return
	}

	stations, ok := jsonData["stations"].(map[string]interface{})
	if !ok {
		Logger().Printf("No stations found in %s", filePath)
		return
	}

	var innerWg sync.WaitGroup
	for name, urlInterface := range stations {
		summary.TotalStations++
		urlStr, ok := urlInterface.(string)
		if !ok {
			Logger().Printf("Invalid URL format for %s", name)
			continue
		}

		innerWg.Add(1)
		go func(name string, urlStr string) {
			defer innerWg.Done()
			limiter <- struct{}{}
			defer func() { <-limiter }()

			if strings.HasSuffix(strings.ToLower(urlStr), ".m3u") || strings.HasSuffix(strings.ToLower(urlStr), ".m3u8") || strings.HasSuffix(strings.ToLower(urlStr), ".pls") {
				summary.PlaylistCount++
				Logger().Printf("Playlist detected: %s", urlStr)
				urls, result := downloadAndExtractPlaylist(urlStr, name) // Removed summary

				if result != nil {
					resultsChan <- result
					return
				}

				if len(urls) == 0 {
					summary.EmptyPlaylists++
					Logger().Printf("No URLs found in playlist: %s", urlStr)
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
