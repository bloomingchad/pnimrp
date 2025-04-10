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
    MEDIAINFO_OUTPUT=$(mediainfo "$TEMP_FILE" | tr '[:upper:]' '[:lower:]')
    for keyword in "${KEYWORDS[@]}"; do
        if echo "$MEDIAINFO_OUTPUT" | grep -q "$keyword"; then
            FOUND=1
            MATCHED_KEYWORD="$keyword (detected by mediainfo)"
            return
        fi
    done

    # Additional check for generic MPEG Audio detection in mediainfo
    if echo "$MEDIAINFO_OUTPUT" | grep -q "mpeg audio"; then
        FOUND=1
        MATCHED_KEYWORD="mpeg audio (detected by mediainfo)"
    fi
}

# Function to check file type using file command
check_with_file() {
    FILE_TYPE=$(file "$TEMP_FILE" | tr '[:upper:]' '[:lower:]')
    for keyword in "${KEYWORDS[@]}"; do
        if echo "$FILE_TYPE" | grep -q "$keyword"; then
            FOUND=1
            MATCHED_KEYWORD="$keyword (detected by file)"
            return
        fi
    done
}

#!/bin/bash

# Function to move the cursor up by one line
cursorUp() {
    echo -ne "\033[1A"
}

# Function to move the cursor down by one line
cursorDown() {
    echo -ne "\033[1B"
}

eraseLine() {
    # Move the cursor to the beginning of the line (\r)
    # Clear the entire line (\033[2K)
    echo -ne "\r\033[2K"
}

# Custom _echo function
_echo() {
    # Move the cursor up
    cursorUp
    #echo ""
    
    # Call the regular echo with the provided argument
    #echo "$1"
    #eraseLine
    
    # Move the cursor down
    cursorDown
    echo "$1" >> result.txt

}

# Main script logic starts here

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
CURL_OPTS=(
    --silent
    -L
    --insecure
    --max-time 7
    --http0.9
    --limit-rate 20K
    --connect-timeout 5
    --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
    --header "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
    --header "Accept-Language: en-US,en;q=0.9"
    --header "Connection: keep-alive"
    --header "Range: bytes=0-"
    --output "$TEMP_FILE"
)

# Try curl normally first
output=$(make_request)
status=$?

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
    if [[ $FOUND -eq 0 ]]; then
        check_with_file
    fi

    # Clean up the temporary file
    rm -f "$TEMP_FILE"

    # Return success or error based on whether a keyword was found
    if [[ $FOUND -eq 1 ]]; then
        _echo "✅ $STATION_NAME ($MATCHED_KEYWORD)"
        exit 0
    else
        _echo "❌ $STATION_NAME: No matching keywords found."
        exit 1
    fi
else
    # Temporary file is empty or does not exist
    rm -f "$TEMP_FILE"
    _echo "❌ $STATION_NAME: Downloaded file is empty or missing."
    exit 1
fi
