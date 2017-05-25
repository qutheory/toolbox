extension ConsoleProtocol {
    /// Dynamically chooses an environment based on
    /// input arguments and lists from the Cloud API.
    func environment(
        on app: ModelOrIdentifier<Application>,
        for arguments: [String],
        using cloudFactory: CloudAPIFactory
    ) throws -> Environment {
        let env: Environment
        
        pushEphemeral()
        
        if let envName = arguments.option("env")?.string {
            env = try cloudFactory
                .makeAuthedClient(with: self)
                .environment(withId: Identifier(envName), for: app)
        } else {
            let envs: [Environment] = try loadingBar(title: "Loading environments", ephemeral: true) {
                do {
                    return try cloudFactory
                        .makeAuthedClient(with: self)
                        .environments(for: app)
                } catch let error as AbortError where error.status == .notFound {
                    return []
                }
            }
            
            if envs.count == 0 {
                warning("No environments found.")
                detail("Create environment", "vapor cloud create env")
                if confirm("Would you like to create an environment now?") {
                    let create = CreateEnvironment(self, cloudFactory)
                    env = try create.createEnvironment(with: arguments + ["--app=\(app.assertIdentifier())"])
                } else {
                    throw "Environment required"
                }
            } else {   
                env = try giveChoice(
                    title: "Which environment?",
                    in: envs
                )
            }
        }
        
        popEphemeral()
        
        detail("env", env.name)
        return env
    }
}

extension Environment: CustomStringConvertible {
    public var description: String {
        return "\(name)"
    }
}
