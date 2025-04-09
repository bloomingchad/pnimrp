#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/data/data/com.termux/files/usr/bin/"

# Check if help flag is provided
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [STATION_NAME] [URL]"
    echo "Checks if the provided URL points to an audio file."
    echo "Returns exit code 0 if audio file is detected, 1 otherwise."
    exit 0
fi

# Check if STATION_NAME and URL are provided
if [[ -z "$1" || -z "$2" ]]; then
    echo "Error: STATION_NAME or URL not provided."
    exit 1
fi

# Define arguments
STATION_NAME="$1"
URL="$2"

# Check for required commands: curl and mediainfo
for cmd in curl mediainfo; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "❌ $STATION_NAME: '$cmd' is not installed or not in PATH."
        exit 1
    fi
done

# Define the target keywords (case-insensitive)
KEYWORDS=("flac" "aac" "mp3" "adts" "mpeg" "layer iii" "pls" "m3u" "ogg" "vorbis" "opus")

# Create a randomly named temporary file with unique identifier for concurrent runs
TEMP_FILE="$(mktemp)"

# Use curl to download the file with a timeout of 5 seconds and a user-agent string

# Common curl options
CURL_OPTS=(
    --silent
    -L
    --http0.9
    --insecure
    --max-time 5
    --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    --output "$TEMP_FILE"
)

# Function to make the request
make_request() {
    local extra_opts=("$@")
    curl "${CURL_OPTS[@]}" "${extra_opts[@]}" "$URL" 2>&1
}

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
    # Use the `file` command to identify the file type
    #FILE_TYPE=$(file "$TEMP_FILE" | tr '[:upper:]' '[:lower:]')
    
    # Check if any of the keywords are present in the file type description
    #FOUND=0
    #MATCHED_KEYWORD=""
    #for keyword in "${KEYWORDS[@]}"; do
    #    if echo "$FILE_TYPE" | grep -q "$keyword"; then
    #        FOUND=1
    #        MATCHED_KEYWORD="$keyword"
    #        break
    #    fi
    #done

    # Use mediainfo to identify the file type
    FOUND=0
    MATCHED_KEYWORD=""
    
    # If file command didn't identify audio, try mediainfo as a fallback
    if [[ $FOUND -eq 0 ]]; then
        MEDIAINFO_OUTPUT=$(mediainfo "$TEMP_FILE" | tr '[:upper:]' '[:lower:]')
        for keyword in "${KEYWORDS[@]}"; do
            if echo "$MEDIAINFO_OUTPUT" | grep -q "$keyword"; then
                FOUND=1
                MATCHED_KEYWORD="$keyword (detected by mediainfo)"
                break
            fi
        done
        
        # Additional check for generic MPEG Audio detection in mediainfo
        if [[ $FOUND -eq 0 ]] && echo "$MEDIAINFO_OUTPUT" | grep -q "mpeg audio"; then
            FOUND=1
            MATCHED_KEYWORD="mpeg audio (detected by mediainfo)"
        fi
    fi
    
    # Clean up the temporary file
    rm -f "$TEMP_FILE"
    
    # Return success or error based on whether a keyword was found
    if [[ $FOUND -eq 1 ]]; then
        echo "✅ $STATION_NAME ($MATCHED_KEYWORD)"
        exit 0
    else
        echo "❌ $STATION_NAME: No matching keywords found."
        exit 1
    fi
else
    # Temporary file is empty or does not exist
    rm -f "$TEMP_FILE"
    echo "❌ $STATION_NAME: Downloaded file is empty or missing."
    exit 1
fi
