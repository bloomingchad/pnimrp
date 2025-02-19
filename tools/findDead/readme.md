# findDead.go

`findDead.go` is a Go-based tool designed to check the
	availability of radio stations listed in JSON files.
	It verifies the accessibility of each station's stream URL,
	identifies dead or invalid links, and provides a summary
	report of the findings. The tool supports various types of
	stream URLs, including ICY streams, playlists (.m3u, .m3u8, .pls),
	and direct HTTP/HTTPS streams.

## Features
	- **Directory Scanning**: Recursively scans a specified directory for JSON files containing station information.
	- **Stream Validation**: Validates the accessibility of each station's stream URL.
	- **Playlist Support**: Handles `.m3u`, `.m3u8`, and `.pls` playlists, extracting and validating individual URLs.
	- **ICY Stream Detection**: Detects and validates ICY streams using a specialized connection method.
	- **TLS Configuration**: Attempts multiple TLS configurations to maximize compatibility with HTTPS streams.
	- **Error Reporting**: Provides detailed error reports, including HTTP status codes, TLS errors, and timeout errors.
	- **Summary Report**: Generates a summary report with statistics on successful and failed checks.
	- **Logging**: Logs detailed information to a file (`finddead.log`) for troubleshooting and analysis.

## Installation
	Ensure you have Go installed on your system. Then, clone the repository and build the project:

```sh
git clone https://github.com/bloomingchad/pnimrp
cd tools/findDead
go build
```

## Usage

```sh
./findDead [-disable-emoji] [-verbose] [-dir <directory>]
```

- `-disable-emoji`: Disable emoji in the output.
- `-verbose`: Enable verbose error output.
- `-dir <directory>`: Specify the directory to scan for JSON files (default is the current directory).

### Example

To scan the `assets` directory for JSON files and disable emoji in the output:

```sh
./findDead -disable-emoji -dir ./assets
```

## Output

The tool outputs the status of each station's stream, indicating whether it is accessible (✅) or not (❌). After completing the scan, it generates a summary report that includes:

- Total stations processed.
- Total URLs checked.
- Successful and failed checks.
- Number of ICY streams detected.
- Playlists processed and empty playlists encountered.
- Counts of timeout and TLS errors.
- Detailed HTTP error counts.
- Other errors encountered during the scan.

**Example Output:**

```
Checking stations...
✅ OK Station1 - audio/mpeg
❌ BAD Station2 - Connection error - http://example.com/stream

--- Summary ---
📊 Total Stations Processed: 10
🔗 Total URLs Checked: 10
✅ Successful Checks: 8
❌ Failed Checks: 2
📻 ICY Streams Detected: 3
📃 Playlists Processed: 2
0️⃣  Empty Playlists: 0
⏱️  Timeout Errors: 1
🔒 TLS Errors: 0

HTTP Error Counts:
  -------------------
  Status Code | Count
  -------------------
          404 |     1
  -------------------

Other Errors:
  -----------------------------------------
  Error Type                 | Count
  -----------------------------------------
  read tcp (consolidated)    |     1
  Connection Refused         |     1
  -----------------------------------------

✨ Done!
```

## Directory Structure

The tool expects JSON files in a specific format, with stations listed under a `"stations"` key:

```json
{
  "stations": {
    "Station1": "http://example.com/stream1",
    "Station2": "http://example.com/stream2"
  }
}
```

The tool will skip any directories named `deadStation` during the scan to avoid processing invalid or outdated entries.

## Logging

Detailed logs are written to `finddead.log`, which includes information about each processed file, URL checks, and any errors encountered. This can be useful for troubleshooting and analyzing issues.

This `README.md` provides a comprehensive overview of the `findDead.go` tool, including its features, installation instructions, usage examples, and expected output. It also includes details about the directory structure, logging, and licensing.
