# Utility Scripts Documentation

This directory contains documentation for the various utility scripts used in the `webnodex/devtoolkit` project.

## Available Scripts

- **chmodx.sh**
  - Sets executable permissions for files and directories, with options for recursive and verbose operation.
- **cmmt.sh**
  - A Git-aware command wrapper that stashes changes, runs a command on affected files, commits the results, and unstashes.
- **commit (npm script)**
  - Uses Commitizen (`git-cz`) for creating Conventional Commit messages.
- **postinstall (npm script)**
  - Installs Lefthook Git hooks automatically after dependency installation.
- **lint:md (lint-md.sh)**
  - Lints and fixes only modified or untracked Markdown files using `markdownlint-cli2`.

## Scoped Scripts

These scripts are often related to a specific domain like Git or linting and have their documentation organized into subdirectories.

- **chmodx Specifics**
  - Documentation related to specific `chmodx` use cases.
- **Commit Related**
  - Scripts and documentation related to Git commit message generation.
- **Git Utilities**
  - General Git utility scripts.
- **Linting Utilities**
  - Scripts related to code and document linting.

Browse the respective `README.md` files in the subdirectories for more details.
