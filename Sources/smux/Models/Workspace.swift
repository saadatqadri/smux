// Sources/smux/Models/Workspace.swift
import Foundation

struct Workspace: Codable, Identifiable {
    var id: String { name }
    let name: String
    var applications: [ApplicationConfig]
    var browserUrls: [String]
    var terminalDirectories: [String]
    var vscodeWorkspace: String?
    
    struct ApplicationConfig: Codable {
        let name: String
        let bundleIdentifier: String
        let windowPositions: [WindowPosition]?
        
        struct WindowPosition: Codable {
            let x: Int
            let y: Int
            let width: Int
            let height: Int
        }
    }
}

// Extension for persistence
extension Workspace {
    static let storageDirectory: URL = {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let smuxDirectory = homeDirectory.appendingPathComponent(".smux")
        
        if !fileManager.fileExists(atPath: smuxDirectory.path) {
            try? fileManager.createDirectory(at: smuxDirectory, withIntermediateDirectories: true)
        }
        
        return smuxDirectory
    }()
    
    static func save(_ workspace: Workspace) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(workspace)
        let fileURL = storageDirectory.appendingPathComponent("\(workspace.name).json")
        try data.write(to: fileURL)
    }
    
    static func load(name: String) throws -> Workspace {
        let fileURL = storageDirectory.appendingPathComponent("\(name).json")
        let data = try Data(contentsOf: fileURL)
        
        let decoder = JSONDecoder()
        return try decoder.decode(Workspace.self, from: data)
    }
    
    static func listAll() -> [String] {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { $0.deletingPathExtension().lastPathComponent }
    }
    
    static func exists(name: String) -> Bool {
        let fileURL = storageDirectory.appendingPathComponent("\(name).json")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
