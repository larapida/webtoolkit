# Utility Scripts Documentation

This directory contains documentation for the various utility scripts used in the `webnodex/devtoolkit` project.

## Available Scripts

- [comand.sh](../../scripts/chmodx.md)
  - Sets executable permissions for files and directories, with options for recursive and verbose operation. See [chmodx.sh](../../scripts/chmodx.md) for details.
- [command2.sh](../../scripts/cmmt.md)
  - A Git-aware command wrapper that stashes changes, runs a command on affected files, commits the results, and unstashes.
- [commit](doc.md) (npm script)
  - Uses Commitizen (`git-cz`) for creating Conventional Commit messages.
- [lint:md](../../scripts/lint-md.sh) alias for lint-md.sh\*\*
  - Lints and fixes only modified or untracked Markdown files using `markdownlint-cli2`.

## Scoped:Scripts

```bash
[scope]:[script]
```

These scripts are often related to a specific domain like Git or linting and have their documentation organized into subdirectories.

- **chmodx Specifics**
  - Documentation related to specific `chmodx` use cases.
- **Commit Related**
  - Scripts and documentation related to Git commit message generation.
- **Git Utilities**
  - General Git utility scripts.
- **Linting Utilities**
  - Scripts related to code and document linting.
