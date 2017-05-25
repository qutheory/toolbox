import libc
import Console
import Foundation
import VaporToolbox
// import Cloud

// The toolbox bootstrap script replaces "master" during installation. Do not modify!

let version = "master"
let terminal = Terminal()

final class Foo: Command {
    let id = "create"
    var signature: [Argument]
    var help: [String] = ["Creates stuff"]
    let console: ConsoleProtocol
    
    init(_ console: ConsoleProtocol) {
        self.console = console
        
        self.signature = [
            Value(name: "type"),
            Option(name: "admin")
        ]
    }
    
    func run() throws {
        let type = try value("type")
        console.info(type)
        if try flag("admin") {
            console.warning("As admin")
        }
    }
}

// let cloud = try Cloud.group(terminal)

final class ToolboxCommand: Command {
    let id: String
    var signature: [Argument] = [
        Option(name: "version", help: ["Prints the Toolbox's version"])
    ]
    
    let help = [
        "Join our Slack if you have questions, need help,",
        "or want to contribute: http://vapor.team"
    ]
    
    let subcommands: [Command] = [
        Foo(terminal),
        New(terminal),
        Build(terminal),
        Run(terminal),
        Fetch(terminal),
        // Update(console: terminal),
        Clean(terminal),
        Test(terminal),
        // Xcode(console: terminal),
        Version(terminal, version: version),
        // cloud,
        /*Group(id: "heroku", help: [
            "Commands to help deploy to Heroku."
        ], terminal, [
            HerokuInit(terminal),
            HerokuPush(terminal),
        ]),
        Group(id: "provider", help: [
            "Commands to help manage providers."
        ], terminal, [
            // ProviderAdd(console: terminal)
        ]),*/
    ]
    
    let console: ConsoleProtocol
    
    init(id: String, _ console: ConsoleProtocol) {
        self.id = id
        self.console = console
    }
    
    func run() throws {
        if try flag("version") {
            console.print("Version: ", newLine: false)
            console.success(version)
        }
        // nothing
    }
}

var iterator = CommandLine.arguments.makeIterator()
guard let executable = iterator.next() else {
    throw "no exectuable"
}

let toolbox = ToolboxCommand(id: executable, terminal)

do {
    try terminal.run(toolbox, arguments: Array(iterator))
} catch ToolboxError.general(let message) {
    terminal.error("Error: ", newLine: false)
    terminal.print(message)
    exit(1)
} catch ConsoleError.insufficientArguments {
    terminal.error("Error: ", newLine: false)
    terminal.print("Insufficient arguments.")
} catch ConsoleError.help {
    exit(0)
} catch ConsoleError.cancelled {
    print("Cancelled")
    exit(2)
} catch ConsoleError.noCommand {
    terminal.error("Error: ", newLine: false)
    terminal.print("No command supplied.")
} catch ConsoleError.commandNotFound(let id) {
    terminal.error("Error: ", newLine: false)
    terminal.print("Command \"\(id)\" not found.")
//} catch let error as AbortError {
//    terminal.error("API Error (\(error.status)): ", newLine: false)
//    terminal.print(error.reason)
} catch {
    terminal.error("Error: ", newLine: false)
    terminal.print("\(error)")
    exit(1)
}
