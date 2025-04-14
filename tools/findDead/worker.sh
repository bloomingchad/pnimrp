#!/bin/bash

# SPDX-License-Identifier: MPL-2.0

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/data/data/com.termux/files/usr/bin/"

# Function to make a curl request
make_request() {
    local extra_opts=("$@")
    curl "${CURL_OPTS[@]}" "${extra_opts[@]}" "$URL" 2>/dev/null   #2>&1
}

# Function to check file type using mediainfo
check_with_mediainfo() {
    MEDIAINFO_OUTPUT=$(mediainfo "$TEMP_FILE")
    for keyword in "${KEYWORDS[@]}"; do
        if echo "$MEDIAINFO_OUTPUT" | grep -iq "$keyword"; then
            FOUND=1
            MATCHED_KEYWORD="$keyword (detected by mediainfo)"
            return
        fi
    done

    # Additional check for generic MPEG Audio detection in mediainfo
    if echo "$MEDIAINFO_OUTPUT" | grep -iq "mpeg"; then
        FOUND=1
        MATCHED_KEYWORD="mpeg audio (detected by mediainfo)"
    fi

    WHAT_FILE_SAID=$(file "$TEMP_FILE")
    if echo "$WHAT_FILE_SAID" | grep -iq "mpeg"; then
        FOUND=1
        MATCHED_KEYWORD="mpeg audio (detected by file)"
    fi

    if echo "$WHAT_FILE_SAID" | grep -iq "pls"; then
        FOUND=1
        MATCHED_KEYWORD="PLS file (detected by file)"
    fi

    if echo "$WHAT_FILE_SAID" | grep -iq "data"; then
        FOUND=1
        MATCHED_KEYWORD="ℹ️  GENERIC DATA file (detected by file) assuming suces"
    fi
}

# Function to check file type using file command
check_with_file() {
    WHAT_FILE_SAID=$(file "$TEMP_FILE")
    for keyword in "${KEYWORDS[@]}"; do
        if echo "$WHAT_FILE_SAID" | grep -iq "$keyword"; then
            FOUND=1
            MATCHED_KEYWORD="$keyword (detected by file)"
            return
        fi
    done

    if echo "$WHAT_FILE_SAID" | grep -iq "mpeg"; then
        FOUND=1
        MATCHED_KEYWORD="mpeg audio (detected by file)"
    fi
}

cursorUp() {
    echo -ne "\033[1A"
}

cursorDown() {
    echo -ne "\033[1B"
}

eraseLine() {
    # Move the cursor to the beginning of the line (\r)
    echo -ne "\r\033[2K"
}

_echo() {
    #cursorUp
    #echo ""
    
    # Call the regular echo with the provided argument
    #echo "$1"
    #eraseLine
    
    #cursorDown
    echo "$1" >> result.txt

}

log_echo() {
    echo "$1" >> error.txt
}


# Check if STATION_NAME and URL are provided
if [[ -z "$1" || -z "$2" ]]; then
    echo "Error: STATION_NAME or URL not provided."
    exit 1
fi

# Define arguments
STATION_NAME="$1"
URL="$2"

# Define the target keywords (case-insensitive)
KEYWORDS=("flac" "aac" "mp3" "adts" "mpeg" "hls" "layer iii" "layer 3" "dash" "pls" "mpd" "m3u" "ogg" "vorbis" "opus")

# Create a randomly named temporary file with unique identifier for concurrent runs
TEMP_FILE="$(mktemp)"

# Common curl options
CURL_OPTS_CORE=(
    --silent
    --insecure
    --max-time 8
    --http0.9
    --limit-rate 64
    --connect-timeout 5
    --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
    --header "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
    --header "Accept-Language: en-US,en;q=0.9"
    --header "Connection: keep-alive"
    --header "Range: bytes=0-"
    --output "$TEMP_FILE"
)

CURL_OPTS=(
    -L
    "${CURL_OPTS_CORE[@]}"
)


