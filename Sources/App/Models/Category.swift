import FluentMySQL
import Vapor

final class Category: Codable {
    var id: Int?
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Category {
    var acronyms: Siblings<Category, Acronym, AcronymCategoryPivot> {
        return siblings()
    }
}

extension Category: Content {}
extension Category: Migration {}
extension Category: MySQLModel {}
extension Category: Parameter {}
