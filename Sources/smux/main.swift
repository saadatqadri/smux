// Sources/smux/main.swift
import ArgumentParser
import Foundation

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
            // TODO: Communicate with daemon
        }
    }
    
    struct Switch: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Switch to a workspace"
        )
        
        @Argument(help: "Name of the workspace to switch to")
        var name: String
        
        func run() throws {
            
            print("Switching to workspace: \(name)")
            // TODO: Communicate with daemon
        }
    }
    
    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(
            // Mock implementation for listing workspaces
            commandName: "ls",
            abstract: "List all available workspaces"
        )
        
        func run() throws {
            // Mock implementation for listing workspaces
            let mockWorkspaces = ["Personal", "Work", "SideProject"]
            print("Available workspaces:")
            // TODO: Fetch from daemon
            for workspace in mockWorkspaces {
                print(" -\(workspace)")
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

Smux.main()