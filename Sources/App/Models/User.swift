import Vapor
import FluentMySQL

extension User: Parameter {}
extension User: MySQLUUIDModel {}
extension User: Content {}
extension User: Migration {}

final class User: Codable {
    var id: UUID?
    let name: String
    let userName: String
    
    init(name: String, userName: String) {
        self.name = name
        self.userName = userName
        
    }
}

extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.creatorID)
    }
}
