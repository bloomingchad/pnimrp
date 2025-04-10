#!/bin/bash

# Configuration
PARALLEL_JOBS=10  # Number of parallel jobs to run

# Check if directory argument was provided
if [[ -z "$1" ]]; then
    echo "Error: Please provide a directory to scan."
    echo "Usage: $0 <directory>"
    exit 1
fi

# Check if the provided directory exists
if [[ ! -d "$1" ]]; then
    echo "Error: Directory '$1' not found or not accessible."
    exit 1
fi

# Store the directory to scan
SCAN_DIR="$1"

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

# Check for required commands
check_required_commands

# Check if worker.sh is executable, if not make it executable
if [[ ! -x "./worker.sh" ]]; then
    chmod +x "./worker.sh"
fi

# Function to check if required commands exist
check_required_commands() {
    for cmd in curl mediainfo parallel jq; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌: '$cmd' is not installed or not in PATH."
            exit 1
        fi
    done
}

# Function to process a single JSON file and feed its stations to GNU Parallel
process_json_file() {
    local json_file="$1"
    echo "Processing $json_file..." >&2  # Redirect to stderr

    # Extract stations from JSON using jq (tab-separated)
    jq -r '.stations | to_entries[] | "\(.key)\t\(.value)"' "$json_file" 2>/dev/null
}


check_required_commands

# Main execution: Continuously find JSON files, extract stations, and feed to GNU Parallel
find "$SCAN_DIR" -type f -name "*.json" -print0 | \
while IFS= read -r -d '' json_file; do
    # Process each JSON file and feed its stations to GNU Parallel
    process_json_file "$json_file"
done | parallel --will-cite -j "$PARALLEL_JOBS" --colsep '\t' \
    'bash ./worker.sh {1} {2}'

echo "All JSON files processed."
exit 0
