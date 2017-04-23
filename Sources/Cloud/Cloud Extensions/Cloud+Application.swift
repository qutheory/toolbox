extension CloudAPI {
    func application(
        for arguments: [String],
        using console: ConsoleProtocol
    ) throws -> Application {
        let app: Application
        
        if let repoName = arguments.option("app")?.string {
            app = try application(withRepoName: repoName)
        } else {
            // picks an application by choosing
            // a project and then application
            func chooseFromList() throws -> Application {
                let projects = try console.loadingBar(title: "Loading projects", ephemeral: true) {
                    return try self.projects()
                }
                
                let project = try console.giveChoice(
                    title: "Which project?", in: projects
                ) { project in
                    return project.name
                }
                console.detail("project", project.name)
                
                let apps = try console.loadingBar(title: "Loading applications", ephemeral: true) {
                    return try applications(
                        projectId: project.assertIdentifier()
                    )
                }
                
                guard apps.count > 0 else {
                    console.warning("No applications found.")
                    console.print("Use: vapor cloud create")
                    throw "Application required"
                }
                
                return try console.giveChoice(
                    title: "Which application?",
                    in: apps
                )
            }
            
            if console.gitInfo.isGitProject() {
                // attempt to find app based on
                // git information
                let apps = try console.gitInfo
                    .remotes()
                    .flatMap { console.gitInfo.resolvedUrl($0.url) }
                    .flatMap { url in
                        try console.loadingBar(title: "Loading applications", ephemeral: true) {
                            return try applications(gitURL: url)
                        }
                    }
      
                // automatically choose app
                // if only one option was returned
                switch apps.count {
                case 0:
                    app = try chooseFromList()
                case 1:
                    app = apps[0]
                default:
                    app = try console.giveChoice(
                        title: "Which application?",
                        in: apps
                    )
                }
            } else {
                app = try chooseFromList()
            }    
        }
        
        console.detail("app", app.name)
        return app
    }
}

extension Application: CustomStringConvertible {
    public var description: String {
        return "\(name) (\(repoName).vapor.cloud)"
    }
}