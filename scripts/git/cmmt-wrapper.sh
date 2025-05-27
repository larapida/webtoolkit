#!/bin/bash
# Script to wrap a command, apply it to git-affected files, stash/commit changes, and restore.

set -euo pipefail

# --- Globals ---
declare -a CMD_TO_RUN_ARGS=()
declare -a INITIAL_AFFECTED_FILES=()
STASH_CREATED=0
STASH_NAME=""

# --- Functions ---
usage() {
    echo "Usage: $(basename "$0") -- <command> [args...]"
    echo "Description:"
    echo "  Wraps a <command> to operate on files currently modified or untracked in git."
    echo "  It stashes existing changes, runs the command on these 'affected files',"
    echo "  commits any modifications made by the command to these files, and then pops the stash."
    echo
    echo "Arguments:"
    echo "  --                Separator indicating the start of the command to be wrapped."
    echo "  <command> [args...] The command and its arguments to execute on affected files."
    echo
    echo "Example:"
    echo "  $(basename "$0") -- pnpm prettier --write"
    echo "  (This would run prettier on currently changed/untracked files)"
}

parse_arguments() {
    local in_command_section=0
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--" ]]; then
            in_command_section=1
            shift
            continue
        fi

        if [[ $in_command_section -eq 1 ]]; then
            CMD_TO_RUN_ARGS+=("$1")
        else
            echo "Error: Unknown wrapper option '$1'. All wrapper options (if any) must precede '--'." >&2
            usage
            exit 1
        fi
        shift
    done

    if [ ${#CMD_TO_RUN_ARGS[@]} -eq 0 ]; then
        echo "Error: No command provided after -- separator." >&2
        usage
        exit 1
    fi
}

get_initially_affected_files() {
    INITIAL_AFFECTED_FILES=() # Clear previous
    local git_status_output
    git_status_output=$(git status --porcelain --untracked-files=all --no-renames)

    if [ -z "$git_status_output" ]; then
        echo "No initially affected files found (repository is clean or only ignored files changed)."
        return
    fi

    while IFS= read -r line; do
        # Format is "XY PATH", where XY are status codes. We need PATH.
        # Path starts at column 4 (index 3).
        INITIAL_AFFECTED_FILES+=("${line:3}")
    done <<< "$git_status_output"

    if [ ${#INITIAL_AFFECTED_FILES[@]} -gt 0 ]; then
        # Deduplicate - though porcelain output for unique files should be unique.
        # Sorting is not strictly necessary here but doesn't hurt.
        mapfile -t -d '' INITIAL_AFFECTED_FILES < <(printf "%s\0" "${INITIAL_AFFECTED_FILES[@]}" | sort -zu)
        echo "Identified initially affected files:"
        printf "  %s\n" "${INITIAL_AFFECTED_FILES[@]}"
    fi
}

check_and_stash_changes() {
    if [ -n "$(git status --porcelain)" ]; then
        echo "Uncommitted changes detected. Stashing..."
        STASH_NAME="wrapper-script-stash-$(date +%s)"
        echo "+ git stash push -u -m \"$STASH_NAME\""
        if git stash push -u -m "$STASH_NAME"; then
            STASH_CREATED=1
            echo "Stashed changes as '$STASH_NAME'."
        else
            echo "Error: Failed to stash changes. Aborting." >&2
            exit 1
        fi
    else
        echo "No uncommitted changes to stash."
    fi
}

execute_command_on_affected() {
    if [ ${#INITIAL_AFFECTED_FILES[@]} -eq 0 ]; then
        echo "No initially affected files to process with the command. Skipping command execution."
        return 0 # Considered success as no action was needed for the command part
    fi

    echo "Executing command on affected files:"
    echo "+ ${CMD_TO_RUN_ARGS[*]} ${INITIAL_AFFECTED_FILES[*]}"
    
    # Execute the command with the list of affected files appended as arguments
    if "${CMD_TO_RUN_ARGS[@]}" "${INITIAL_AFFECTED_FILES[@]}"; then
        echo "Command executed successfully."
        return 0
    else
        local exit_code=$?
        echo "Error: Command '${CMD_TO_RUN_ARGS[0]}' failed with exit code $exit_code." >&2
        return $exit_code
    fi
}

stage_and_commit_command_changes() {
    local files_staged_by_script=0
    echo "Checking for modifications made by the command to initially targeted files..."

    if [ ${#INITIAL_AFFECTED_FILES[@]} -eq 0 ]; then
        echo "No files were initially targeted by the command; skipping staging/commit."
        return
    fi

    for file_path in "${INITIAL_AFFECTED_FILES[@]}"; do
        # Check if the file was modified or added by the command relative to its post-stash state
        # (which should be clean or as per HEAD for tracked files).
        if [ -e "$file_path" ] && [ -n "$(git status --porcelain -- "$file_path")" ]; then
            echo "File '$file_path' was modified/added by the command. Staging..."
            echo "+ git add \"$file_path\""
            if git add "$file_path"; then
                files_staged_by_script=1
            else
                echo "Warning: Failed to stage '$file_path'." >&2
            fi
        elif [[ $(git status --porcelain -- "$file_path" 2>/dev/null) == *" D "* ]]; then
             # If the command deleted a file that was initially targeted (and tracked)
             echo "File '$file_path' was deleted by the command. Staging deletion..."
             echo "+ git add \"$file_path\""
             if git add "$file_path"; then # `git add` stages deletions of tracked files
                files_staged_by_script=1
             else
                echo "Warning: Failed to stage deletion of '$file_path'." >&2
             fi
        fi
    done

    if [ "$files_staged_by_script" -eq 1 ]; then
        if ! git diff --quiet --staged HEAD; then # Check if there are actual staged changes
            local commit_msg="Automated: Apply '${CMD_TO_RUN_ARGS[0]}' to affected files"
            echo "Committing changes made by the command..."
            echo "+ git commit -m \"$commit_msg\""
            if git commit -m "$commit_msg"; then
                echo "Changes committed successfully."
            else
                echo "Error: Failed to commit changes. Staged changes remain." >&2
                # Continue to stash pop
            fi
        else
            echo "No effective changes to commit after staging."
        fi
    else
        echo "No targeted files appear to have been modified by the command, or staging failed."
    fi
}

pop_stashed_changes() {
    if [ "$STASH_CREATED" -eq 1 ]; then
        echo "Attempting to pop stash '$STASH_NAME'..."
        echo "+ git stash pop"
        if git stash pop; then # Pops the most recent stash
            echo "Stash popped successfully."
        else
            echo "Error: Failed to pop stash. Conflicts may have occurred." >&2
            echo "Your original changes are still in the stash '$STASH_NAME' (or the latest if names collide)."
            echo "Please resolve conflicts and manage the stash manually (e.g., 'git stash apply STASH_NAME')."
            # Exit with an error code to signal manual intervention is critical.
            exit 2 # Using a distinct exit code for stash pop failure
        fi
    fi
}

# --- Main Logic ---
main() {
    parse_arguments "$@"

    get_initially_affected_files
    check_and_stash_changes

    local command_execution_status=0
    if ! execute_command_on_affected; then
        command_execution_status=$?
        echo "Command execution failed. Modifications (if any) will not be committed by this script."
    else
        # Only attempt to stage and commit if the command itself was successful
        stage_and_commit_command_changes
    fi

    pop_stashed_changes

    # Exit with the command's execution status if it failed, otherwise exit 0
    exit "$command_execution_status"
}

main "$@"