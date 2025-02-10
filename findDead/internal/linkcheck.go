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
		Logger().Printf("Empty URL provided for station: %s", stationName)
		return result
	}

	if !strings.HasPrefix(strings.ToLower(urlStr), "http://") && !strings.HasPrefix(strings.ToLower(urlStr), "https://") {
		Logger().Printf("No protocol specified for %s, defaulting to http://", urlStr)
		urlStr = "http://" + urlStr // Modify the local copy, not result.URL
	}
	result.URL = urlStr // Always set the URL, even if modified

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
		return tryTLSConfigs(result.URL, stationName, summary)
	}

	return tryWithConfig(result.URL, stationName, nil, "HTTP", summary)
}

func tryTLSConfigs(urlStr string, stationName string, summary *Summary) *LinkCheckResult {
    // Prioritize connecting to as many streams as possible, even if it means sacrificing strict TLS security.
    // We use InsecureSkipVerify: true as a last resort to maximize connectivity.  This is a trade-off:
    // we gain broader compatibility but lose the security guarantees of certificate verification.
	tlsConfigs := []struct {
		name   string
		config *tls.Config
	}{
        // Try InsecureSkipVerify *first* to maximize compatibility.  This is the key change.
        {
            name: "Insecure Connection", // Renamed for clarity
            config: &tls.Config{
                InsecureSkipVerify: true,
            },
        },
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
	}

	var lastResult *LinkCheckResult // Keep track of the last result

	for _, tlsCfg := range tlsConfigs {
		result := tryWithConfig(urlStr, stationName, tlsCfg.config, tlsCfg.name, summary)
		if result.Valid {
			return result // Return immediately on success
		}
		lastResult = result // Store the result
        // Only return if it is not a TLS error to try other configs
        if result.Error != "" && !strings.Contains(strings.ToLower(result.Error), "tls") && !strings.Contains(strings.ToLower(result.Error), "x509") && !strings.Contains(strings.ToLower(result.Error), "certificate") {
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
		DialContext:           (&net.Dialer{Timeout: 10 * time.Second, KeepAlive: 30 * time.Second}).DialContext, // Reduced dial timeout to 10s
		ForceAttemptHTTP2:     true,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   5 * time.Second, // Reduced TLS handshake timeout
		ExpectContinueTimeout: 1 * time.Second,
	}

	client := &http.Client{
		Transport: tr,
		Timeout:   10 * time.Second, // Reduced overall timeout
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
    // Remove retries; use a single attempt with timeouts.
    // Check for ICY stream *after* a redirect.
    if redirectCount > 0 && isLikelyICY(result.URL) {
        Logger().Printf("Likely ICY stream detected after redirect, using specialized check: %s", result.URL)
        icyResult := checkICYStream(result.URL, stationName, summary)
        return icyResult // Return immediately, whether successful or not
    }

    Logger().Printf("Checking URL with %s config: %s", configName, currentURL)

    req, err := http.NewRequest("GET", currentURL, nil)
    if err != nil {
        result.Error = "Invalid URL - " + err.Error()
        Logger().Printf("Invalid URL: %s - Error: %v", currentURL, err)
        return result // Return immediately on URL error
    }

    req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36")
    req.Header.Set("Accept", "*/*")
    req.Header.Set("Connection", "keep-alive")
    req.Header.Set("Icy-MetaData", "1") // Request ICY metadata

    resp, err := client.Do(req)
    if err != nil {
        if urlErr, ok := err.(*url.Error); ok { // Check if it's a *url.Error
            if urlErr.Timeout() {
                result.Error = "Timeout"
                summary.TimeoutErrors++ // Increment specific timeout counter
            } else if strings.Contains(urlErr.Error(), "unsupported protocol scheme") {
                result.Error = fmt.Sprintf("Unsupported protocol: %s", urlErr.URL)
                updateOtherErrors(summary, "Unsupported Protocol", urlErr.Error())
            } else if strings.Contains(urlErr.Error(), "tls") || strings.Contains(strings.ToLower(urlErr.Error()), "x509") || strings.Contains(strings.ToLower(urlErr.Error()), "certificate") {
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
        return result // Return on error
    }
    defer resp.Body.Close()

    if resp.StatusCode >= 200 && resp.StatusCode < 400 {
        result.Valid = true
        result.ContentType = resp.Header.Get("Content-Type")
        Logger().Printf("Valid stream found with %s config: %s", configName, currentURL)

        // If we get a 2xx response, *and* it's likely an ICY stream based on headers,
        // do a final ICY check to get the *correct* Content-Type.
        if isLikelyICY(currentURL) || strings.Contains(strings.ToLower(result.ContentType), "application/octet-stream") {
                Logger().Printf("Potentially ICY after 2xx, doing ICY check: %s", result.URL) //Inform
                icyResult := checkICYStream(result.URL, stationName, summary)
                if icyResult.Valid { //If is ICY
                        result.ContentType = icyResult.ContentType // Update Content-Type
                }
        }
        return result
    } else {
        result.Error = fmt.Sprintf("HTTP %d", resp.StatusCode)
        summary.HTTPErrorCounts[resp.StatusCode]++ // Count specific HTTP status codes
        Logger().Printf("HTTP error with %s config: %s - %s", configName, currentURL, result.Error)
        return result // Return on HTTP error
    }
}
