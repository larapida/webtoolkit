# `postinstall` - Lefthook Git Hook Installation

## Purpose

The `postinstall` script, defined in `package.json` as `lefthook install`, is automatically executed by `pnpm` (or `npm`/`yarn`) after project dependencies are installed or updated.

Its primary function is to install and configure Git hooks managed by Lefthook. Lefthook allows you to manage Git hooks using a configuration file (typically `lefthook.yml`) committed to your repository, ensuring consistent hook behavior across all developer environments.

## How It Works

When `lefthook install` is run:

1. Lefthook reads its configuration file (e.g., `lefthook.yml`).
2. It creates or updates the necessary hook scripts in your local `.git/hooks/` directory based on this configuration.

This ensures that any defined pre-commit, pre-push, commit-msg, or other Git hooks are active for your repository.

## Usage

This script is typically not run manually. It's part of the automated setup process when you run `pnpm install`. If you need to manually re-initialize Lefthook hooks, you can run `pnpm lefthook install` directly.
