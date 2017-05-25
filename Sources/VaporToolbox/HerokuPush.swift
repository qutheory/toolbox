import Console

public final class HerokuPush: Command {
    public let id = "push"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Pushes the application to Heroku."
    ]

    public let console: ConsoleProtocol

    public init(_ console: ConsoleProtocol) {
        self.console = console
    }

    public func run() throws {
        do {
            _ = try console.backgroundExecute(program: "which", arguments: ["heroku"])
        } catch ConsoleError.backgroundExecute {
            console.info("Visit https://toolbelt.heroku.com")
            throw ToolboxError.general("Heroku Toolbelt must be installed.")
        }

        do {
            let status = try console.backgroundExecute(program: "git", arguments: ["status", "--porcelain"])
            if status.makeString().trim() != "" {
                console.info("All current changes must be committed before pushing to Heroku.")
                throw ToolboxError.general("Found uncommitted changes.")
            }
        } catch ConsoleError.backgroundExecute {
            throw ToolboxError.general("No .git repository found.")
        }

        let isVerbose = try flag("verbose")
        let herokuBar = console.loadingBar(title: "Pushing to Heroku", animated: !isVerbose)
        herokuBar.start()
        do {
            try console.execute(verbose: isVerbose, program: "git", arguments: ["push", "heroku", "master"])
            herokuBar.finish()
        } catch ConsoleError.execute(_) {
            herokuBar.fail()
            throw ToolboxError.general("Unable to push to Heroku.")
        } catch {
            // prevents foreground executions from logging 'Done' instead of 'Failed'
            herokuBar.fail()
            throw error
        }
    }

}
