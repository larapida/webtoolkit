# Script: `lint-md.sh` (Invoked as `webnodex:lint-md`)

## Overview

`lint-md.sh` is a script designed to find modified or untracked Markdown files (`.md`, `.markdown`) within the current Git repository and then lint and automatically fix them using `pnpm dlx markdownlint-cli2 --fix`.

## Invocation

### Via `webnodex` dispatcher (Recommended)

This script is intended to be run via the `webnodex` dispatcher using an npm script.

```bash
pnpm run webnodex:lint-md [options]
```

**Example:**

```bash
# Lint and fix modified/untracked Markdown files
pnpm run webnodex:lint-md

# Check which Markdown files would be linted, without fixing
pnpm run webnodex:lint-md -c
```

### Direct Execution

```bash
bash ./scripts/lint/lint-md.sh [options]
```

## Usage

```bash
📝 Usage: lint-md.sh [options]

Lints and fixes modified/untracked Markdown files (.md, .markdown) in the current Git repository
using 'pnpm dlx markdownlint-cli2 --fix'.

Options:
  -c                Check only: List Markdown files that would be linted, but do not run the linter.
  -q                Quiet mode: Suppress all informational output. Only errors will be shown.
  -h                Show this help message.
```

## Options

- `-c`: **Check only**. Lists the Markdown files that are modified or untracked and would be processed, but does not actually run the linter/fixer.
- `-q`: **Quiet mode**. Suppresses all informational output. Only errors (e.g., missing prerequisites, linter errors) will be shown.
- `-h`: **Help**. Displays the usage message and exits.

## Behavior

1.  **Prerequisite Checks**: Verifies that `git` and `pnpm` are installed and available in the system's PATH.
2.  **File Discovery**:
    - Identifies Markdown files (`**/*.md`, `**/*.markdown`) that are modified, added, copied, or renamed relative to `HEAD` (staged or unstaged, excluding deleted files).
    - Identifies untracked Markdown files, respecting `.gitignore` and standard Git exclusions.
    - Creates a unique list of these files.
3.  **Execution**:
    - If in **Check only** mode (`-c`), it lists the identified files and exits.
    - Otherwise, it runs `pnpm dlx markdownlint-cli2 --fix` on the identified files.
    - If `markdownlint-cli2` reports errors or fails, the script will also exit with a non-zero status and display a warning (unless in quiet mode).
4.  **Output**:
    - Unless in quiet mode, the script provides informational messages about its progress.
    - If files are found, they are listed.
    - A success or warning message is shown upon completion.

## Dependencies

- `git`: For identifying changed and untracked files.
- `pnpm`: For running `markdownlint-cli2` via `pnpm dlx`.
- `markdownlint-cli2`: The actual Markdown linter and fixer. The script invokes it using `pnpm dlx`, so it doesn't need to be globally installed but `pnpm` must be able to download and run it.

## Notes

- The script uses `set -euo pipefail` for robust error handling.
- This script modifies files in place when it fixes linting issues. Ensure your work is committed or backed up if you are unsure about the changes `markdownlint-cli2` might make.
