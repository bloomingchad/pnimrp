#!/bin/bash

# SPDX-License-Identifier: MPL-2.0
# thanks to gnuparallel and mediainfo.

# Check if directory argument was provided
if [[ -z "$1" ]]; then
    echo "Error: Please provide a directory to scan."
    echo "Usage: $0 <directory>"
    exit 1
fi

# Function to print red-colored error messages
perror() {
    echo -e "\e[31mError: $1\e[0m" >&2
}

# Function to print yellow-colored warning messages
pwarn() {
    echo -e "\e[33mWarning: $1\e[0m" >&2
}

# Check if the provided directory exists
if [[ ! -d "$1" ]]; then
    perror "Directory '$1' not found or not accessible."
    exit 1
fi

# Ensure the script runs only on Linux
if [[ "$(uname)" != "Linux" ]]; then
    perror "This script is only tested on Linux"
    perror "Exiting due to possible quirky behaviour"
    exit 1
fi

if ! command -v ldd &> /dev/null; then
  pwarn "ldd is not installed or not in PATH"
fi

# Check if glibc is present
if ! ldd --version 2>&1 | grep -q "GLIBC"; then
    pwarn "This script is only tested in glibc (GNU C Library)."
    pwarn "Consider possible quirky behaviour!"
    sleep 3
fi

PARALLEL_JOBS=10  # Default number of parallel jobs

# Detect system architecture and adjust PARALLEL_JOBS accordingly
ARCH=$(uname -m)  # Get the system architecture

if [[ "$ARCH" == "i386" || "$ARCH" == "x86_64" ]]; then
    PARALLEL_JOBS=30  # Set higher parallel jobs for i386 or amd64
fi

# Store the directory to scan
SCAN_DIR="$1"

if [ -f "result.txt" ]; then
    # Remove the file if it exists
    rm "result.txt"
fi

if [ -f "error.txt" ]; then
    rm "error.txt"
fi

# Check if worker.sh exists in current directory
if [[ ! -f "./worker.sh" ]]; then
    echo "Error: worker.sh not found in current directory."
    exit 1
fi

# Function to display help message
show_help() {
    echo "Usage: $0 [STATION_NAME] [URL]"
    echo "Checks if the provided URL points to an audio file."
    echo "Returns exit code 0 if audio file is detected, 1 otherwise."
}

# Check if help flag is provided
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check if worker.sh is executable, if not make it executable
if [[ ! -x "./worker.sh" ]]; then
    chmod +x "./worker.sh"
fi

# Function to check if required commands exist
check_required_commands() {
    for cmd in curl mediainfo parallel jq file; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌: '$cmd' is not installed or not in PATH."
            exit 1
        fi
    done
}

cursorUp() {
    echo -ne "\033[1A" "$@"
}

# Function to process a single JSON file and feed its stations to GNU Parallel
process_json_file() {
    local json_file="$1"
    #echo "Processing $json_file..." >&2  # Redirect to stderr
    echo "" >&2
    cursorUp >&2

    # Extract stations from JSON using jq (tab-separated)
    jq -r '.stations | to_entries[] | "\(.key)\t\(.value)"' "$json_file" 2>/dev/null
}


check_required_commands

# Main execution: Continuously find JSON files, extract stations, and feed to GNU Parallel
find "$SCAN_DIR" -type f -name "*.json" -print0 | \
while IFS= read -r -d '' json_file; do
    # Process each JSON file and feed its stations to GNU Parallel
    process_json_file "$json_file"
done | parallel --bar --will-cite -j "$PARALLEL_JOBS" --colsep '\t' \
    'bash ./worker.sh {1} {2}'

echo "All JSON files processed."

echo "Summary:"
echo "    Total Stations: $(grep -ri ": \"" "$1" | wc -l)"
echo "    ❌ Unhealthy Found: $(grep -ic ❌ result.txt)"
echo "    ✅ Healthy Found:   $(grep -ic -e "✅" -e "ℹ️ " result.txt)"

echo "Please check results.txt and error.txt for more detailed"
echo "Please use man curl and navigate to EXIT CODES section"
exit 0
