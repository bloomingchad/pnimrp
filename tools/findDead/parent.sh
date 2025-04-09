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

# Check if worker.sh is executable, if not make it executable
if [[ ! -x "./worker.sh" ]]; then
    chmod +x "./worker.sh"
fi

# Check if GNU Parallel is installed
if ! command -v parallel &> /dev/null; then
    echo "Error: GNU Parallel is not installed. Please install it first."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it first."
    exit 1
fi

# Function to process a single JSON file
process_json_file() {
    local json_file="$1"
    echo "Processing $json_file..." >&2  # Redirect to stderr

    # Extract stations from JSON using jq (tab-separated)
    stations=$(jq -r '.stations | to_entries[] | "\(.key)\t\(.value)"' "$json_file" 2>/dev/null)

    # Process each station using GNU Parallel
    if [[ -n "$stations" ]]; then
        echo "$stations" | parallel --will-cite -j "$PARALLEL_JOBS" --colsep '\t' \
            'bash ./worker.sh {1} {2}'
    else
        echo "No stations found in $json_file" >&2  # Redirect to stderr
    fi
}
# Find all JSON files recursively and process them
find_and_process_json() {
    local search_dir="$1"
    
    # Find all JSON files recursively
    find "$search_dir" -type f -name "*.json" | while read -r json_file; do
        process_json_file "$json_file"
    done
}

# Main execution with the provided directory
find_and_process_json "$SCAN_DIR"

echo "All JSON files processed."
exit 0
