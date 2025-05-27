# Webnodex/devtoolkit an Opinionated Developer Toolkit 🛠️

Welcome to the `webnodex/devtoolkit` repository! This project is a collection of utility scripts and configurations designed to streamline common development tasks, improve code quality, and enhance the overall developer experience.

## Features

This toolkit provides a range of scripts for:

- **Git Workflow Automation**: Tools for conventional commits, AI-assisted commit message generation, and Git-aware command execution.
- **Code Quality & Linting**: Scripts for linting Markdown files and potentially other code types.
- **File Management**: Utilities like `chmodx.sh` for managing file permissions.
- **Developer Experience**: Integration with tools like Lefthook for automated Git hooks.

## Getting Started

1. **Clone the repository:**

   ```bash
   git clone https://github.com/webnodex/devtoolkit.git
   cd devtoolkit
   ```

2. **Install dependencies:**

   ```bash
   pnpm install
   ```

   This will also set up Lefthook Git hooks via the `postinstall` script.

## Documentation 📖

For detailed information on all available scripts, their usage, options, and examples, please refer to the main documentation entry point:

- **Full Documentation**

## Scripts Overview

Many useful scripts are defined in the `package.json` and can be run using `pnpm run <script-name>`. Key scripts include:

- `pnpm run commit`: Interactive conventional commit message generation.
- `pnpm run commit:ai`: AI-assisted commit message generation.
- `pnpm run chmodx`: Make files executable.
- `pnpm run lintmd`: Lint modified Markdown files.
- `pnpm run cmmt -- <command>`: Wrap a command with Git stashing, execution on affected files, and auto-commit.

Explore the scripts documentation for a complete list and details.

## Contributing

Contributions are welcome! Please refer to the (future) `CONTRIBUTING.md` for guidelines.

## License

This project is licensed under the (Your License Here - e.g., MIT License).
