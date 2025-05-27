# Script: `cmmt-msg.sh`

## Overview

`cmmt-msg.sh` is a shell script that leverages Ollama (with a model like `llama3`) to generate conventional commit messages based on staged Git changes. It prepares a prompt with the diff, calls the Ollama API, and then presents the generated message to the user for confirmation or editing before committing.

## Invocation

### Direct Execution

```bash
bash ./scripts/git/cmmt-msg.sh
```

This script is typically run from the root of a Git repository where you have staged changes you want to commit.

## Features

- **AI-Powered Commit Messages**: Uses Ollama to generate commit messages.
- **Conventional Commits**: Prompts the AI to follow the Conventional Commits specification.
- **OS Detection**: Attempts to detect the operating system (Linux, WSL, macOS, Windows Git Bash) to correctly set the `OLLAMA_HOST`. It defaults to `http://localhost:11434`.
- **User Interaction**:
  - Displays the generated commit message.
  - Asks for confirmation (`y/n/e`):
    - `y`: Commits with the generated message.
    - `n`: Aborts the commit.
    - `e`: Opens the generated message in a text editor (`$EDITOR`, `nano`, or `vi`) for modification before committing.
- **Error Handling**: Checks for empty diffs and failures in message generation.

## Configuration

- **`OLLAMA_HOST`**: The script sets a default `OLLAMA_HOST` (usually `http://localhost:11434`). You can modify this variable within the script if your Ollama instance runs on a different host or port.
- **Ollama Model**: The script is configured to use the `llama3` model by default. This can be changed in the `curl` request JSON payload within the script.
- **Prompt**: The prompt sent to Ollama can be customized within the script for different styles or levels of detail.
- **Editor**: For editing messages, the script uses the `$EDITOR` environment variable. If not set, it falls back to `nano`, then `vi`.

## Dependencies

- `git`: Required for `git diff --staged`.
- `curl`: Required for making API calls to Ollama.
- `grep`, `sed`, `tr`: Used for text manipulation.
- An Ollama instance running and accessible at `OLLAMA_HOST`.
- A suitable text editor (like `nano` or `vi`) if you plan to use the edit option and `$EDITOR` is not set.

## Workflow

1. Checks if running in WSL to adjust `OLLAMA_HOST` if necessary.
2. Retrieves staged changes using `git diff --staged`.
3. If no staged changes, it exits.
4. Constructs a prompt for Ollama including the diff.
5. Sends a request to the Ollama API (`/api/generate`) to get a commit message.
6. Extracts the generated message from the API response.
7. If message generation fails, it reports an error and exits.
8. Displays the generated message and prompts the user to accept (`y`), reject (`n`), or edit (`e`).
9. If accepted, commits using `git commit -m "GENERATED_MESSAGE"`.
10. If edit is chosen, opens the message in an editor, then commits with the edited message.
11. If rejected, aborts the operation.

## Example Usage

```bash
# Stage your changes first
git add .

# Run the script to generate and confirm the commit message
bash ./scripts/git/cmmt-msg.sh
```
