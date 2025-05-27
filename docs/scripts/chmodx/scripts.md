# `chmodx:scripts` - Make All Project Scripts Executable

## Purpose

The `chmodx:scripts` command, defined in `package.json` as `bash ./scripts/chmodx.sh -r scripts`, is a convenient shortcut for making all files within the project's main `scripts` directory (and its subdirectories) executable.

This is particularly useful for ensuring that all utility scripts, hooks, or other executable files located under the `./scripts/` path have the necessary execute permissions.

## How It Works

This command directly invokes the main `./scripts/chmodx.sh` utility with specific arguments:

- `-r`: Enables recursive mode. This means `chmodx.sh` will process the specified directory and all files within its subdirectories.
- `scripts`: Specifies the target directory to process, which is the `./scripts/` directory at the root of your project.

As a result, `chmodx.sh` will:

1. Attempt to make the `./scripts` directory itself executable.
2. Find all regular files within `./scripts` (and any subdirectories like `./scripts/git/`, `./scripts/lint/`) and attempt to make each of them executable (`chmod +x`).

## Usage

To make all files in the `./scripts` directory (and its subdirectories) executable, run:

```bash
pnpm run chmodx:scripts
```

This command does not take any additional arguments or options itself; it's a pre-configured call to `chmodx.sh`. For more granular control or different options, you would use the main `chmodx` script directly.
