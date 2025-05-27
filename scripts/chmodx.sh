#!/bin/bash
# Script to make specified files executable (chmod +x).

# Exit immediately if a command exits with a non-zero status (set -e).
# Treat unset variables as an error (set -u).
# The return value of a pipeline is the status of the last command
# to exit with a non-zero status, or zero if no command exited with a non-zero status (set -o pipefail).
set -euo pipefail

QUIET_MODE=0
VERBOSE_MODE=0
RECURSIVE_MODE=0

# Function to display script usage
usage() {
    echo -e "📝 Usage: $0 [options]\n"
    echo "Makes the specified files executable by applying 'chmod +x'."
    echo
    echo "Options:"
    echo "  -v                Verbose mode: Show detailed actions for each file."
    echo "  -q                Quiet mode: Suppress all informational output. Only errors will be shown."
    echo "  -r                Recursive: If an argument is a directory, make all files within it executable."
    echo "  -h                Show this help message."
}

# Parsing command-line options
while getopts "hvqr" opt; do
    case ${opt} in
        h) usage; exit 0 ;;
        v) VERBOSE_MODE=1 ;;
        q) QUIET_MODE=1 ;;
        r) RECURSIVE_MODE=1 ;;
        \?) echo -e "❌ Invalid option: -$OPTARG\n" >&2; usage; exit 1 ;;
    esac
done
shift $((OPTIND -1))

# If quiet mode is on, verbose mode's script-generated messages are also suppressed
if [ "$QUIET_MODE" -eq 1 ]; then
    VERBOSE_MODE=0
fi

if [ "$QUIET_MODE" -eq 0 ]; then
    echo -e "🔧 Welcome to $(basename "$0") - The File Executable Setter! 🚀\n"
    # Only show generic "Processing..." if not verbose, as verbose mode will give per-item/per-directory details.
    if [ "$VERBOSE_MODE" -eq 0 ]; then
        echo -e "⚙️ Processing specified items..."
    fi
fi

if [ $# -eq 0 ]; then
    if [ "$QUIET_MODE" -eq 0 ]; then
        echo -e "⚠️ No files specified. Please provide one or more file paths." >&2
    fi
    usage # Show usage if no files are provided
    exit 1
fi

MADE_EXEC_COUNT=0
ALREADY_EXEC_COUNT=0
FAIL_COUNT=0
TOTAL_ATTEMPTED=$#

# Function to process a single file/item
process_item() {
    local target_path="$1"

    if [ ! -e "$target_path" ]; then
        if [ "$QUIET_MODE" -eq 0 ]; then # Always show errors unless quiet
            echo -e "❌ Error: '$target_path' not found." >&2
        fi
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # If it's a directory and we are not in recursive mode for *this specific item*,
    # chmod +x will apply to the directory itself.
    # If it's a file, chmod +x applies to the file.
    if [ -x "$target_path" ]; then
        if [ "$VERBOSE_MODE" -eq 1 ]; then # Only if verbose and not quiet
            echo -e "👍 '$target_path' is already executable."
        fi
        ALREADY_EXEC_COUNT=$((ALREADY_EXEC_COUNT + 1))
    else
        if chmod +x "$target_path"; then
            if [ "$VERBOSE_MODE" -eq 1 ]; then # Only if verbose and not quiet
                echo -e "✅ Successfully made '$target_path' executable."
            fi
            MADE_EXEC_COUNT=$((MADE_EXEC_COUNT + 1))
        else
            if [ "$QUIET_MODE" -eq 0 ]; then # Always show errors unless quiet
                echo -e "❌ Error: Failed to make '$target_path' executable. 'chmod +x' failed." >&2
            fi
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
}

for item_path_arg in "$@"; do
    if [ "$RECURSIVE_MODE" -eq 1 ] && [ -d "$item_path_arg" ]; then
        # In recursive mode, if it's a directory:
        # 1. Process the directory itself.
        if [ "$VERBOSE_MODE" -eq 1 ] && [ "$QUIET_MODE" -eq 0 ]; then
            echo -e "Processing directory entry '$item_path_arg'..."
        fi
        process_item "$item_path_arg"

        # 2. Then, process files within the directory.
        if [ "$VERBOSE_MODE" -eq 1 ]; then
            echo -e "Recursively processing files in directory '$item_path_arg'..."
        fi
        # Find all files (-type f) within the directory and process them
        # -print0 and -d $'\0' handle filenames with spaces/newlines
        find "$item_path_arg" -type f -print0 | while IFS= read -r -d $'\0' file_in_dir; do
            process_item "$file_in_dir"
        done

        # 3. Then, process sub-directories within the directory (excluding the top-level one already processed).
        if [ "$VERBOSE_MODE" -eq 1 ]; then
            echo -e "Recursively processing sub-directories in directory '$item_path_arg'..."
        fi
        find "$item_path_arg" -mindepth 1 -type d -print0 | while IFS= read -r -d $'\0' subdir_in_dir; do
            process_item "$subdir_in_dir"
        done
    else
        # Process the item directly (could be a file or a directory if not in recursive mode for this item)
        process_item "$item_path_arg"
    fi
done

if [ "$QUIET_MODE" -eq 0 ]; then
    if [ "$VERBOSE_MODE" -eq 1 ]; then
        echo "--- Summary ---"
        echo "Total items attempted:      $TOTAL_ATTEMPTED"
        echo "Made executable:            $MADE_EXEC_COUNT"
        echo "Already executable:         $ALREADY_EXEC_COUNT"
        echo "Not found or failed:        $FAIL_COUNT"
        echo "---------------"
    else # Not verbose, not quiet - provide a concise summary
        echo # Newline for separation before summary
        echo -e "📊 Summary for $TOTAL_ATTEMPTED top-level item(s):"
        echo -e "  - Made executable:       $MADE_EXEC_COUNT"
        echo -e "  - Already executable:    $ALREADY_EXEC_COUNT"
        echo -e "  - Errors (not found/failed chmod): $FAIL_COUNT"
    fi

    if [ "$FAIL_COUNT" -eq 0 ] && [ "$TOTAL_ATTEMPTED" -gt 0 ]; then
        echo -e "✨ All operations completed successfully!"
    elif [ "$FAIL_COUNT" -gt 0 ]; then
        echo -e "⚠️ Some operations encountered errors."
    fi
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0