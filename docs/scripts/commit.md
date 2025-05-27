# `commit` - Conventional Commit Messages with Commitizen

## Purpose

The `commit` script, defined in `package.json` as `pnpm dlx git-cz`, is used to initiate an interactive process for creating Git commit messages that adhere to the Conventional Commits specification.

Using `git-cz` (Commitizen) helps ensure that commit messages are consistent, informative, and can be easily parsed by automated tools for tasks like generating changelogs or triggering releases.

## How It Works

When you run `pnpm run commit`:

1. `pnpm dlx` downloads and executes `git-cz` if it's not already available.
2. Commitizen presents a series of prompts (e.g., type of change, scope, short description, body, breaking changes, footer) to guide you through crafting a well-formed commit message.
3. Once you complete the prompts, Commitizen creates the commit with the generated message.

## Usage

To use this script, stage your changes (`git add .`) and then run:

```bash
pnpm run commit
```
