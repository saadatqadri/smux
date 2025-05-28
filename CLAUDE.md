# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

```bash
# Build the project in debug mode
swift build

# Build the project in release mode
swift build -c release

# Run the project
swift run smux

# Run tests
swift test

# Install locally after building
cp .build/release/smux /usr/local/bin/smux
```

## Project Architecture

SMUX (Smart Multiplexer) is a macOS command-line tool that helps developers manage multiple project workspaces by automating the setup of development environments. The architecture follows a simple structure:

### Core Components

1. **Models**
   - `Workspace.swift`: Defines the data structure for workspace configurations including applications, browser URLs, terminal directories, VSCode workspaces, and MCP server configurations
   - `WorkspaceManager.swift`: Singleton that manages workspace operations (create, switch, list, etc.)

2. **Command Line Interface**
   - `main.swift`: Implements the CLI using ArgumentParser with subcommands (create, switch, list, config, snapshot)

### Key Concepts

1. **Workspace**: A configuration that includes:
   - Application settings (name, bundle identifier, window positions)
   - Browser URLs to open
   - Terminal directories to launch
   - VSCode workspace path
   - MCP server configurations for AI tools like Claude and Windsurf

2. **MCP Server Configuration**: Model Context Protocol servers for AI tooling:
   - Command and arguments to launch the server
   - Environment variables
   - Access control settings (disabled, alwaysAllow)

3. **Persistence**: Workspaces are stored as JSON files in `~/.smux/` directory

### Data Flow

1. User creates or configures a workspace via CLI
2. Workspace configuration is serialized and saved to the filesystem
3. When switching workspaces:
   - Applications are launched via AppleScript
   - Browser URLs are opened
   - Terminal windows are set up
   - VSCode workspace is opened
   - MCP servers are configured (e.g., updating Claude Desktop config)

### Key Files

- `Sources/smux/Models/Workspace.swift`: Core data model for workspace configuration
- `Sources/smux/Models/WorkspaceManager.swift`: Business logic for workspace operations
- `Sources/smux/main.swift`: CLI implementation with all subcommands

## Development Notes

- The project is macOS-only, using AppleScript for application automation
- Workspace configurations are stored as JSON files in the `~/.smux/` directory
- The MCP server configuration feature modifies config files for Claude Desktop
- Future planned features include workspace secrets management, cross-platform support, and workspace sharing