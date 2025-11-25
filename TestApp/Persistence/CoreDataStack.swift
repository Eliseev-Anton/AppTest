import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TestApp")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext { container.viewContext }
    
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // --- Helper: save posts ---
    func upsertPosts(_ posts: [Post], completion: (() -> Void)? = nil) {
        let ctx = viewContext
        ctx.perform {
            let fetchReq: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
            do {
                let existing = try ctx.fetch(fetchReq)
                var existingMap = [Int: PostEntity]()
                existing.forEach { existingMap[Int($0.id)] = $0 }
                
                for post in posts {
                    if let ent = existingMap[post.id] {
                        // update
                        ent.title = post.title
                        ent.body = post.body
                        ent.userId = Int64(post.userId)
                        // keep liked as it was
                    } else {
                        let ent = PostEntity(context: ctx)
                        ent.id = Int64(post.id)
                        ent.userId = Int64(post.userId)
                        ent.title = post.title
                        ent.body = post.body
                        ent.liked = false
                    }
                }
                
                try ctx.save()
                completion?()
            } catch {
                print("CoreData upsert error: \(error)")
                completion?()
            }
        }
    }
    
    func fetchSavedPosts() -> [PostEntity] {
        let req: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        do {
            return try viewContext.fetch(req)
        } catch {
            print("fetchSavedPosts error: \(error)")
            return []
        }
    }
}

