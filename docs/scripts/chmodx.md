# Script: `chmodx.sh`

## Overview

The `chmodx.sh` script is designed to make specified files and directories executable by applying `chmod +x` to them. It offers options for verbose output, quiet operation, and recursive application to directories.

## Invocation

### Direct Execution

```bash
bash ./scripts/chmodx.sh [options] <file_or_directory_path>...
```

## Usage

```bash
📝 Usage: chmodx.sh [options]
Makes the specified files executable by applying 'chmod +x'.

Options:
  -v                Verbose mode: Show detailed actions for each file.
  -q                Quiet mode: Suppress all informational output. Only errors will be shown.
  -r                Recursive: If an argument is a directory, make all files within it executable.
  -h                Show this help message.
```

## Options

- `-v`: Enables verbose mode, providing detailed feedback for each file processed.
- `-q`: Enables quiet mode, suppressing all informational output. Only errors will be displayed. If quiet mode is on, verbose mode messages are also suppressed.
- `-r`: Enables recursive mode. If a specified path is a directory, the script will attempt to make the directory itself, all files within its tree, and all sub-directories within its tree executable.
- `-h`: Displays the help message and exits.

## Behavior

- The script exits immediately if any command fails (`set -e`).
- It treats unset variables as errors (`set -u`).
- The return value of a pipeline is the status of the last command to exit with a non-zero status (`set -o pipefail`).
- If no file paths are provided, it displays a warning and the usage message, then exits with status 1.
- The script provides a summary of operations (files made executable, already executable, not found/failed) unless in quiet mode.
- Exits with status 1 if any operation failed (e.g., file not found, `chmod` failed), otherwise exits with 0.

## Examples

```bash
# Make a single script executable
bash ./scripts/chmodx.sh ./my_script.sh

# Make multiple files executable with verbose output
bash ./scripts/chmodx.sh -v ./script1.sh ./another_script.py

# Make all files in a directory executable recursively
bash ./scripts/chmodx.sh -r ./bin/
```
