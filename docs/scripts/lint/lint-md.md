# `lint-md.sh` - Markdown Linter & Fixer for Affected Files 🚀

## Purpose

The `lint-md.sh` script is a utility designed to identify and lint only the Markdown files (`*.md`, `*.markdown`) within the current Git repository that have been modified or are new (untracked). It then uses `pnpm dlx markdownlint-cli2 --fix` to lint and attempt to automatically fix any issues in these files.

This targeted approach saves time by avoiding the linting of unchanged files, making it efficient for pre-commit hooks or regular maintenance.

## Usage

The basic syntax for using the script is:

```bash
./scripts/lint/lint-md.sh [options]
```

Or, if you have it set up as a `pnpm` script (e.g., named `lint:md`):

```bash
pnpm lint:md [options]
```

## Options

The script supports the following command-line options:

- `-h`: **Help**
  - Displays a help message outlining the script's usage and available options, then exits.
- `-c`: **Check Only**
  - Lists the Markdown files that would be linted based on their modified/untracked status but does **not** actually run `markdownlint-cli2`. This is useful for a dry run.
- `-q`: **Quiet Mode**
  - Suppresses all informational output from the script (e.g., welcome messages, prerequisite checks, lists of files found). Only error messages (e.g., missing prerequisites, `markdownlint-cli2` errors) will be displayed.

**Important Note on Option Placement:**
For the options to be correctly recognized, they **MUST precede** any non-option arguments (though this script currently doesn't accept non-option arguments other than what `getopts` processes).

## How It Works

1. **Prerequisite Checks**:

   - Verifies that `git` is installed and available in the system's `PATH`.
   - Verifies that `pnpm` is installed and available in the system's `PATH`.
     If either is missing, the script will print an error and exit.

2. **File Discovery**:

   - **Modified Files**: Uses `git diff --name-only -z --diff-filter=d --no-renames HEAD -- "**/*.md" "**/*.markdown"` to find Markdown files that are:
     - Modified (M)
     - Added (A)
     - Copied (C)
     - Renamed (R) (shows the new name)
     - Type-changed (T)
       It excludes deleted (D) files. This covers both staged and unstaged changes relative to the `HEAD` commit.
   - **Untracked Files**: Uses `git ls-files -z -o --exclude-standard -- "**/*.md" "**/*.markdown"` to find new Markdown files in the working directory that are not yet tracked by Git. This respects rules in `.gitignore` and other standard Git exclusion files.
   - The `-z` option in `git` commands ensures that filenames with spaces or special characters are handled correctly using NUL-termination.

3. **File List Processing**:

   - The lists of modified and untracked files are combined.
   - `mapfile` and `sort -zu` are used to create a unique, sorted list of files to process.

4. **Linting and Fixing**:
   - If no relevant Markdown files are found, the script reports this and exits successfully.
   - If files are found:
     - If `-c` (check-only) mode is active, the script lists the files and exits without linting.
     - Otherwise, it executes `pnpm dlx markdownlint-cli2 --fix` followed by the list of discovered Markdown files. `pnpm dlx` ensures `markdownlint-cli2` is used even if not a direct project dependency.
     - The `--fix` flag instructs `markdownlint-cli2` to attempt to automatically correct any linting violations.

## Prerequisites

- **Git**: Must be installed and accessible in your system's `PATH`.
- **pnpm**: Must be installed and accessible in your system's `PATH`.
- **markdownlint-cli2**: While not a direct prerequisite for the script to run (as it uses `pnpm dlx`), `markdownlint-cli2` will be downloaded and executed by `pnpm` if not already available. A `.markdownlint.json` or similar configuration file in your project root is recommended to configure `markdownlint-cli2` rules.

## Exit Codes

- `0`:
  - Successful execution. This can mean:
    - No relevant Markdown files were found to lint.
    - Check-only mode (`-c`) was used, and files were listed successfully.
    - `markdownlint-cli2` ran and found no errors, or successfully fixed all errors.
- `1`:
  - An error occurred. This can mean:
    - An invalid command-line option was provided.
    - A prerequisite (`git` or `pnpm`) was not found.
    - `markdownlint-cli2` was executed but reported linting errors that it could not (or did not) fix.

## Example Usage

1. **Lint and fix all modified/untracked Markdown files:**

   ```bash
   ./scripts/lint/lint-md.sh
   ```

2. **Only check which Markdown files would be linted (dry run):**

   ```bash
   ./scripts/lint/lint-md.sh -c
   ```

3. **Lint and fix, but suppress informational script output:**

   ```bash
   ./scripts/lint/lint-md.sh -q
   ```

---

This script helps maintain the quality and consistency of Markdown files in your project by focusing only on the changes you're actively working on.
