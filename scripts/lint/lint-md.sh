#!/bin/bash
# Script to find modified/untracked Markdown files and lint/fix them.

# Exit immediately if a command exits with a non-zero status (set -e).
# Treat unset variables as an error (set -u).
# The return value of a pipeline is the status of the last command
# to exit with a non-zero status, or zero if no command exited with a non-zero status (set -o pipefail).
set -euo pipefail


# Variables for options
QUIET_MODE=0
CHECK_ONLY=0

# Function to display script usage
usage() {
    echo -e "📝 Usage: $0 [options]\n"
    echo "Lints and fixes modified/untracked Markdown files (.md, .markdown) in the current Git repository"
    echo "using 'pnpm dlx markdownlint-cli2 --fix'."
    echo
    echo "Options:"
    echo "  -c                Check only: List Markdown files that would be linted, but do not run the linter."
    echo "  -q                Quiet mode: Suppress all informational output. Only errors will be shown."
    echo "  -h                Show this help message."
}

# Parsing command-line options
while getopts "hcq" opt; do
    case ${opt} in
        h )
            usage
            exit 0
            ;;
        c )
            CHECK_ONLY=1
            ;;
        q )
            QUIET_MODE=1
            ;;
        \? )
            echo -e "❌ Invalid option: -$OPTARG\n" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

if [ "$QUIET_MODE" -eq 0 ]; then
    echo -e "🤖 Welcome to Markdown Linter & Fixer! 🚀\n"
fi

# --- Prerequisite Checks ---
if [ "$QUIET_MODE" -eq 0 ]; then
    echo -e "🔎 Checking prerequisites..."
fi

if ! command -v git &> /dev/null; then
    echo -e "❌ Error: git is not installed or not in PATH." >&2
    echo "Please install git to use this script." >&2
    exit 1
fi
if [ "$QUIET_MODE" -eq 0 ]; then
    echo "👍 git is available."
fi

if ! command -v pnpm &> /dev/null; then
    echo -e "❌ Error: pnpm is not installed or not in PATH." >&2
    echo "Please install pnpm to use this script (e.g., from https://pnpm.io)" >&2
    exit 1
fi
if [ "$QUIET_MODE" -eq 0 ]; then
    echo -e "👍 pnpm is available.\n"
fi

# Array to hold all discovered file paths (potentially with duplicates)
declare -a candidate_files=()

# 1. Get files that are modified, added, copied, or renamed relative to HEAD (staged or unstaged).
#    --diff-filter=d: Excludes deleted files. We are interested in files that currently exist and are changed.
#                     This covers Added, Copied, Modified, Renamed, Type-changed files.
#    --no-renames:    For renamed files, list the new name.
#    -z:              Use NUL as a terminator for filenames (handles special characters).
#    Patterns:        "**/*.md" and "**/*.markdown" ensure only Markdown files are considered.
while IFS= read -r -d $'\0' file; do
    candidate_files+=("$file")
done < <(git diff --name-only -z --diff-filter=d --no-renames HEAD -- "**/*.md" "**/*.markdown")

# 2. Get untracked Markdown files.
#    -o:              Show other (untracked) files.
#    --exclude-standard: Respect .gitignore and other standard Git exclusions.
#    -z:              Use NUL as a terminator.
while IFS= read -r -d $'\0' file; do
    candidate_files+=("$file")
done < <(git ls-files -z -o --exclude-standard -- "**/*.md" "**/*.markdown")

if [ "$QUIET_MODE" -eq 0 ]; then
    echo -e "🔎 Finding modified or untracked Markdown files (**.md, **.markdown)..."
fi

# 3. Create a unique list of files to lint.
declare -a files_to_process=()
if [ ${#candidate_files[@]} -gt 0 ]; then
    # Convert array to a NUL-separated string, sort unique (-u) with NUL delimiters (-z),
    # then read back into an array using mapfile with NUL as delimiter (-d '').
    mapfile -t -d '' files_to_process < <(printf "%s\0" "${candidate_files[@]}" | sort -zu)
fi

# 4. Lint and fix the files if any were found.
if [ ${#files_to_process[@]} -gt 0 ]; then
  if [ "$QUIET_MODE" -eq 0 ]; then
    echo -e "\nℹ️ Found the following Markdown files to process:"
    # Using printf for safer printing of filenames, especially if they contain % or start with -
    printf "  %s\n" "${files_to_process[@]}"
  fi

  if [ "$CHECK_ONLY" -eq 1 ]; then
    if [ "$QUIET_MODE" -eq 0 ]; then
        echo -e "\n✅ Check-only mode: Files listed above would be linted. No changes made."
    fi
  else
    if [ "$QUIET_MODE" -eq 0 ]; then
        echo -e "\n⚙️ Running markdownlint-cli2 to lint and fix..."
    fi
    # Pass the array of files directly to the command.
    # The shell will expand "${files_to_process[@]}" into separate arguments.
    # Filenames with spaces or special characters will be handled correctly as single arguments.
    if ! pnpm dlx markdownlint-cli2 --fix "${files_to_process[@]}"; then
        if [ "$QUIET_MODE" -eq 0 ]; then
            echo -e "\n⚠️ Warning: markdownlint-cli2 finished with an error or linting issues (see output above)." >&2
            echo "   Some files might not have been fixed or still contain linting problems." >&2
        fi
        exit 1 # Propagate failure
    else
        if [ "$QUIET_MODE" -eq 0 ]; then
            echo -e "\n✅ Markdown linting and fixing complete for selected files."
        fi
    fi
  fi
else
  if [ "$QUIET_MODE" -eq 0 ]; then
    echo -e "\n👍 No relevant modified or untracked Markdown files found to lint."
  fi
fi