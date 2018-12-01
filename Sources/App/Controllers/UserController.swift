import Vapor
import Authentication

final class UserController: RouteCollection {
    func boot(router: Router) throws {
        let userRoute = router.grouped("api", "users")
        userRoute.post(use: createHandler)
        userRoute.get(use: getAllHandler)
        userRoute.get(User.Public.parameter, use: getHandler)
        userRoute.get(User.parameter, "acronyms", use: getAcronymsHandler)
        
        let basicAuthMiddlewear = User.basicAuthMiddleware(using: BCrypt)
        let basicAuthGroup = userRoute.grouped(basicAuthMiddlewear)
        basicAuthGroup.post("login", use: loginHandler)
        
    }
    
    func createHandler(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap(to: User.self) { user in
            let hasher = try req.make(BCryptDigest.self)
            user.password = try hasher.hash(user.password)
            return user.save(on: req)
        }
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.Public.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.Public.self)
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(User.self).flatMap(to: [Acronym].self, { user in
            return try user.acronyms.query(on: req).all()
        })
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
}
