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

            guard let workspace = manager.createWorkspace(
                name: name,
                vscodeWorkspace: vscodeWorkspace,
                browserUrls: urls,
                terminalDirectories: dirs
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

            // Create the workspace
            guard let workspace = manager.createWorkspace(
                name: name,
                vscodeWorkspace: vscode,
                browserUrls: urls,
                terminalDirectories: dirs,
                applications: applications
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

        func run() throws {
            print("Configuring workspace: \(name)")
            // TODO: Save configuration
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

// MARK: - Main Entry Point
Smux.main()