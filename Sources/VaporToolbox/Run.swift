import Console
import Foundation
import JSON

public final class Run: Command {
    public let id = "run"

    public let help: [String] = [
        "Runs the compiled application."
    ]

    public let signature: [Argument] = [
        Option(name: "exec", help: ["The executable name."])
    ]

    public let console: ConsoleProtocol

    public init(_ console: ConsoleProtocol) {
        self.console = console
    }

    public func run() throws {
        let configuration = try flag("release") ? "release" : "debug"
        let packageName = try projectInfo.packageName()
        console.print("Running ", newLine: false)
        console.info(packageName, newLine: false)
        console.print(" in ", newLine: false)
        console.warning(configuration, newLine: false)
        console.print(" mode...")
        
        do {
            let executable = try executablePath()

            let configuredRunFlags = try Config.runFlags()
            let passThrough = [] + configuredRunFlags


            try console.foregroundExecute(
                program: executable,
                arguments: passThrough
            )
        } catch ConsoleError.execute(_) {
            throw ToolboxError.general("Run failed.")
        }
    }

    private func buildFolder() throws -> String {
        let configuration = try flag("release") ? "release" : "debug"
        let folder = ".build/\(configuration)"

        do {
            _ = try console.backgroundExecute(program: "ls", arguments: [folder])
        } catch ConsoleError.backgroundExecute(_) {
            throw ToolboxError.general("No builds found for \(configuration) configuration.")
        }

        return folder
    }

    private func executablePath() throws -> String {
        let folder = try buildFolder()
        let exec = try option("exec") ?? getExecutableToRun()
        let executablePath = "\(folder)/\(exec)"
        try verify(executablePath: executablePath)
        return executablePath
    }

    private func verify(executablePath: String) throws {
        let pathExists = try? console.backgroundExecute(program: "ls", arguments: [executablePath])
        guard pathExists?.makeString().trim() == executablePath else {
            console.warning("Could not find executable at \(executablePath).")
            console.warning("Make sure 'vapor build' has been called.")
            throw ToolboxError.general("No executable found.")
        }
    }

    private func getExecutableToRun() throws -> String {
        let executables = try projectInfo.availableExecutables()
        guard !executables.isEmpty else {
            throw ToolboxError.general("No executables found")
        }

        // If there's only 1 executable, we'll use that
        if executables.count == 1 {
            return executables[0]
        }

        let title = "Which executable would you like to run?"
        guard let executable = console.askList(withTitle: title, from: executables) else {
            console.print("Please enter a valid number associated with your executable")
            console.print("Use --exec=desiredExecutable to skip this step")
            throw ToolboxError.general("No executable selected")
        }
        console.info("Thanks! Skip this question in the future by using '--exec=\(executable)'")
        return executable
    }
}
