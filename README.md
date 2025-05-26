# SMUX: Smart Multiplexer for Developer Workspaces

SMUX is a command-line tool that helps developers efficiently manage multiple project workspaces by automating the setup of development environments, including applications, browser tabs, terminal directories, VSCode workspaces, and MCP server configurations.

## Features

- **Workspace Management**: Create, switch between, and configure workspaces for different projects
- **Application Launching**: Automatically open project-specific applications
- **Browser URL Management**: Open relevant websites and web applications
- **Terminal Directory Setup**: Open terminal windows in project-specific directories
- **VSCode Workspace Integration**: Open the appropriate VSCode workspace
- **MCP Server Configuration**: Configure Model Context Protocol servers for AI tools like Claude and Windsurf
- **Template-based Workspace Creation**: Create new workspaces based on existing templates

## Installation

### Prerequisites

- macOS (currently only supports macOS)
- Swift 5.7 or later
- Xcode 14.0 or later (for development)

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/saadatqadri/smux.git
   cd smux
   ```

2. Build the project:
   ```bash
   swift build -c release
   ```

3. Install the binary (optional):
   ```bash
   cp .build/release/smux /usr/local/bin/smux
   ```

## Usage

### Basic Commands

```bash
# Create a new workspace
smux create <workspace-name> [options]

# Switch to an existing workspace
smux switch <workspace-name> [options]

# List all workspaces
smux list

# Configure an existing workspace
smux config <workspace-name> [options]

# Delete a workspace
smux delete <workspace-name>
```

### Creating a Workspace

```bash
# Create a basic workspace
smux create my-project

# Create a workspace with specific applications
smux create my-project --applications "Safari,VSCode,Terminal"

# Create a workspace with browser URLs
smux create my-project --browser-urls "https://github.com/myorg/myrepo,https://jira.myorg.com"

# Create a workspace with terminal directories
smux create my-project --terminal-dirs "~/projects/my-project,~/projects/my-project/api"

# Create a workspace with a VSCode workspace
smux create my-project --vscode-workspace "~/projects/my-project"

# Create a workspace with MCP server configurations
smux create my-project --mcp-config path/to/mcp-config.json

# Create a workspace interactively
smux create my-project --interactive

# Create a workspace based on a template
smux create my-project --template existing-project
```

### Switching Workspaces

```bash
# Switch to a workspace
smux switch my-project

# Switch to a workspace with verbose output
smux switch my-project --verbose

# Force switch to a workspace (skip confirmation prompts)
smux switch my-project --force
```

### MCP Server Configuration

SMUX supports configuring Model Context Protocol (MCP) servers for AI tools like Claude and Windsurf. MCP servers are defined in the workspace configuration and are automatically configured when switching workspaces.

Example MCP configuration JSON:

```json
{
  "karbon": {
    "command": "node",
    "args": ["/path/to/karbon-mcp-server/dist/index.js"],
    "env": {
      "KARBON_BEARER_TOKEN": "your-token",
      "KARBON_ACCESS_KEY": "your-access-key"
    }
  },
  "linear-mcp": {
    "command": "node",
    "args": ["/path/to/linear-mcp/build/index.js"],
    "env": {
      "LINEAR_API_KEY": "your-linear-api-key"
    },
    "disabled": false,
    "alwaysAllow": ["list_teams", "list_issues"]
  }
}
```

## Project Structure

```
Sources/
  └── smux/
      ├── main.swift             # Entry point and CLI implementation
      ├── Models/
      │   ├── Workspace.swift    # Workspace data model
      │   └── WorkspaceManager.swift # Workspace operations
      └── Utils/
          └── Process.swift      # Process execution utilities
```

## Development

### Architecture

SMUX follows a simple architecture:

1. **Models**: Data structures representing workspaces and configurations
2. **WorkspaceManager**: Core business logic for managing workspaces
3. **CLI**: Command-line interface implemented in main.swift

### Adding New Features

To add new features to SMUX:

1. **Extend the Workspace Model**: If your feature requires new configuration data, extend the `Workspace` struct in `Workspace.swift`.
2. **Implement Business Logic**: Add methods to `WorkspaceManager.swift` to handle the new functionality.
3. **Update CLI**: Modify `main.swift` to add new commands or options for your feature.
4. **Add Tests**: Write tests for your new functionality.

### Workspace Configuration Format

Workspace configurations are stored as JSON files in `~/.smux/`. Each workspace has its own file named `<workspace-name>.json`. The configuration format is:

```json
{
  "name": "workspace-name",
  "applications": [
    {
      "name": "ApplicationName",
      "bundleIdentifier": "com.example.app"
    }
  ],
  "browserUrls": [
    "https://example.com"
  ],
  "terminalDirectories": [
    "~/path/to/directory"
  ],
  "vscodeWorkspace": "~/path/to/workspace.code-workspace",
  "mcpServers": {
    "server-name": {
      "command": "executable",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value"
      },
      "disabled": false,
      "alwaysAllow": ["function1", "function2"]
    }
  }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Roadmap

- **Workspace Secrets Management**: Securely store and manage sensitive information
- **Cross-platform Support**: Add support for Linux and Windows
- **Workspace Sharing**: Export and import workspaces for team collaboration
- **Integration with More Tools**: Support additional development tools and IDEs
- **Workspace Snapshots**: Save and restore workspace states
