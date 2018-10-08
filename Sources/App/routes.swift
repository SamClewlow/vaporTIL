import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    let acronymController = AcronymsController()
    try router.register(collection: acronymController)
    
    let categoryController = CategoryController()
    try router.register(collection: categoryController)
    
    let userController = UserController()
    try router.register(collection: userController)
    
    let websiteController = WebsiteController()
    try router.register(collection: websiteController)
}
