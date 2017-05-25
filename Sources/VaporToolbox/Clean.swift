import Console

public final class Clean: Command {
    public let id = "clean"

    public let signature: [Argument] = [
        Option(name: "xcode", help: ["Removes any Xcode projects while cleaning."]),
        Option(name: "pins", help: ["Removes the Package.pins file as well."])
    ]

    public let help: [String] = [
        "Cleans temporary files--usually fixes",
        "a plethora of bizarre build errors."
    ]

    public let console: ConsoleProtocol

    public init(_ console: ConsoleProtocol) {
        self.console = console
    }

    public func run() throws {
        try clean()
    }
    
    internal func clean() throws {
        console.warning("Cleaning will increase your build time ... ")
        console.warning("We recommend trying 'vapor update' first.")
        guard console.confirm("Would you like to clean anyways?") else {
            return
        }
        
        let cleanBar = console.loadingBar(title: "Cleaning", animated: true) // fixme
        cleanBar.start()
        
        _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", ".build"])
        
        if try flag("xcode") {
            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "*.xcodeproj"])
        }
        
        if try flag("pins") {
            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "Package.pins"])
        }
        
        cleanBar.finish()
    }
}
