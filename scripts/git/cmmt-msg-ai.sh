#!/bin/bash

# Optional: User-provided description of changes (first argument to the script)
USER_PROVIDED_DESCRIPTION="$1"

# Configuration for Ollama host (default)
# OLLAMA_HOST can be overridden by an environment variable.
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
OLLAMA_MODEL_NAME="${CMT_MSG_AI_OLLAMA_MODEL:-tavernari/git-commit-message}" # Default model, can be overridden

# Function to check if running in WSL
is_wsl() {
    grep -qi "microsoft\|wsl" /proc/version 2>/dev/null
    return $?
}

# Function to check if jq is available
check_jq() {
    command -v jq &> /dev/null
}

# Function to detect OS type
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if is_wsl; then
                echo "WSL"
            else
                echo "Linux"
            fi
            ;;
        Darwin*)
            echo "macOS"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows_GitBash"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# Determine the OS
OS_TYPE=$(detect_os)

# Adjust Ollama host based on OS type
case "$OS_TYPE" in
    "WSL")
        echo "Running inside WSL. Ollama host: $OLLAMA_HOST"
        ;;
    "Linux")
        echo "Running on native Linux. Ollama host: $OLLAMA_HOST"
        ;;
    "macOS")
        echo "Running on macOS. Ollama host: $OLLAMA_HOST"
        ;;
    "Windows_GitBash")
        echo "Running on Windows via Git Bash. Ollama host: $OLLAMA_HOST"
        ;;
    "UNKNOWN")
        echo "Unknown OS type: $OS_TYPE. Using Ollama host: $OLLAMA_HOST"
        ;;
esac

echo "Using Ollama model: $OLLAMA_MODEL_NAME"

if [ -n "$USER_PROVIDED_DESCRIPTION" ]; then
    # Display the description being used, ensure it's printed safely
    printf "Using user-provided description: %s\n" "$USER_PROVIDED_DESCRIPTION"
fi

# --- Your existing commit-with-ai logic starts here ---

# 1. Get the diff of staged changes
DIFF_OUTPUT=$(git diff --staged)

if [ -z "$DIFF_OUTPUT" ]; then
    echo "No staged changes to commit."
    exit 0
fi

# 2. Prepare the prompt for Ollama
PROMPT_MAIN_INSTRUCTION="Generate a concise commit message in the conventional commit format from the following git diff:"
PROMPT_ADDITIONAL_CONTEXT=""

