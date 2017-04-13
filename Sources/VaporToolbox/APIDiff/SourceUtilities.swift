import JSON

extension JSON {
    var pretty: String {
        return try! serialize(prettyPrint: true).makeString()
    }
}

extension Array where Iterator.Element: JSONInitializable {
    init(json: JSON) throws {
        self = try json.array?.map { json in
            return try Iterator.Element(json: json)
        } ?? []
    }
}

