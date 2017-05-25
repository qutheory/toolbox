import Console
import Foundation

extension Array where Element == String {
    var isVerbose: Bool {
        return flag("verbose")
    }
}

public final class Build: Command {
    public let id = "build"

    public let signature: [Argument]

    public let help: [String] = [
        "Compiles the application."
    ]

    public let console: ConsoleProtocol
    
    let clean: Clean
    let fetch: Fetch
    let runCommand: Run

    public init(_ console: ConsoleProtocol) {
        self.console = console
        
        self.clean = Clean(console)
        self.fetch = Fetch(console)
        self.runCommand = Run(console)
        
        self.signature = [
            Option(name: "run", help: ["Runs the project after building."]),
            Option(name: "clean", help: ["Cleans the project before building."]),
            Option(name: "fetch", help: ["Fetches the project before building, default true."]),
            Option(name: "debug", help: ["Builds with debug symbols."]),
            Option(name: "verbose", help: ["Print build logs instead of loading bar."]),
            Option(name: "release", help: ["Builds release configuration"])
        ] + clean.signature + fetch.signature + runCommand.signature
    }

    public func run() throws {
        if try flag("clean") {
            try clean.run()
        }
        
        if try flag("fetch") {
            try fetch.run()
        }
        
        try build()
        
        if try flag("run") {
            try runCommand.run()
        }
    }

    private func build() throws {
        let buildFlags = try loadBuildFlags()

        let isVerbose = try flag("verbose")
        let buildBar = console.loadingBar(title: "Building Project", animated: !isVerbose)
        buildBar.start()

        let command =  ["build", "--enable-prefetching"] + buildFlags
        do {
            try console.execute(verbose: isVerbose, program: "swift", arguments: command)
            buildBar.finish()
        } catch ConsoleError.backgroundExecute(let code, let error, let output) {
            buildBar.fail()
            try backgroundError(command: command, code: code, error: error, output: output)
        } catch {
            // prevents foreground executions from logging 'Done' instead of 'Failed'
            buildBar.fail()
            throw error
        }
    }

    private func loadBuildFlags() throws -> [String] {
        var buildFlags = try Config.buildFlags()

        if try flag("debug") {
            // Appending these flags aids in debugging
            // symbols on linux
            buildFlags += ["-Xswiftc", "-g"]
        }

        if try flag("release") {
            buildFlags += ["--configuration", "release"]
        }

        // Setup passthrough
        //buildFlags += arguments
         //   .removeFlags(["clean", "run", "debug", "verbose", "fetch", "release"])
           // .options
            //.map { name, value in "--\(name)=\(value)" }

        return buildFlags
    }

    private func backgroundError(command: [String], code: Int, error: String, output: String) throws {
        console.print()
        console.info("Command:")
        console.print(command.joined(separator: " "))
        console.print()

        console.info("Error (\(code)):")
        console.print(error)
        console.print()

        console.info("Output:")
        console.print(output)
        console.print()

        console.info("Toolchain:")
        let toolchain = try console.backgroundExecute(program: "which", arguments: ["swift"]).makeString().trim()
        console.print(toolchain)
        console.print()

        console.info("Help:")
        console.print("Join our Slack where hundreds of contributors")
        console.print("are waiting to help: http://vapor.team")
        console.print()

        throw ToolboxError.general("Build failed.")
    }
}
