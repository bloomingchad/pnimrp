#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

// Function to check if a character is valid (ASCII-only)
int is_valid_char(char c) {
    // Valid characters are within the ASCII range (0x00 to 0x7F)
    if ((unsigned char)c <= 0x7F) {
        return 1; // Valid ASCII character
    }
    return 0; // Invalid non-ASCII character
}

// Function to check a file
void check_file(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        perror("Error opening file");
        return;
    }

    char line[1024];
    int line_number = 0;

    while (fgets(line, sizeof(line), file)) {
        line_number++;

        for (int i = 0; line[i] != '\0'; i++) {
            if (!is_valid_char(line[i])) {
                printf("Invalid character found in file: %s, line number: %d\n", filename, line_number);
                printf("Line content: %s", line);
                break; // Only report the first invalid character in the line
            }
        }
    }

    fclose(file);
}

// Function to recursively read files in a directory
void read_files(const char *dirpath) {
    DIR *dir = opendir(dirpath);
    if (!dir) {
        perror("Error opening directory");
        return;
    }

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        // Skip "." and ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        char path[1024];
        snprintf(path, sizeof(path), "%s/%s", dirpath, entry->d_name);

        if (entry->d_type == DT_DIR) {
            // Recursively check directories
            read_files(path);
        } else if (entry->d_type == DT_REG && strstr(entry->d_name, ".json") != NULL) {
            // Check JSON files
            check_file(path);
        }
    }

    closedir(dir);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <directory>\n", argv[0]);
        return 1;
    }

    read_files(argv[1]);
    return 0;
}
