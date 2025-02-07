// internal/linkcheck.go
package internal

import (
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

func checkURL(urlStr string, stationName string, summary *Summary) *LinkCheckResult {
	summary.TotalURLs++
	result := &LinkCheckResult{URL: urlStr, StationName: stationName}

	if urlStr == "" {
		result.Error = "Empty URL"
		updateOtherErrors(summary, "Empty URL", "Empty URL")
		//NO SUM: summary.FailedChecks++ // No increment here
		Logger().Printf("Empty URL provided for station: %s", stationName)
		return result
	}

	if !strings.HasPrefix(strings.ToLower(urlStr), "http://") && !strings.HasPrefix(strings.ToLower(urlStr), "https://") {
		Logger().Printf("No protocol specified for %s, defaulting to http://", urlStr)
		result.URL = "http://" + urlStr
	} else {
		result.URL = urlStr
	}

	// If it's likely an ICY stream, try the specialized check *first*.
	if isLikelyICY(result.URL) {
		Logger().Printf("Likely ICY stream detected, using specialized check: %s", result.URL)
		icyResult := checkICYStream(result.URL, stationName, summary)
		// Only return if the ICY check was *successful*.
		if icyResult.Valid {
			return icyResult
		}
		// Otherwise, fall through to the normal HTTP/HTTPS checks.
	}

	if strings.HasPrefix(strings.ToLower(result.URL), "https://") {
		//NO SUM: result.Valid = false  // Don't assume failure yet
		return tryTLSConfigs(result.URL, stationName, summary)
	}

	return tryWithConfig(result.URL, stationName, nil, "HTTP", summary)
}

func tryTLSConfigs(urlStr string, stationName string, summary *Summary) *LinkCheckResult {
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

	var lastResult *LinkCheckResult // Keep track of the last result

	for _, tlsCfg := range tlsConfigs {
		result := tryWithConfig(urlStr, stationName, tlsCfg.config, tlsCfg.name, summary)
		if result.Valid {
			return result // Return immediately on success
		}
		lastResult = result // Store the result
		// Only return if it is not TLS error, to try other configs
		if result.Error != "" && !strings.Contains(strings.ToLower(result.Error), "tls") {
			return result
		}
	}

	// Instead of returning a generic failure, return the last result
	// with the specific error information.
	if lastResult != nil {
		return lastResult
	}
	//This should not happen, we check for errors and return before.
	return &LinkCheckResult{
		StationName: stationName,
		URL:         urlStr,
		Valid:       false,
		Error:       "Failed all TLS configurations",
	}
}

func tryWithConfig(urlStr string, stationName string, tlsConfig *tls.Config, configName string, summary *Summary) *LinkCheckResult {
	result := &LinkCheckResult{URL: urlStr, StationName: stationName}
	redirectCount := 0

	tr := &http.Transport{
		TLSClientConfig:       tlsConfig,
		Proxy:                 http.ProxyFromEnvironment,
		DialContext:           (&net.Dialer{Timeout: 30 * time.Second, KeepAlive: 30 * time.Second}).DialContext,
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
			result.URL = req.URL.String() // Update the URL in case of redirects
			return nil
		},
	}

	currentURL := urlStr

	for attempt := 0; attempt < MaxRetries; attempt++ {
		// Check for ICY stream *after* a redirect.
		if redirectCount > 0 {
			if isLikelyICY(result.URL) {
				Logger().Printf("Likely ICY stream detected after redirect, using specialized check: %s", result.URL)
				icyResult := checkICYStream(result.URL, stationName, summary)
				return icyResult // Return immediately, whether successful or not, after retries
			}
		}

		Logger().Printf("Checking URL with %s config (attempt %d): %s", configName, attempt+1, currentURL)

		req, err := http.NewRequest("GET", currentURL, nil)
		if err != nil {
			// If NewRequest fails, there won't be any retries.
			result.Error = "Invalid URL - " + err.Error()
			Logger().Printf("Invalid URL: %s - Error: %v", currentURL, err)
			//summary.FailedChecks++ // Increment failed checks count here.
			return result // Return immediately on URL error
		}

		req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36")
		req.Header.Set("Accept", "*/*")
		req.Header.Set("Connection", "keep-alive")
		req.Header.Set("Icy-MetaData", "1")

		resp, err := client.Do(req)
		if err != nil {
			//NO SUM: summary.FailedChecks++ // DON'T increment failed checks *inside* the retry loop
			// Handle errors *within* the retry loop, but don't return yet.
			if urlErr, ok := err.(*url.Error); ok { // Check if it's a *url.Error
				if urlErr.Timeout() {
					result.Error = "Timeout"
					summary.TimeoutErrors++ // Increment specific timeout counter
				} else if strings.Contains(urlErr.Error(), "unsupported protocol scheme") {
					result.Error = fmt.Sprintf("Unsupported protocol: %s", urlErr.URL)
					updateOtherErrors(summary, "Unsupported Protocol", urlErr.Error())
				} else if strings.Contains(urlErr.Error(), "tls") {
					result.Error = "TLS error: " + urlErr.Error()
					summary.TLSErrors++ // Increment specific TLS errors counter
				} else {
					result.Error = urlErr.Error()
					updateOtherErrors(summary, summarizeError(urlErr.Error()), urlErr.Error())
				}
			} else {
				result.Error = err.Error()
				updateOtherErrors(summary, summarizeError(err.Error()), err.Error())
			}

			Logger().Printf("Error during GET request with %s config: %s - Error: %v", configName, currentURL, err)
			time.Sleep(getBackoffTime(attempt))
			currentURL = result.URL // Prepare for next attempt with possibly redirected URL
			continue                // Go to the next attempt
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode < 400 {
			result.Valid = true
			result.ContentType = resp.Header.Get("Content-Type")
			Logger().Printf("Valid stream found with %s config: %s", configName, currentURL)
			return result // Return immediately on success
		} else {
			//NO SUM: summary.FailedChecks++ // DON'T increment inside the loop
			result.Error = fmt.Sprintf("HTTP %d", resp.StatusCode)
			summary.HTTPErrorCounts[resp.StatusCode]++ // Count specific HTTP status codes
			Logger().Printf("HTTP error with %s config: %s - %s", configName, currentURL, result.Error)
			time.Sleep(getBackoffTime(attempt))
			currentURL = result.URL
			continue
		}
	}

	// If we get here, all attempts have failed.  Return the result with the accumulated error information.
	return result
}
