// Sources/smux/main.swift
import ArgumentParser
import Foundation

// MARK: - Main Command
struct Smux: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "smux",
        abstract: "A workspace multiplexer for macOS",
        subcommands: [
            Create.self,
            Switch.self,
            List.self,
            Config.self,
            Snapshot.self
        ]
    )
}

// MARK: - Subcommands
extension Smux {
    struct Create: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Create a new workspace"
        )

        @Argument(help: "Name of the workspace to create")
        var name: String

        @Option(name: .long, help: "Use an existing workspace as a template")
        var template: String?

        @Option(name: .long, help: "VSCode workspace file path")
        var vscodeWorkspace: String?

        @Option(name: .long, help: "Comma-separated list of URLs to open")
        var browserUrls: String?

        @Option(name: .long, help: "Comma-separated list of terminal working directories")
        var terminalDirs: String?
        
        @Option(name: .long, help: "JSON file containing MCP server configurations")
        var mcpConfig: String?

        @Flag(name: .shortAndLong, help: "Enable interactive mode for configuration")
        var interactive: Bool = false

        @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
        var force: Bool = false

        func run() throws {
            let manager = WorkspaceManager.shared

            // Check if workspace already exists
            if manager.getWorkspace(name: name) != nil && !force {
                print("Workspace '\(name)' already exists. Use --force to overwrite.")
                throw ExitCode.failure
            }

            // Interactive mode
            if interactive {
                return try runInteractiveMode(manager: manager)
            }

            // Template-based creation
            if let templateName = template {
                print("Creating workspace '\(name)' from template '\(templateName)'...")
                guard let workspace = manager.createWorkspaceFromTemplate(name: name, templateName: templateName) else {
                    print("Failed to create workspace from template.")
                    throw ExitCode.failure
                }

                print("Successfully created workspace '\(name)' from template '\(templateName)'")
                printWorkspaceSummary(workspace)
                return
            }
            
            // Normal creation with command-line options
            let urls = browserUrls?.split(separator: ",").map(String.init) ?? []
            let dirs = terminalDirs?.split(separator: ",").map(String.init) ?? []
            
            // Parse MCP server configurations if provided
            var mcpServers: [String: Workspace.MCPServerConfig]? = nil
            if let mcpConfigPath = mcpConfig {
                mcpServers = loadMCPConfigFromFile(mcpConfigPath)
            }

            guard let workspace = manager.createWorkspace(
                name: name,
                vscodeWorkspace: vscodeWorkspace,
                browserUrls: urls,
                terminalDirectories: dirs,
                applications: [],
                mcpServers: mcpServers
            ) else {
                print("Failed to create workspace.")
                throw ExitCode.failure
            }

            print("Successfully created workspace '\(name)'")
            printWorkspaceSummary(workspace)
        }
        
        private func runInteractiveMode(manager: WorkspaceManager) throws -> Void {
            print("Creating workspace '\(name)' in interactive mode...")
            print("Press Enter to skip any option.")
            
            // Helper function to parse JSON input
            func parseJSONInput(_ input: String) -> [String: Any]? {
                guard !input.isEmpty else { return nil }
                guard let data = input.data(using: .utf8) else { return nil }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        return json
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
                return nil
            }

            // VSCode workspace
            print("\nVSCode workspace file path:")
            let vscodeInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
            let vscode = vscodeInput?.isEmpty == false ? vscodeInput : nil

            // Browser URLs
            print("\nBrowser URLs (comma-separated):")
            let urlsInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
            let urls = urlsInput?.isEmpty == false ?
                urlsInput!.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) } :
                []

            // Terminal directories
            print("\nTerminal directories (comma-separated):")
            let dirsInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
            let dirs = dirsInput?.isEmpty == false ?
                dirsInput!.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) } :
                []

            // Applications (basic support for now)
            print("\nApplications to include (comma-separated, e.g., 'Safari,Mail'):")
            let appsInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            var applications: [Workspace.ApplicationConfig] = []
            if let appsInput = appsInput, !appsInput.isEmpty {
                applications = appsInput.split(separator: ",")
                    .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    .map { Workspace.ApplicationConfig(name: $0, bundleIdentifier: "", windowPositions: nil) }
            }

            // MCP server configurations
            print("\nMCP server configurations (JSON format, e.g., '{\"karbon\":{\"command\":\"node\",\"args\":[\"/path/to/server.js\"]}}'): ")
            let mcpInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            var mcpServers: [String: Workspace.MCPServerConfig]? = nil
            if let mcpInput = mcpInput, !mcpInput.isEmpty {
                if let mcpJson = parseJSONInput(mcpInput) as? [String: [String: Any]] {
                    mcpServers = [:]  
                    for (serverName, serverConfig) in mcpJson {
                        if let command = serverConfig["command"] as? String,
                           let args = serverConfig["args"] as? [String] {
                            var config = Workspace.MCPServerConfig(command: command, args: args)
                            
                            if let env = serverConfig["env"] as? [String: String] {
                                config.env = env
                            }
                            
                            if let disabled = serverConfig["disabled"] as? Bool {
                                config.disabled = disabled
                            }
                            
                            if let alwaysAllow = serverConfig["alwaysAllow"] as? [String] {
                                config.alwaysAllow = alwaysAllow
                            }
                            
                            mcpServers?[serverName] = config
                        }
                    }
                } else {
                    print("Invalid MCP server configuration format. Skipping.")
                }
            }
            
            // Create the workspace
            guard let workspace = manager.createWorkspace(
                name: name,
                vscodeWorkspace: vscode,
                browserUrls: urls,
                terminalDirectories: dirs,
                applications: applications,
                mcpServers: mcpServers
            ) else {
                print("Failed to create workspace.")
                throw ExitCode.failure
            }

            print("\nSuccessfully created workspace '\(name)'")
            printWorkspaceSummary(workspace)
            return
        }
        
        private func printWorkspaceSummary(_ workspace: Workspace) {
            print("\nWorkspace Configuration:")
            print("  Name: \(workspace.name)")

            if let vscode = workspace.vscodeWorkspace {
                print("  VSCode Workspace: \(vscode)")
            }

            if !workspace.browserUrls.isEmpty {
                print("  Browser URLs:")
                workspace.browserUrls.forEach { print("    - \($0)") }
            }

            if !workspace.terminalDirectories.isEmpty {
                print("  Terminal Directories:")
                workspace.terminalDirectories.forEach { print("    - \($0)") }
            }

            if !workspace.applications.isEmpty {
                print("  Applications:")
                workspace.applications.forEach { print("    - \($0.name)") }
            }
            
            if let mcpServers = workspace.mcpServers, !mcpServers.isEmpty {
                print("  MCP Servers:")
                mcpServers.keys.forEach { print("    - \($0)") }
            }
        }
    }

    struct Switch: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Switch to a workspace"
        )

        @Argument(help: "Name of the workspace to switch to")
        var name: String

        @Flag(name: .shortAndLong, help: "Save current state before switching")
        var save: Bool = false

        @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
        var force: Bool = false

        @Flag(name: .shortAndLong, help: "Show progress during switching")
        var verbose: Bool = false

        func run() throws {
            // Check if workspace exists
            let manager = WorkspaceManager.shared
            guard manager.getWorkspace(name: name) != nil else {
                print("Error: Workspace '\(name)' not found.")
                print("Available workspaces:")
                for workspace in manager.getWorkspaces() {
                    print(" - \(workspace)")
                }
                throw ExitCode.failure
            }

            // Confirm switch if not forced
            if !force {
                print("Are you sure you want to switch to workspace '\(name)'? (y/N)")
                let response = readLine()?.lowercased() ?? ""
                if response != "y" && response != "yes" {
                    print("Switch canceled.")
                    throw ExitCode.success
                }
            }

            // Show progress if verbose
            if verbose {
                print("Starting workspace switch to '\(name)'...")
            }

            // Perform the switch
            let success = manager.switchToWorkspace(name: name, saveCurrentState: save)

            if success {
                if verbose {
                    print("Successfully switched to workspace '\(name)'")
                }
            } else {
                print("Failed to switch to workspace '\(name)'")
                throw ExitCode.failure
            }
        }
    }

    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "ls",
            abstract: "List all available workspaces"
        )

        func run() throws {
            let manager = WorkspaceManager.shared
            let workspaces = manager.getWorkspaces()

            if workspaces.isEmpty {
                print("No workspaces found.")
                return
            }

            print("Available workspaces:")
            for workspace in workspaces {
                print(" - \(workspace)")
            }
        }
    }

    struct Config: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Configure a workspace"
        )

        @Argument(help: "Name of the workspace to configure")
        var name: String

        @Option(name: .long, help: "VSCode workspace file path")
        var vscodeWorkspace: String?

        @Option(name: .long, help: "Comma-separated list of URLs to open")
        var browserUrls: String?

        @Option(name: .long, help: "Comma-separated list of terminal working directories")
        var terminalDirs: String?
        
        @Option(name: .long, help: "JSON file containing MCP server configurations")
        var mcpConfig: String?

        func run() throws {
            print("Configuring workspace: \(name)")
            
            let manager = WorkspaceManager.shared
            guard var workspace = manager.getWorkspace(name: name) else {
                print("Workspace '\(name)' not found.")
                throw ExitCode.failure
            }
            
            var updated = false
            
            // Update VSCode workspace if provided
            if let vscodeWorkspace = vscodeWorkspace {
                workspace.vscodeWorkspace = vscodeWorkspace
                updated = true
            }
            
            // Update browser URLs if provided
            if let browserUrls = browserUrls {
                let urls = browserUrls.split(separator: ",").map(String.init)
                workspace.browserUrls = urls
                updated = true
            }
            
            // Update terminal directories if provided
            if let terminalDirs = terminalDirs {
                let dirs = terminalDirs.split(separator: ",").map(String.init)
                workspace.terminalDirectories = dirs
                updated = true
            }
            
            // Update MCP server configurations if provided
            if let mcpConfigPath = mcpConfig {
                if let mcpServers = loadMCPConfigFromFile(mcpConfigPath) {
                    workspace.mcpServers = mcpServers
                    updated = true
                }
            }
            
            if updated {
                if manager.saveWorkspace(workspace) {
                    print("Successfully updated workspace '\(name)'")
                } else {
                    print("Failed to save workspace configuration.")
                    throw ExitCode.failure
                }
            } else {
                print("No changes to save.")
            }
        }
    }

    struct Snapshot: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Save current window state to workspace"
        )

        @Argument(help: "Name of the workspace to snapshot")
        var name: String

        func run() throws {
            print("Saving snapshot for workspace: \(name)")
            // TODO: Capture current window state
        }
    }
}

