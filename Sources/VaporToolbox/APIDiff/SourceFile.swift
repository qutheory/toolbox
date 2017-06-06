import JSON

final class SourceFile {
    let name: String
    let keys: [SourceKey]
    
    init(name: String, keys: [SourceKey]) {
        self.name = name
        self.keys = keys
    }
}
