# `commit:ai` - AI-Assisted Git Commit Message Generator 🤖

## Purpose

The `commit:ai` script (`./scripts/git/cmmt-ai.sh`) leverages an AI model (likely via Ollama) to help generate Git commit messages based on a brief description of your changes. This can speed up the commit process and help create more descriptive messages.

## Usage

To use this script via `pnpm`:

```bash
pnpm run commit:ai [options]
```

Directly (if in the `scripts/git` directory or using the full path):

```bash
bash ./scripts/git/cmmt-ai.sh [options]
```

## Options

Based on common patterns for such scripts, the actual options might vary. Refer to the script's internal help or source if available.

- `-d "Description"`: Provides an initial description of the changes. If omitted, the script will likely prompt you to enter it.
- `-h`: Displays a help message for the script.

## How It Works

1. The script typically takes a brief description of the code changes as input (either via the `-d` option or by prompting the user).
2. It sends this description to a locally running AI model (e.g., Llama3 via Ollama) configured to generate Git commit messages.
3. The AI model processes the input and returns a suggested commit message.
4. The script displays the generated message, often providing a `git commit -m "..."` command that you can copy and paste.

## Prerequisites

- A running Ollama instance (or a similar local AI model server).
- The required AI model (e.g., `tavernari/git-commit-message` or `llama3`) pulled and available to Ollama.

## Examples

1. **Run interactively (script will prompt for description):**

   ```bash
   pnpm run commit:ai
   ```

2. **Provide a description directly:**

   ```bash
   pnpm run commit:ai -d "fix: resolve issue with user login form validation"
   ```

## Remote Execution (Example)

You can download and execute this script directly from a raw GitHub URL using `curl` and `bash`.

```bash
# Replace with your actual repository URL and branch/commit SHA
REPO_BASE_URL="https://raw.githubusercontent.com/your-username/your-repo/main"
SCRIPT_PATH="scripts/git/cmmt-ai.sh"

# Run interactively
curl -sSL "${REPO_BASE_URL}/${SCRIPT_PATH}" | bash

# Run with a description (arguments are passed after --)
curl -sSL "${REPO_BASE_URL}/${SCRIPT_PATH}" | bash -s -- -d "feat: add new reporting feature"
```

**Note:** Ensure the script has execute permissions if downloaded and run locally. Remote execution via `curl | bash` should be done with caution and only from trusted sources.
