<!-- ENGLISH ONLY -->

# `script.sh` - Title 🔄

The `script.sh` script <!-- /GENERATE a short description of what it does on a single line -->

> [!IMPORTANT]  
> Se script alias definitpo in `package.json` informare gli utenti che è uno script locale.
> Se è uno script bash allora elimina la nota
> se è uno script bash ma fa uso di script locali npm, ingformare gli utenti che l'utilizzo diretto con curl non funzionerà a meno che la cartella [scripts/](../../../scripts) non venga scaricata e installata nel repository locale.
> in caso più avanti nel testro, fornire istruzioni su come configurare lo script npm per il suo corretto utilizzo

## Purpose

<!-- EXAMPLE OF PURPOSE -->

1. Identifies files currently modified or untracked in your Git repository.
2. Stashes these existing changes (including untracked files) to create a clean working state.
3. Executes a user-provided command, specifically targeting only the initially identified "affected files."
4. Checks which of these "affected files" were actually modified by the executed command.
5. Stages (adds to the Git index) only those "affected files" that were changed by the command.
6. Commits these staged changes with an automated commit message.
7. Attempts to pop the stash created in step 2, restoring your original working state.

This is ideal for running formatters (like Prettier), linters (like ESLint with `--fix`), or other code modification tools on your work-in-progress, committing their specific changes, and then seamlessly returning to your previous state.

## Usage

<!-- /GENERATE description of how to use it -->

```bash
./path-to-script/cmmt.sh [--option,-O] <command> [args_for_command...]
```

<!-- only if availsable -->

Or, using the `pnpm` script defined in `package.json`:

```bash
pnpm run cmmt [--options] <command> [args_for_command...]
```

## How It Works

1. **Argument Parsing**: Separates the wrapper script's logic from the command it needs to execute.
2. **Identify Affected Files**: Uses `git status --porcelain` to find all modified, added, or untracked files.
3. **Stash**: If changes are found, `git stash push -u -m "wrapper-script-stash-..."` saves the current state.
4. **Execute Command**: Runs the `<command_to_wrap>` with the list of initially affected files appended as arguments. This ensures the command _only_ operates on these files.
5. **Stage & Commit**:
   - Iterates through the initially affected files.
   - If a file was modified by the wrapped command (checked via `git status --porcelain -- <file>`), it's staged using `git add <file>`.
   - If any files were staged, a commit is made with a message like "Automated: Apply '<command_name>' to affected files".
6. **Pop Stash**: Attempts `git stash pop` to restore the original changes. Handles potential conflicts by advising manual resolution.

## Options

The `script.sh` script itself does not take options before the `--` separator. All arguments after `--` are considered part of the command to be wrapped.

## Prerequisites and Dependencies for local usage <!-- see example of how to configuere all dependencies -->

- **Git**: Must be installed and accessible. The script must be run from within a Git repository.

## Examples

1. **Format staged/modified/untracked files with Prettier and commit the changes:**

   ```bash
   pnpm run cmmt -- pnpm prettier --write
   ```

2. **Lint and fix files with ESLint and commit the fixes:**

   ```bash
   pnpm run cmmt -- pnpm eslint --fix
   ```

3. **Run a custom script on affected files and commit its changes:**

   ```bash
   pnpm run cmmt -- ./scripts/my-custom-processor.sh --some-option
   ```

## Remote Execution (Example)

You can download and execute this script directly from a raw GitHub URL. The command to be wrapped and its arguments must be passed after the `--` for `bash -s --`.

```bash
# Replace with your actual repository URL and branch/commit SHA
REPO_BASE_URL="https://raw.githubusercontent.com/your-username/your-repo/main"
SCRIPT_PATH="scripts/cmmt.sh"

# Example: Run prettier --write on affected files
# Note the double '--': the first is for 'bash -s', the second is for 'cmmt.sh'
curl -sSL "${REPO_BASE_URL}/${SCRIPT_PATH}" | bash -s -- -- pnpm prettier --write
```

**Important Considerations for Remote Execution:**

- The script operates on the local Git repository where it's executed.
- Ensure the commands being wrapped (e.g., `pnpm prettier`) are available in the environment where the script is run.
- Remote execution via `curl | bash` should be done with caution and only from trusted sources.

<!-- /GENERATE if necessary (see note in the header) example of how to configure dependencies locally -->

:bye:
