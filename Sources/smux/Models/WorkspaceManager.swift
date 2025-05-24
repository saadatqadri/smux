// Sources/smux/Models/WorkspaceManager.swift
import Foundation

/// Manages workspace operations including creation, switching, and listing
class WorkspaceManager {
    /// Singleton instance
    static let shared = WorkspaceManager()
    
    private init() {}
    
    /// Get all available workspaces
    /// - Returns: Array of workspace names
    func getWorkspaces() -> [String] {
        return Workspace.listAll()
    }
    
    /// Get a workspace by name
    /// - Parameter name: Name of the workspace
    /// - Returns: Workspace if found, nil otherwise
    func getWorkspace(name: String) -> Workspace? {
        guard Workspace.exists(name: name) else {
            return nil
        }
        
        do {
            return try Workspace.load(name: name)
        } catch {
            print("Error loading workspace \(name): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Save a workspace configuration
    /// - Parameter workspace: The workspace to save
    /// - Returns: Boolean indicating success
    func saveWorkspace(_ workspace: Workspace) -> Bool {
        do {
            try Workspace.save(workspace)
            return true
        } catch {
            print("Error saving workspace \(workspace.name): \(error.localizedDescription)")
            return false
        }
    }
    
    /// Switch to a workspace
    /// - Parameters:
    ///   - name: Name of the workspace to switch to
    ///   - saveCurrentState: Whether to save the current state before switching
    /// - Returns: Boolean indicating success
    func switchToWorkspace(name: String, saveCurrentState: Bool = false) -> Bool {
        // Validate workspace exists
        guard let workspace = getWorkspace(name: name) else {
            print("Workspace '\(name)' not found")
            return false
        }
        
        // Save current state if requested
        if saveCurrentState {
            // TODO: Implement snapshot functionality
            print("Saving current state...")
        }
        
        print("Switching to workspace: \(name)")
        
        // Close current applications if needed
        // TODO: Implement application closing
        
        // Open configured applications
        for app in workspace.applications {
            openApplication(app)
        }
        
        // Open browser URLs if configured
        if !workspace.browserUrls.isEmpty {
            openBrowserUrls(workspace.browserUrls)
        }
        
        // Open terminal directories if configured
        if !workspace.terminalDirectories.isEmpty {
            openTerminalDirectories(workspace.terminalDirectories)
        }
        
        // Open VS Code workspace if configured
        if let vscodeWorkspace = workspace.vscodeWorkspace {
            openVSCodeWorkspace(vscodeWorkspace)
        }
        
        return true
    }
    
    /// Open an application based on configuration
    /// - Parameter app: Application configuration
    private func openApplication(_ app: Workspace.ApplicationConfig) {
        print("Opening application: \(app.name)")
        
        // Create AppleScript to launch the application
        var script = "tell application \"\(app.name)\" to activate"
        
        // Add window positioning if available
        if let windowPositions = app.windowPositions, !windowPositions.isEmpty {
            // TODO: Implement window positioning with AppleScript
        }
        
        // Execute the script
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        
        do {
            try process.run()
        } catch {
            print("Error launching \(app.name): \(error.localizedDescription)")
        }
    }
    
    /// Open browser URLs
    /// - Parameter urls: Array of URLs to open
    private func openBrowserUrls(_ urls: [String]) {
        print("Opening browser URLs: \(urls)")
        
        for url in urls {
            let process = Process()
            process.launchPath = "/usr/bin/open"
            process.arguments = [url]
            
            do {
                try process.run()
            } catch {
                print("Error opening URL \(url): \(error.localizedDescription)")
            }
        }
    }
    
    /// Open terminal directories
    /// - Parameter directories: Array of directories to open in Terminal
    private func openTerminalDirectories(_ directories: [String]) {
        print("Opening terminal directories: \(directories)")
        
        for directory in directories {
            let script = "tell application \"Terminal\" to do script \"cd \(directory)\""
            
            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", script]
            
            do {
                try process.run()
            } catch {
                print("Error opening terminal at \(directory): \(error.localizedDescription)")
            }
        }
    }
    
    /// Open VS Code workspace
    /// - Parameter workspacePath: Path to the VS Code workspace file
    private func openVSCodeWorkspace(_ workspacePath: String) {
        print("Opening VS Code workspace: \(workspacePath)")
        
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-a", "Visual Studio Code", workspacePath]
        
        do {
            try process.run()
        } catch {
            print("Error opening VS Code workspace \(workspacePath): \(error.localizedDescription)")
        }
    }
}