#special case for m3u8 files
if echo "$URL" | grep -iq "m3u"; then
  curl_output=$(curl "${CURL_OPTS_CORE[@]}" "$URL" 2>/dev/null)
  curl_status=$?
  
  if (( curl_status != 0 && curl_status != 28 )); then
    log_echo "❌ $STATION_NAME: CurlError $curl_status"
    _echo "❌ $STATION_NAME: CurlError $curl_status"
    log_echo "-----------------------------------------"
    log_echo "$curl_output"
    log_echo "-----------------------------------------"
    exit 1
  fi

  if grep -q "#EXTM3U" "$TEMP_FILE"; then
     _echo "✅ $STATION_NAME (M3U8 PLAYLIST)"
     log_echo "✅ $STATION_NAME (M3U8 PLAYLIST)"
     exit 0
  fi

  rm -f "$TEMP_FILE"
  exit 0
fi

# Try curl normally first
curl_output=$(make_request)
curl_status="$?"

if (( curl_status != 0 && curl_status != 28 )); then
  log_echo "❌ $STATION_NAME: CurlError $curl_status"
  _echo "❌ $STATION_NAME: CurlError $curl_status"
  log_echo "START curloutp-----------------------------------------"
  log_echo "$curl_output"
  log_echo "END curloutp-----------------------------------------"
  exit 1
fi

#if [ $status -ne 0 ]; then
#    # Check if error indicates HTTP/0.9 is not allowed
#    if echo "$output" | grep -qi -e "0.9" -e "not allowed"; then
#        # Retry with HTTP/0.9 support
#        make_request --http0.9 >/dev/null
#    # Check if error indicates SSL certificate problem
#    elif echo "$output" | grep -qi "SSL certificate problem: unable to get local issuer certificate"; then
#        # Retry with insecure flag
#        make_request --insecure >/dev/null
#    fi
#fi

# Check if the temporary file exists and is not empty
if [[ -s "$TEMP_FILE" ]]; then
    # Initialize variables for detection
    FOUND=0
    MATCHED_KEYWORD=""

    # First, try detecting with mediainfo
    check_with_mediainfo

    # If mediainfo fails, fall back to the file command
    FILE_RESPONSE=$(file "$TEMP_FILE")

    if echo "$FILE_RESPONSE" | grep -iq "with very long lines"; then
        log_echo "ℹ️  $STATION_NAME has very long lines, assuming sucess ✅"
        _echo "ℹ️  $STATION_NAME has very long lines, assuming sucess ✅"
        FOUND=1
        log_echo "START-----------------------------------------"
        log_echo "file said:"
        file "$TEMP_FILE" >> error.txt
        log_echo "mediainfo said:"
        mediainfo "$TEMP_FILE" >> error.txt
        log_echo "$STATION_NAME: $TEMP_FILE"
        log_echo "$URL"
        log_echo "END-----------------------------------------"
    fi

    # Return success or error based on whether a keyword was found
    if [[ $FOUND -eq 1 ]]; then
        _echo "✅ $STATION_NAME ($MATCHED_KEYWORD)"
        rm -f "$TEMP_FILE"
        exit 0
    else
        log_echo "❌ $STATION_NAME: No matching keywords found."
        _echo "❌ $STATION_NAME: No matching keywords found."
        log_echo "START-----------------------------------------"
        log_echo "file said:"
        file "$TEMP_FILE" >> error.txt
        log_echo "mediainfo said:"
        mediainfo "$TEMP_FILE" >> error.txt
        log_echo "$STATION_NAME: $TEMP_FILE"
        log_echo "$URL"
        log_echo "END-----------------------------------------"
		rm -f "$TEMP_FILE"
        exit 1
    fi
else
    # Temporary file is empty or does not exist
    _echo "❌ $STATION_NAME: Downloaded file is empty or missing."
    rm -f "$TEMP_FILE"
    exit 1
fi
