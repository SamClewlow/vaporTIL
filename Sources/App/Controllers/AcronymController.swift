import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoute = router.grouped("api", "acronyms")
        acronymsRoute.get(use: getAllHandler)
        acronymsRoute.get(Acronym.parameter, use: getHandler)
        acronymsRoute.get(Acronym.parameter, "creator", use: getCreatorHandler)
        acronymsRoute.get(Acronym.parameter, "categories", use: getCategoriesHandler)
        acronymsRoute.post(Acronym.parameter, "category", Category.parameter, use: addCategoriesHandler)
        acronymsRoute.get("search", use: searchHandler)
        
        let tokenAuthMiddlewear = User.tokenAuthMiddleware()
        let tokenAuthGroup = acronymsRoute.grouped(tokenAuthMiddlewear)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    func createHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.content.decode(AcronymCreateData.self)
            .flatMap(to: Acronym.self) { data in
                let user = try req.requireAuthenticated(User.self)
                let acronym = try Acronym(short: data.short,
                                          long: data.long,
                                          creatorID: user.requireID())
                return acronym.save(on: req)
            }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).flatMap(to: HTTPStatus.self, { (acronym) -> EventLoopFuture<HTTPStatus> in
            return acronym.delete(on: req).transform(to: .noContent)
        })
    }
    
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(AcronymCreateData.self)) { acronym, updatedAcronym -> Future<Acronym> in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            acronym.creatorID = try req.requireAuthenticated(User.self).requireID()
            return acronym.save(on: req)
        }
    }
    
    func getCreatorHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(Acronym.self).flatMap(to: User.self, { acronym in
            return acronym.creator.get(on: req)
        })
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self).flatMap(to: [Category].self, { acronym in
            return try acronym.categroies.query(on: req).all()
        })
    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Acronym.self),
                           req.parameters.next(Category.self), { (acronym, category) in
                            
                            let pivot = try AcronymCategoryPivot(acronymID: acronym.requireID(),
                                                                 categoryID: category.requireID())
                            return pivot.save(on: req).transform(to: .ok)
        })
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let term = req.query[String.self, at: "term"] else {
           throw Abort(.badRequest, reason: "Missing search term")
        }
        return Acronym.query(on: req).group(.or, closure: { (or) in
            or.filter(\.short == term)
            or.filter(\.long == term)
        }).all()
    }
}

struct AcronymCreateData: Content {
    let short: String
    let long: String
}
