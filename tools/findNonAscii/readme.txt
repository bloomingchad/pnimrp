### ReadMe for JSON ASCII Validator

---

#### Overview
This tool is designed to recursively scan JSON files in a specified directory and check for invalid characters. It flags any non-ASCII characters (e.g., Arabic, Greek, or other Unicode characters) that are not part of the standard ASCII character set (`0x00` to `0x7F`). It outputs the file name, line number, and line content where invalid characters are found.

---

#### Purpose
The primary reason for this tool is to ensure that JSON files containing station links and related data maintain a consistent column layout when processed. When non-ASCII characters (such as Arabic or Greek text) are present in the JSON files, they can disrupt the formatting and alignment of the data, causing layout issues. By enforcing ASCII compliance, this tool helps maintain the integrity and readability of the data structure.

---

#### Features
- **Recursive Directory Scanning**: Checks all `.json` files in the specified directory and its subdirectories.
- **ASCII Compliance**: Detects and reports non-ASCII characters (e.g., Arabic, Greek, or other Unicode text).
- **Detailed Output**: Displays the file name, line number, and line content where invalid characters are found for easy debugging.

---

#### Usage
1. **Compile the Program**:
   Save the program as `check_json_ascii.c` and compile it using `gcc`:
   ```bash
   gcc -o check_json_ascii check_json_ascii.c
   ```

2. **Run the Program**:
   Execute the program by passing the directory path containing the JSON files as an argument:
   ```bash
   ./check_json_ascii /path/to/directory
   ```

3. **Review the Output**:
   The program will print the file name, line number, and line content for any invalid (non-ASCII) characters found. For example:
   ```
   Invalid character found in file: /path/to/directory/example.json, line number: 3
   Line content: { "name": "محمد" }

   Invalid character found in file: /path/to/directory/example.json, line number: 5
   Line content: { "description": "This is a test με ελληνικά" }
   ```
