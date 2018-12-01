import Vapor
import Leaf
import Authentication

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("acronyms", Acronym.parameter, use: acronymHandler)
        authSessionRoutes.get("users", use: usersHandler)
        authSessionRoutes.get("users", User.parameter, use: userHandler)
        authSessionRoutes.get("categories", use: categoriesHandler)
        authSessionRoutes.get("categories", Category.parameter, use: categoryHandler)
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post("login", use: loginFormHandler)
        
        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoutes.get("create-acronym", use: createAcronymHandler)
        protectedRoutes.post("create-acronym", use: createFormHandler)
        protectedRoutes.get("edit-acronym", Acronym.parameter, use: editAcronymHandler)
        protectedRoutes.post("edit-acronym", Acronym.parameter, use: editFormHandler)
        protectedRoutes.post("acronyms", Acronym.parameter, "delete", use: deleteHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Acronym.query(on: req).all().flatMap(to: View.self, { (acronyms) -> EventLoopFuture<View> in
            let context = IndexContent(title: "Homepage", acronyms: acronyms.isEmpty ? nil : acronyms)
            return try req.leaf().render("index", context)
        })
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self).flatMap(to: View.self, { acronym in
            return try flatMap(to: View.self,
                               acronym.creator.get(on: req),
                               acronym.categroies.query(on: req).all()) { user, categories in
                                
                                let context = AcronymDetail(title: acronym.short,
                                                            acronym: acronym,
                                                            creator: user,
                                                            categories: categories.isEmpty ? nil : categories)
                                return try req.leaf().render("acronym", context)
            }
        })
    }
    
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self, { (user) in
            return try user.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
                let context = UserContext(title: "Users", user: user, acronyms: acronyms.isEmpty ? nil : acronyms)
                return try req.leaf().render("user", context)
            }
        })
    }
    
    func usersHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).all().flatMap(to: View.self) { users in
            let context = UsersContext(title: "Users", users: users.isEmpty ? nil : users)
            return try req.leaf().render("users", context)
        }
    }
    
    func categoriesHandler(_ req: Request) throws -> Future<View> {
        return Category.query(on: req).all().flatMap(to: View.self, { categories in
            let context = CategoriesContext(title: "Categories",
                                            categories: categories.isEmpty ? nil : categories)
            return try req.leaf().render("categories", context)
        })
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Category.self).flatMap(to: View.self) { category in
            return try category.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
                let context = CategoryContext(name: category.name,
                                              acronyms: acronyms.isEmpty ? nil : acronyms)
                return try req.leaf().render("category", context)
            }
        }
    }
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> {
        let context = CreateAcronymContext(title: "Create an Acronym")
        return try req.leaf().render("createAcronym", context)
    }
    
    func createFormHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(AcronymForm.self).flatMap(to: Response.self) { data in
            let user = try req.requireAuthenticated(User.self)
            let acronym = try Acronym(short: data.acronymShort,
                                      long: data.acronymLong,
                                      creatorID: user.requireID())
            
            return acronym.save(on: req).map(to: Response.self) { acronym in
                
                guard let id = acronym.id else {
                    return req.redirect(to: "/")
                }
                return req.redirect(to: "acronyms/\(id)")
            }
        }
    }
    
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
            let context = EditAcronymContext(title: "Edit Acronym",
                                             acronym: acronym)
            return try req.leaf().render("editAcronym", context)
        }
    }
    
    func editFormHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(AcronymForm.self).flatMap(to: Response.self) { data in
            return try req.parameters.next(Acronym.self).flatMap(to: Response.self) { acronym in
                let user = try req.requireAuthenticated(User.self)
                let newAcronym = try Acronym(short: data.acronymShort,
                                             long: data.acronymLong,
                                             creatorID: user.requireID())
                newAcronym.id = acronym.id
                return newAcronym.save(on: req).map(to: Response.self) { acronym in
                    guard let id = newAcronym.id else {
                        return req.redirect(to: "/")
                    }
                    
                    return req.redirect(to: "/acronyms/\(id)")
                }
            }
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Acronym.self).flatMap(to: Response.self) { acronym in
            return acronym.delete(on: req).transform(to: req.redirect(to: "/"))
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context = LoginContext(title: "Log In")
        return try req.leaf().render("login", context)
    }

    func loginFormHandler( _ req: Request) throws -> Future<Response> {
        return try req.content.decode(LoginForm.self).flatMap(to: Response.self) { data in
            let verifier = try req.make(BCryptDigest.self)
            return User.authenticate(username: data.userName, password: data.password, using: verifier, on: req).map(to: Response.self) { user in

                guard let user = user else {
                    return req.redirect(to: "/login")
                }
                try req.authenticateSession(user)
                return req.redirect(to: "/")
            }
        }
    }
}

private extension Request {
    func leaf() throws -> LeafRenderer {
        return try self.make(LeafRenderer.self)
    }
}

struct IndexContent: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymDetail: Encodable {
    let title: String
    let acronym: Acronym
    let creator: User
    let categories: [Category]?
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]?
}

struct UsersContext: Encodable {
    let title: String
    let users: [User]?
}

struct CategoriesContext: Encodable {
    let title: String
    let categories: [Category]?
}

struct CategoryContext: Encodable {
    let name: String
    let acronyms: [Acronym]?
}

struct CreateAcronymContext: Encodable {
    let title: String
}

struct AcronymForm: Content {
    static let defaultContentType = MediaType.urlEncodedForm
    let acronymShort: String
    let acronymLong: String
}

struct EditAcronymContext: Encodable {
    let title: String
    let acronym: Acronym
}

struct LoginContext: Encodable {
    let title: String
}

struct LoginForm: Content {
    let userName: String
    let password: String
}
