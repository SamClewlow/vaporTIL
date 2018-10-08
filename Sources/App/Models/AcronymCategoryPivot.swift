import FluentMySQL
import Vapor
import Foundation

final class AcronymCategoryPivot: MySQLUUIDPivot {
    typealias Left = Acronym
    static var leftIDKey: LeftIDKey = \AcronymCategoryPivot.acronymID
    
    typealias Right = Category
    static var rightIDKey: RightIDKey = \AcronymCategoryPivot.categoryID
    
    var id: UUID?
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    init(acronymID: Acronym.ID, categoryID: Category.ID) {
        self.acronymID = acronymID
        self.categoryID = categoryID
    }
}

extension AcronymCategoryPivot: Migration {}
