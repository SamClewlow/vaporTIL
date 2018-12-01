import Vapor
import FluentMySQL
import Authentication

extension User: Parameter {}
extension User: MySQLUUIDModel {}
extension User: Content {}
extension User: Migration {}

final class User: Codable {
    var id: UUID?
    var name: String
    var userName: String
    var password: String
    
    init(name: String,
         userName: String,
         password: String) {
        
        self.name = name
        self.userName = userName
        self.password = password
    }
    
    final class Public: Codable {
        var id: UUID?
        var name: String
        var userName: String
        
        init(name: String,
             userName: String) {
            
            self.name = name
            self.userName = userName
        }
    }
}

extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.creatorID)
    }
}


extension User: BasicAuthenticatable {
    static var usernameKey: UsernameKey = \User.userName
    static var passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

extension User: SessionAuthenticatable {}
extension User: PasswordAuthenticatable {}

extension User.Public: MySQLUUIDModel {
    static let entity = User.entity
}

extension User.Public: Content {}
extension User.Public: Parameter {}