// MARK: - Helper Functions

/// Load MCP server configurations from a JSON file
/// - Parameter path: Path to the JSON file
/// - Returns: Dictionary of MCP server configurations, or nil if loading failed
func loadMCPConfigFromFile(_ path: String) -> [String: Workspace.MCPServerConfig]? {
    let expandedPath: String
    if path.hasPrefix("~") {
        let pathWithoutTilde = String(path.dropFirst())
        expandedPath = FileManager.default.homeDirectoryForCurrentUser.path + pathWithoutTilde
    } else {
        expandedPath = path
    }
    
    guard FileManager.default.fileExists(atPath: expandedPath) else {
        print("MCP configuration file not found: \(expandedPath)")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: expandedPath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
        
        var mcpServers: [String: Workspace.MCPServerConfig] = [:]
        
        if let json = json {
            for (serverName, serverConfig) in json {
                if let command = serverConfig["command"] as? String,
                   let args = serverConfig["args"] as? [String] {
                    var config = Workspace.MCPServerConfig(command: command, args: args)
                    
                    if let env = serverConfig["env"] as? [String: String] {
                        config.env = env
                    }
                    
                    if let disabled = serverConfig["disabled"] as? Bool {
                        config.disabled = disabled
                    }
                    
                    if let alwaysAllow = serverConfig["alwaysAllow"] as? [String] {
                        config.alwaysAllow = alwaysAllow
                    }
                    
                    mcpServers[serverName] = config
                }
            }
        }
        
        return mcpServers
    } catch {
        print("Error loading MCP configuration: \(error.localizedDescription)")
        return nil
    }
}

// MARK: - Main Entry Point
Smux.main()