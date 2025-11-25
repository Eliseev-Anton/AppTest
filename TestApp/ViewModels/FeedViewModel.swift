import Foundation
import CoreData

final class FeedViewModel {
    // Configuration
    private let pageSize = 20

    // Data
    private(set) var allPosts: [Post] = []
    private(set) var visiblePosts: [Post] = []

    // Observers
    var onDataUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?

    private var isLoading = false {
        didSet { onLoadingStateChanged?(isLoading) }
    }

    init() {
        // try load from CoreData first
        loadFromCache()
    }

    func refresh() {
        fetchPosts(remote: true)
    }

    func fetchPosts(remote: Bool = false) {
        if isLoading { return }
        isLoading = true

        if remote {
            NetworkService.shared.fetchPosts { [weak self] result in
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let posts):
                    self.allPosts = posts.sorted { $0.id < $1.id }
                    // save to CoreData
                    CoreDataStack.shared.upsertPosts(posts) {
                        self.loadFromCache() // reload using CoreData entities to preserve likes
                    }
                case .failure(let error):
                    self.onError?(error)
                    self.loadFromCache()
                }
            }
        } else {
            // load local cache
            loadFromCache()
            isLoading = false
        }
    }

    private func loadFromCache() {
        let entities = CoreDataStack.shared.fetchSavedPosts()
        // map to Post while preserving liked state in separate map
        // But we expose only Post for UI; liked state fetched from entities when needed
        self.allPosts = entities.map { Post(userId: Int($0.userId), id: Int($0.id), title: $0.title ?? "", body: $0.body ?? "") }
        self.visiblePosts = Array(allPosts.prefix(pageSize))
        onDataUpdated?()
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        guard currentIndex >= visiblePosts.count - 5 else { return }
        let nextCount = min(visiblePosts.count + pageSize, allPosts.count)
        guard nextCount > visiblePosts.count else { return }
        visiblePosts = Array(allPosts.prefix(nextCount))
        onDataUpdated?()
    }

    // MARK: Like handling
    func isLiked(postId: Int) -> Bool {
        let req: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %d", postId)
        do {
            let res = try CoreDataStack.shared.viewContext.fetch(req)
            return res.first?.liked ?? false
        } catch {
            return false
        }
    }

    func toggleLike(postId: Int) {
        let ctx = CoreDataStack.shared.viewContext
        let req: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %d", postId)
        do {
            let res = try ctx.fetch(req)
            if let ent = res.first {
                ent.liked.toggle()
                try ctx.save()
            }
        } catch {
            print("toggleLike error: \(error)")
        }
    }
}
