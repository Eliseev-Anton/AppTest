import Foundation
import CoreData

/// CoreData stack responsible for persistent storage:
/// - Loading persistent container
/// - Saving context changes
/// - Managing Posts caching (offline mode)
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    /// Main persistent container of the application.
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TestApp")
        
        // Load storage (SQLite by default). Fatal for unrecoverable errors.
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("CoreData load error: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    /// Shortcut for main context (UI thread).
    var viewContext: NSManagedObjectContext { container.viewContext }
    
    /// Saves changes in the main context if needed.
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do { try context.save() }
            catch {
                fatalError("CoreData save error: \(error.localizedDescription)")
            }
        }
    }

    /// Inserts or updates posts in persistent storage.
    /// Preserves `liked` state for existing entities.
    func upsertPosts(_ posts: [Post], completion: (() -> Void)? = nil) {
        let ctx = viewContext
        
        ctx.perform {
            let fetchReq: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
            
            do {
                // Build dictionary for O(1) lookup
                let existing = try ctx.fetch(fetchReq)
                var existingMap = [Int: PostEntity]()
                existing.forEach { existingMap[Int($0.id)] = $0 }

                // Insert or update incoming posts
                for post in posts {
                    if let ent = existingMap[post.id] {
                        // Update existing entity
                        ent.title = post.title
                        ent.body = post.body
                        ent.userId = Int64(post.userId)
                    } else {
                        // Insert new entity
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
                print("CoreData upsert error:", error)
                completion?()
            }
        }
    }

    /// Loads all posts from persistent storage sorted by ID.
    func fetchSavedPosts() -> [PostEntity] {
        let req: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        do { return try viewContext.fetch(req) }
        catch {
            print("fetchSavedPosts error:", error)
            return []
        }
    }
}