if [ -n "$USER_PROVIDED_DESCRIPTION" ]; then
    # Escape characters that might be problematic in the prompt string itself or in JSON later.
    # This primarily targets quotes and backslashes for shell variable construction.
    # jq will handle full JSON string escaping if used.
    CLEANED_USER_DESCRIPTION=$(echo "$USER_PROVIDED_DESCRIPTION" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/`/\\`/g' -e 's/\$/\\\$/g')
    PROMPT_ADDITIONAL_CONTEXT="Consider this user summary: \"$CLEANED_USER_DESCRIPTION\""
fi

# Construct the final prompt
if [ -n "$PROMPT_ADDITIONAL_CONTEXT" ]; then
  FINAL_PROMPT_FOR_OLLAMA="$PROMPT_ADDITIONAL_CONTEXT
$PROMPT_MAIN_INSTRUCTION
$DIFF_OUTPUT"
else
  FINAL_PROMPT_FOR_OLLAMA="$PROMPT_MAIN_INSTRUCTION
$DIFF_OUTPUT"
fi

# 3. Call Ollama API to generate the commit message
echo "Generating commit message with Ollama..."

if check_jq; then
    echo "Using jq for JSON processing."
    # Pipe the prompt to jq, and pipe jq's output (the JSON payload) to curl.
    # jq reads prompt_text from its stdin using --rawfile.
    # curl reads the JSON payload from its stdin using --data-binary @-.
    # curl options:
    #  -s: be silent
    #  -S: show error message on stderr if -s is used and curl fails
    #  -f: fail silently (no output to stdout) on server errors (4xx, 5xx), and return exit code 22
    #  -L: follow redirects (good practice for robustness)

    JQ_SCRIPT_ARGS=(
        -c -n # compact output, null input
        --arg model "$OLLAMA_MODEL_NAME" \
        --rawfile prompt_text /dev/stdin \
        --argjson stream false \
        --argjson temp 0.2 \
        --argjson num_predict 128 \
        '{model: $model, prompt: $prompt_text, stream: $stream, options: {temperature: $temp, num_predict: $num_predict}}'
    )

    set -o pipefail # Ensures pipeline fails if any command in it fails
    # Stderr from curl (due to -S if curl itself fails, e.g. connection refused) will go to script's stderr.
    # Stdout from curl (the API response body) is captured by API_RESPONSE_BODY.
    API_RESPONSE_BODY=$(echo "$FINAL_PROMPT_FOR_OLLAMA" | jq "${JQ_SCRIPT_ARGS[@]}" | \
        curl --max-time 180 -sS -L -f -X POST "$OLLAMA_HOST/api/generate" \
        -H "Content-Type: application/json" \
        --data-binary @- )
    PIPELINE_EXIT_STATUS=$?
    set +o pipefail # Restore default behavior

    COMMIT_MESSAGE_RESPONSE="$API_RESPONSE_BODY" # Default for error reporting if parsing fails or pipeline failed

    if [ $PIPELINE_EXIT_STATUS -ne 0 ]; then
        echo "Error: Ollama API request pipeline failed with exit status $PIPELINE_EXIT_STATUS." >&2
        # API_RESPONSE_BODY might be empty if curl -f suppressed output, or contain curl error if -S printed it.
        # The generic error handler later will use COMMIT_MESSAGE_RESPONSE.
        GENERATED_COMMIT_MESSAGE="" # Ensure it's empty on failure
    else
        # Pipeline succeeded (exit status 0), try to parse the response
        GENERATED_COMMIT_MESSAGE=$(echo "$API_RESPONSE_BODY" | jq -r '.response // ""')
        if [ -z "$GENERATED_COMMIT_MESSAGE" ] && [ -n "$API_RESPONSE_BODY" ]; then
            # HTTP success, but .response field was missing or empty in a non-empty body
            echo "Warning: Ollama API request succeeded, but the 'response' field was missing or empty in the JSON." >&2
            # COMMIT_MESSAGE_RESPONSE is already set to API_RESPONSE_BODY for the generic error message
        fi
    fi

else
    echo "jq not found. Using sed/grep for JSON processing (less robust)."
    # Escape prompt content for embedding in JSON string
    JSON_ESCAPED_PROMPT_CONTENT=$(echo "$FINAL_PROMPT_FOR_OLLAMA" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g')

    COMMIT_MESSAGE_RESPONSE=$(curl -s -X POST "$OLLAMA_HOST/api/generate" \
        -H "Content-Type: application/json" \
        --data-binary @- <<EOF_PAYLOAD
{
    "model": "$OLLAMA_MODEL_NAME",
    "prompt": "$JSON_ESCAPED_PROMPT_CONTENT",
    "stream": false,
    "options": { "temperature": 0.2, "num_predict": 128 }
}
EOF_PAYLOAD
    )
    GENERATED_COMMIT_MESSAGE=$(echo "$COMMIT_MESSAGE_RESPONSE" | grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"$//')
fi

if [ -z "$GENERATED_COMMIT_MESSAGE" ]; then
    echo "Failed to generate commit message. Ollama response was empty or malformed."
    echo "Ollama Response: $COMMIT_MESSAGE_RESPONSE"
    exit 1
fi

echo "Generated Commit Message:"
echo "$GENERATED_COMMIT_MESSAGE"

# 4. Ask the user for confirmation
read -p "Do you want to use this commit message? (y/n/e for edit): " -n 1 -r REPLY </dev/tty
echo # (optional) move to a new line

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Use a temporary file for the commit message to handle multi-line messages robustly
    TEMP_COMMIT_MSG_FILE=$(mktemp)
    echo "$GENERATED_COMMIT_MESSAGE" > "$TEMP_COMMIT_MSG_FILE"
    git commit -F "$TEMP_COMMIT_MSG_FILE"
    rm -f "$TEMP_COMMIT_MSG_FILE" # Clean up immediately after use
    echo "Commit successful!"
elif [[ $REPLY =~ ^[Ee]$ ]]; then
    # Open the message in an editor
    TEMP_MSG_FILE=$(mktemp)
    # Ensure temp file is cleaned up if script exits unexpectedly
    trap 'rm -f "$TEMP_MSG_FILE"; trap - EXIT INT TERM' EXIT INT TERM

    echo "$GENERATED_COMMIT_MESSAGE" > "$TEMP_MSG_FILE"

    EDITOR_LAUNCHED=false
    if [ -n "$EDITOR" ]; then
        "$EDITOR" "$TEMP_MSG_FILE"
        EDITOR_LAUNCHED=true
    elif command -v nano &> /dev/null; then
        nano "$TEMP_MSG_FILE"
        EDITOR_LAUNCHED=true
    elif command -v vi &> /dev/null; then
        vi "$TEMP_MSG_FILE"
        EDITOR_LAUNCHED=true
    else
        echo "No suitable editor found (set \$EDITOR or install nano/vi)."
        read -p "Commit with the original generated message? (y/n): " -n 1 -r confirm_no_edit </dev/tty
        echo
        if [[ $confirm_no_edit =~ ^[Yy]$ ]]; then
            echo "Committing with original generated message."
            # TEMP_MSG_FILE already contains the original message
            git commit -F "$TEMP_MSG_FILE"
            echo "Commit successful!"
            # Script will proceed to cleanup phase below
        else
            echo "Commit aborted due to no editor and user cancellation."
            # Trap will clean up TEMP_MSG_FILE on exit.
            exit 1
        fi
    fi

    # This block is reached if an editor was launched,
    # or if no editor was found but user chose to commit original (in which case commit already happened).
    if [ "$EDITOR_LAUNCHED" = true ]; then
        # Check if the file still exists and is not empty after editing
        if [ ! -s "$TEMP_MSG_FILE" ]; then # -s checks if file exists and has a size greater than zero
            echo "Warning: Commit message is empty or file was deleted after edit."
            read -p "Abort commit? (y/n): " -n 1 -r confirm_abort_empty </dev/tty
            echo
            if [[ $confirm_abort_empty =~ ^[Yy]$ ]]; then
                echo "Commit aborted."
                # Trap will clean up TEMP_MSG_FILE on exit.
                exit 1
            fi
        fi
        git commit -F "$TEMP_MSG_FILE"
        echo "Commit successful after edit!"
    fi

    rm -f "$TEMP_MSG_FILE" # Explicitly clean up the temp file
    trap - EXIT INT TERM   # Clear the trap as we've handled the file
else
    echo "Commit aborted."
fi