import FluentMySQL
import Vapor

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    let creatorID: User.ID
    
    init(short: String, long: String, creatorID: User.ID) {
        self.short = short
        self.long = long
        self.creatorID = creatorID
    }
}

extension Acronym {
    var creator: Parent<Acronym, User> {
        return parent(\.creatorID)
    }
    
    var categroies: Siblings<Acronym, Category, AcronymCategoryPivot> {
        return siblings()
    }
}

extension Acronym: Parameter {}
extension Acronym: Migration {}
extension Acronym: Content {}
extension Acronym: MySQLModel {
//    typealias Database = SQLiteDatabase
//    typealias ID = Int
//    static var idKey: IDKey = \Acronym.id
}
