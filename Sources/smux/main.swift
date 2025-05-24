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

        func run() throws {
            print("Creating workspace: \(name)")
            // TODO: Implement workspace creation
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