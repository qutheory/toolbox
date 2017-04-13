import Console
import JSON
import Core

public final class APIDiff: Command {
    public let id = "api-diff"
    
    public let signature: [Argument] = [
        Value(name: "old-tag", help: ["Old API tag"]),
        Value(name: "new-tag", help: ["New API tag"]),
        Value(name: "scheme", help: ["Name of the scheme to analyze"])
    ]
    
    public let help: [String] = [
        "Produces API diffs"
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        do {
            _ = try console.backgroundExecute(program: "sourcekitten", arguments: ["help"])
        } catch {
            throw ToolboxError.general("SourceKitten required (brew install sourcekitten)")
        }
        
        let oldTag = try value("old-tag", from: arguments)
        let newTag = try value("new-tag", from: arguments)
        let scheme = try value("scheme", from: arguments)
        
        let oldPath = ".old_api.json"
        let newPath = ".new_api.json"
        
        try prepareTag(oldTag, scheme: scheme)
        try parseTag(oldTag, to: oldPath, scheme: scheme)

        try prepareTag(newTag, scheme: scheme)
        try parseTag(newTag, to: newPath, scheme: scheme)
        
        let oldBytes = try DataFile().load(path: oldPath)
        let newBytes = try DataFile().load(path: newPath)
        
        let old = try JSON(bytes: oldBytes)
        let new = try JSON(bytes: newBytes)
    
        let oldSymbols = try parseSymbols(from: old)
        let newSymbols = try parseSymbols(from: new)
        
        var stableKeys: [SourceKey] = []
        var missingKeys: [SourceKey] = []
        
        for (oldSymbol, oldKey) in oldSymbols {
            if let _ = newSymbols[oldSymbol] {
                stableKeys.append(oldKey)
            } else {
                missingKeys.append(oldKey)
            }
        }
        
        for key in stableKeys {
            console.success(key.name ?? "n/a", newLine: false)
            console.print(" ", newLine: false)
            console.print(key.usr ?? "n/a")
        }
        for key in missingKeys {
            console.warning(key.name ?? "n/a", newLine: false)
            console.print(" ", newLine: false)
            console.print(key.usr ?? "n/a")
        }
    }
    
    func parseTag(_ tag: String, to path: String, scheme: String) throws {
        console.info("Parsing \(tag) API...")
        try console.foregroundExecute(program: "/bin/sh", arguments: ["-c", "sourcekitten doc -- -workspace \(scheme).xcworkspace -scheme \(scheme) > \(path)"])
        console.success("Parsed \(tag) API to \(path)!")
    }
    
    func prepareTag(_ tag: String, scheme: String) throws {
        console.info("Preparing tag \(tag)...")
        console.info("Cleaning...")
        try console.foregroundExecute(program: "/bin/sh", arguments: ["-c", "rm .build Package.pins *.xcodeproj *.xcworkspace"])
        console.info("Checking out tag...")
        try console.foregroundExecute(program: "git", arguments: ["checkout", tag])
        console.info("Generating Xcode project...")
        try console.foregroundExecute(program: "/bin/sh", arguments: ["-c", "swift package --enable-prefetching generate-xcodeproj"])
        console.info("Opening Xcode project...")
        try console.foregroundExecute(program: "/bin/sh", arguments: ["-c", "open *.xcodeproj"])
        console.info("Go to File > Save Workspace as \(scheme).xcworkspace")
        _ = console.ask("Have you saved the workspace?")
    }
    
    func parseSymbols(from json: JSON) throws -> [String: SourceKey] {
        let files = try parseFiles(from: json)
        
        var symbols: [String: SourceKey] = [:]
        files.forEach { file in
            for key in file.keys {
                key.collect(&symbols)
            }
        }
        
        return symbols
    }
    
    func parseFiles(from json: JSON) throws -> [SourceFile] {
        guard let docs = json.array else {
            throw ToolboxError.general("API JSON was not an array")
        }
        
        var files: [SourceFile] = []
        
        try docs.forEach { doc in
            guard let rawFiles = doc.object else {
                return
            }
            for (key, file) in rawFiles {
                let keys = try [SourceKey](json: file.get(DotKey("key.substructure")))
                let file = SourceFile(name: key, keys: keys)
                files.append(file)
            }
        }
        
        return files
    }
}
