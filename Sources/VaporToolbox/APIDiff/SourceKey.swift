import JSON

final class SourceKey {
    let accessLevel: SourceAccessLevel
    let kind: String
    let name: String?
    let typeName: String?
    let usr: String?
    let typeUsr: String?
    let subKeys: [SourceKey]
    
    init(
        accessLevel: SourceAccessLevel,
        kind: String,
        name: String?,
        typeName: String?,
        usr: String?,
        typeUsr: String?,
        subKeys: [SourceKey]
    ) {
        self.accessLevel = accessLevel
        self.kind = kind.components(separatedBy: ".").last ?? ""
        self.name = name
        self.typeName = typeName
        self.usr = usr
        self.typeUsr = typeUsr
        self.subKeys = subKeys
    }
}

extension SourceKey: JSONInitializable {
    convenience init(json: JSON) throws {
        let name: String? = try json.get(DotKey("key.name"))
        
        let subkeys: [SourceKey] = try json[DotKey("key.substructure")]?.array?.map { subkeyJSON in
            var subkeyJSON = subkeyJSON
            
            // create nested name
            let currentName = subkeyJSON[DotKey("key.name")]?.string ?? ""
            let nestedName = (name ?? "") + "." + (currentName)
            
            // update json with nested name
            subkeyJSON[DotKey("key.name")] = JSON(nestedName)
            
            // initialize from json
            return try SourceKey(json: subkeyJSON)
        } ?? []
        
        try self.init(
            accessLevel: SourceAccessLevel(json: json.get(DotKey("key.accessibility"))),
            kind: json.get(DotKey("key.kind")),
            name: name,
            typeName: json.get(DotKey("key.typename")),
            usr: json.get(DotKey("key.usr")),
            typeUsr: json.get(DotKey("key.typeusr")),
            subKeys: subkeys
        )
    }
}

extension Array where Iterator.Element == SourceKey {
    func print() {
        forEach { key in
            key.print()
        }
    }
}
extension SourceKey {
    func print(indent: Int = 0) {
        let pad = String(repeating: "\t", count: indent)
        Swift.print(pad + loggable)
        for key in subKeys {
            key.print(indent: indent + 1)
        }
    }
    
    func collect(_ symbols: inout [String: SourceKey]) {
        if let usr = self.usr, accessLevel == .pub {
            symbols[usr] = self
        }
        for key in subKeys {
            key.collect(&symbols)
        }
    }
}

extension SourceKey {
    var loggable: String {
        return "\(name ?? "") \(usr ?? "")"
    }
}

extension SourceKey: CustomStringConvertible {
    var description: String {
        return name ?? ""
    }
}
