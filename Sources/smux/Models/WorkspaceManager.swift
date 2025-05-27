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
    
    /// Create a new workspace with the given configuration
    /// - Parameters:
    ///   - name: Name of the workspace
    ///   - vscodeWorkspace: Optional path to VSCode workspace file
    ///   - browserUrls: Optional list of browser URLs to open
    ///   - terminalDirectories: Optional list of terminal directories to open
    ///   - applications: Optional list of applications to open
    /// - Returns: The created workspace if successful, nil otherwise
    func createWorkspace(
        name: String,
        vscodeWorkspace: String? = nil,
        browserUrls: [String] = [],
        terminalDirectories: [String] = [],
        applications: [Workspace.ApplicationConfig] = [],
        mcpServers: [String: Workspace.MCPServerConfig]? = nil
    ) -> Workspace? {
        // Check if workspace already exists
        if Workspace.exists(name: name) {
            print("Workspace '\(name)' already exists")
            return nil
        }

        // Create new workspace
        let workspace = Workspace(
            name: name,
            applications: applications,
            browserUrls: browserUrls,
            terminalDirectories: terminalDirectories,
            vscodeWorkspace: vscodeWorkspace,
            mcpServers: mcpServers
        )
        
        // Save workspace
        if saveWorkspace(workspace) {
            return workspace
        } else {
            return nil
        }
    }
    
    /// Create a workspace from a template
    /// - Parameters:
    ///   - name: Name of the new workspace
    ///   - templateName: Name of the template workspace to use
    /// - Returns: The created workspace if successful, nil otherwise
    func createWorkspaceFromTemplate(name: String, templateName: String) -> Workspace? {
        // Check if workspace already exists
        if Workspace.exists(name: name) {
            print("Workspace '\(name)' already exists")
            return nil
        }

        // Check if template exists
        guard let template = getWorkspace(name: templateName) else {
            print("Template workspace '\(templateName)' not found")
            return nil
        }
        
        // Create new workspace from template
        var workspace = template
        workspace.name = name

        // Save workspace
        if saveWorkspace(workspace) {
            return workspace
        } else {
            return nil
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
        
        // Configure MCP servers if specified
        var appsToRestart: [String] = []
        if let mcpServers = workspace.mcpServers, !mcpServers.isEmpty {
            if configureMCPServers(mcpServers) {
                appsToRestart.append(contentsOf: ["Claude", "Windsurf"])
            }
        }
        
        // Prompt to restart applications if needed
        if !appsToRestart.isEmpty {
            promptToRestartApplications(appsToRestart)
        }
        
        return true
    }
    
    /// Open an application based on configuration
    /// - Parameter app: Application configuration
    private func openApplication(_ app: Workspace.ApplicationConfig) {
        print("Opening application: \(app.name)")
        
        // Special handling for Safari with profile
        if app.name.lowercased() == "safari" && app.safariProfile != nil {
            openSafariWithProfile(app.safariProfile!)
            return
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/open"
        
        if app.bundleIdentifier.isEmpty {
            // Open by application name
            process.arguments = ["-a", app.name]
        } else {
            // Open by bundle identifier
            process.arguments = ["-b", app.bundleIdentifier]
        }
        
        do {
            try process.run()
        } catch {
            print("Error opening application \(app.name): \(error.localizedDescription)")
        }
    }
    
    /// Open Safari with a specific profile
    /// - Parameter profileName: Name of the Safari profile to use
    private func openSafariWithProfile(_ profileName: String) {
        print("Opening Safari with profile: \(profileName)")
        
        // First, try the AppleScript approach to open Safari with a specific profile
        let script = """
        tell application "Safari"
            activate
            delay 1 -- Wait for Safari to activate
            tell application "System Events"
                tell process "Safari"
                    try
                        -- Try the direct menu approach first (2 or fewer profiles)
                        click menu item "New \(profileName) Window" of menu 1 of menu bar item "File" of menu bar 1
                    on error
                        -- Try the submenu approach (more than 2 profiles)
                        try
                            -- Open the "New Window" submenu
                            click menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1
                            delay 0.5 -- Allow time for the submenu to open
                            -- Click the specific profile window item
                            click menu item "New \(profileName) Window" of menu 1 of menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1
                        on error
                            -- If both approaches fail, just open a regular Safari window
                            click menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1
                            display notification "Could not find Safari profile: \(profileName)" with title "SMUX"
                        end try
                    end try
                end tell
            end tell
        end tell
        """
        
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Check if AppleScript execution was successful
            if process.terminationStatus != 0 {
                // If it failed due to permissions, inform the user and fall back to regular Safari
                if process.terminationReason == .uncaughtSignal {
                    print("\nPermission error: SMUX needs Accessibility permissions to control Safari.")
                    print("Please go to System Preferences > Security & Privacy > Privacy > Accessibility")
                    print("and add Terminal or your IDE to the list of allowed apps.\n")
                }
                
                // Fall back to just opening Safari without profile selection
                fallbackToRegularSafari()
            } else {
                print("Safari has been opened with profile: \(profileName)")
            }
        } catch {
            print("Error opening Safari with profile \(profileName): \(error.localizedDescription)")
            fallbackToRegularSafari()
        }
    }
    
    /// Fallback method to open Safari without profile selection
    private func fallbackToRegularSafari() {
        let fallbackProcess = Process()
        fallbackProcess.launchPath = "/usr/bin/open"
        fallbackProcess.arguments = ["-a", "Safari"]
        
        do {
            try fallbackProcess.run()
            print("Opened Safari without profile selection")
        } catch {
            print("Error opening Safari: \(error.localizedDescription)")
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
            // Expand tilde to home directory if present
            let expandedPath: String
            if directory.hasPrefix("~") {
                let pathWithoutTilde = String(directory.dropFirst())
                expandedPath = FileManager.default.homeDirectoryForCurrentUser.path + pathWithoutTilde
            } else {
                expandedPath = directory
            }
            
            let script = "tell application \"Terminal\" to do script \"cd \(expandedPath)\""
            
            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", script]
            
            do {
                try process.run()
            } catch {
                print("Error opening terminal at \(expandedPath): \(error.localizedDescription)")
            }
        }
    }
    
    /// Open VS Code workspace
    /// - Parameter workspacePath: Path to the VS Code workspace file
    private func openVSCodeWorkspace(_ workspacePath: String) {
        print("Opening VS Code workspace: \(workspacePath)")
        
        // Expand tilde to home directory if present
        let expandedPath: String
        if workspacePath.hasPrefix("~") {
            let pathWithoutTilde = String(workspacePath.dropFirst())
            expandedPath = FileManager.default.homeDirectoryForCurrentUser.path + pathWithoutTilde
        } else {
            expandedPath = workspacePath
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-a", "Visual Studio Code", expandedPath]
        
        do {
            try process.run()
        } catch {
            print("Error opening VS Code workspace \(expandedPath): \(error.localizedDescription)")
        }
    }
    
    // MARK: - MCP Server Configuration
    
    /// Configure MCP servers for various applications
    /// - Parameter mcpServers: Dictionary of MCP server configurations
    /// - Returns: Boolean indicating if any configurations were updated
    private func configureMCPServers(_ mcpServers: [String: Workspace.MCPServerConfig]) -> Bool {
        print("Configuring MCP servers...")
        
        var configUpdated = false
        
        // Configure Claude Desktop
        if configureClaudeMCPServers(mcpServers) {
            configUpdated = true
        }
        
        // Configure Windsurf (placeholder for future implementation)
        // if configureWindsurfMCPServers(mcpServers) {
        //     configUpdated = true
        // }
        
        return configUpdated
    }
    
    /// Configure MCP servers for Claude Desktop
    /// - Parameter mcpServers: Dictionary of MCP server configurations
    /// - Returns: Boolean indicating if configuration was updated
    private func configureClaudeMCPServers(_ mcpServers: [String: Workspace.MCPServerConfig]) -> Bool {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let claudeConfigDir = homeDirectory.appendingPathComponent("Library/Application Support/Claude")
        let configFile = claudeConfigDir.appendingPathComponent("claude_desktop_config.json")
        
        // Check if Claude config directory exists
        if !fileManager.fileExists(atPath: claudeConfigDir.path) {
            print("Claude configuration directory not found. Claude Desktop may not be installed.")
            return false
        }
        
        // Create backup of existing config
        let backupFile = claudeConfigDir.appendingPathComponent("claude_desktop_config.backup.json")
        do {
            if fileManager.fileExists(atPath: configFile.path) {
                let configData = try Data(contentsOf: configFile)
                try configData.write(to: backupFile)
                print("Created backup of Claude Desktop configuration")
            }
        } catch {
            print("Error creating backup of Claude Desktop configuration: \(error.localizedDescription)")
            return false
        }
        
        // Read existing config or create new one
        var config: [String: Any] = [:]
        if fileManager.fileExists(atPath: configFile.path) {
            do {
                let data = try Data(contentsOf: configFile)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    config = json
                }
            } catch {
                print("Error reading Claude Desktop configuration: \(error.localizedDescription)")
                return false
            }
        }
        
        // Update MCP servers configuration
        var mcpServersDict: [String: Any] = [:]
        for (name, serverConfig) in mcpServers {
            var serverDict: [String: Any] = [
                "command": serverConfig.command,
                "args": serverConfig.args
            ]
            
            if let env = serverConfig.env {
                serverDict["env"] = env
            }
            
            if let disabled = serverConfig.disabled {
                serverDict["disabled"] = disabled
            }
            
            if let alwaysAllow = serverConfig.alwaysAllow {
                serverDict["alwaysAllow"] = alwaysAllow
            }
            
            mcpServersDict[name] = serverDict
        }
        
        config["mcpServers"] = mcpServersDict
        
        // Write updated config
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
            try jsonData.write(to: configFile)
            print("Updated Claude Desktop MCP server configuration")
            return true
        } catch {
            print("Error writing Claude Desktop configuration: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Prompt user to restart applications after configuration changes
    /// - Parameter appNames: Array of application names to restart
    private func promptToRestartApplications(_ appNames: [String]) {
        print("\nMCP server configurations have been updated.")
        print("The following applications need to be restarted to apply the changes:")
        for appName in appNames {
            print("  - \(appName)")
        }
        
        print("\nWould you like to restart these applications now? (y/N)")
        let response = readLine()?.lowercased() ?? ""
        
        if response == "y" || response == "yes" {
            for appName in appNames {
                restartApplication(appName)
            }
        } else {
            print("Please restart the applications manually to apply the MCP server configurations.")
        }
    }
    
    /// Restart an application
    /// - Parameter appName: Name of the application to restart
    private func restartApplication(_ appName: String) {
        print("Restarting \(appName)...")
        
        // First quit the application
        let quitScript = "tell application \"\(appName)\" to quit"
        let quitProcess = Process()
        quitProcess.launchPath = "/usr/bin/osascript"
        quitProcess.arguments = ["-e", quitScript]
        
        do {
            try quitProcess.run()
            quitProcess.waitUntilExit()
            
            // Wait a moment before restarting
            Thread.sleep(forTimeInterval: 1.0)
            
            // Then launch the application again
            let launchScript = "tell application \"\(appName)\" to activate"
            let launchProcess = Process()
            launchProcess.launchPath = "/usr/bin/osascript"
            launchProcess.arguments = ["-e", launchScript]
            
            try launchProcess.run()
            print("\(appName) has been restarted")
        } catch {
            print("Error restarting \(appName): \(error.localizedDescription)")
        }
    }
}
