import Console
import Foundation
import libc
import Core

public final class Fetch: Command {
    public let id = "fetch"

    public let signature: [Argument]

    public let help: [String] = [
        "Fetches the application's dependencies."
    ]

    public let console: ConsoleProtocol
    
    let clean: Clean

    public init(_ console: ConsoleProtocol) {
        self.console = console
        
        self.clean = Clean(console)
        
        self.signature = [
            Option(name: "clean", help: ["Cleans the project before fetching."])
        ] + clean.signature
    }

    public func run() throws {
        if try flag("clean") {
            try clean.run()
        }
        
        try fetch()
    }
    
    internal func fetch() throws {
        if !console.projectInfo.buildFolderExists() {
            console.warning("No .build folder, fetch may take a while...")
        }
        
        let isVerbose = try flag("verbose")
        let depBar = console.loadingBar(title: "Fetching Dependencies", animated: !isVerbose)
        depBar.start()

        try console.execute(
            verbose: isVerbose,
            program: "swift",
            arguments: ["package", "--enable-prefetching", "fetch"]
        )
        depBar.finish()
    }
}

// MARK: Prototypes

extension LoadingBar {
    func track(_ operation: @escaping () throws -> ()) rethrows {
        start()
        defer { finish() }
        try operation()
    }
}
extension ConsoleProtocol {
    func ls(_ arguments: [String]) throws -> String {
        return try backgroundExecute(program: "ls", arguments: arguments)
    }
}

extension ConsoleProtocol {
    public func execute(verbose: Bool, program: String, arguments: [String]) throws  {
        if verbose {
            try foregroundExecute(program: program, arguments: arguments)
        } else {
            _ = try backgroundExecute(program: program, arguments: arguments)
        }
    }
}
