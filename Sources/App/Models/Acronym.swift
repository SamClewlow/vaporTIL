import FluentSQLite
import Vapor

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String) {
        self.short = short
        self.long = long
    }
}

extension Acronym: Migration {}
extension Acronym: Content {}
extension Acronym: SQLiteModel {
//    typealias Database = SQLiteDatabase
//    typealias ID = Int
//    static var idKey: IDKey = \Acronym.id
}
