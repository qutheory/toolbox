import JSON

enum SourceAccessLevel {
    case pub
    case priv
    case int
    case none
}

extension SourceAccessLevel: JSONInitializable {
    init(json: JSON) throws {
        switch json.string ?? "" {
        case "source.lang.swift.accessibility.public":
            self = .pub
        case "source.lang.swift.accessibility.private":
            self = .priv
        case "source.lang.swift.accessibility.internal":
            self = .int
        default:
            self = .none
        }
    }
}
