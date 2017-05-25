import Console
import JSON
import Foundation

public final class Version: Command {
    public let id = "version"

    public let help: [String] = [
        "Displays Vapor CLI version"
    ]

    public let console: ConsoleProtocol
    public let version: String

    public init(_ console: ConsoleProtocol, version: String) {
        self.console = console
        self.version = version
    }

    public func run() throws {
        console.print("Vapor Toolbox: ", newLine: false)
        console.success("\(version)")

        guard projectInfo.isSwiftProject() else { return }
        guard projectInfo.isVaporProject() else {
            console.warning("No Vapor dependency detected, unable to log Framework Version")
            return
        }

        // If we have a vapor project, but checkouts
        // don't exist yet, we'll need to build
        let exists = try vaporCheckoutExists()
        if !exists {
            console.info("In order to find the Vapor Framework version of your project, it needs to be built at least once")
        }

        let vapor = try projectInfo.vaporVersion()

        console.print("Vapor Framework: ", newLine: false)
        console.success("\(vapor)")
    }

    private func vaporCheckoutExists() throws -> Bool {
        return try projectInfo.vaporCheckout() != nil
    }
}
