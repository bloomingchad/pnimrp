// internal/utils.go
package internal

import (
	"net/url"
	"strings"
	"time"
)

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

func getHost(urlStr string) string {
	u, err := url.Parse(urlStr)
	if err != nil {
		return ""
	}
	return u.Host
}

func getBackoffTime(attempt int) time.Duration {
	backoff := InitialBackoff * time.Duration(1<<attempt)
	if backoff > MaxBackoff {
		return MaxBackoff
	}
	return backoff
}

func summarizeError(errString string) string {
	lowerErr := strings.ToLower(errString)

	if strings.Contains(lowerErr, "connection refused") {
		return "Connection Refused"
	}
	if strings.Contains(lowerErr, "network is unreachable") ||
		strings.Contains(lowerErr, "no route to host") ||
		strings.Contains(lowerErr, "i/o timeout") {
		return "Network Error"
	}
	if strings.Contains(lowerErr, "invalid header") {
		return "Invalid Header"
	}
	if strings.Contains(lowerErr, "no such host") ||
		strings.Contains(lowerErr, "server misbehaving") ||
		strings.Contains(lowerErr, "lookup") {
		return "DNS Error"
	}
	if strings.Contains(lowerErr, "certificate") ||
		strings.Contains(lowerErr, "x509") {
		return "Certificate Error"
	}
	if strings.Contains(lowerErr, "too many open files") {
		return "Too Many Open Files"
	}
	if strings.Contains(lowerErr, "unexpected EOF") {
		return "Unexpected EOF"
	}
	if strings.HasPrefix(lowerErr, "read tcp") {
		return "read tcp"
	}

	words := strings.Fields(errString)
	if len(words) >= 3 {
		return strings.Join(words[:3], " ")
	}
	return errString
}

func updateOtherErrors(summary *Summary, summarizedError string, fullError string) {
	if existingDetail, ok := summary.OtherErrors[summarizedError]; ok {
		existingDetail.Count++
		existingDetail.FullError = fullError
		summary.OtherErrors[summarizedError] = existingDetail
	} else {
		summary.OtherErrors[summarizedError] = ErrorDetail{Count: 1, FullError: fullError}
	}
}
