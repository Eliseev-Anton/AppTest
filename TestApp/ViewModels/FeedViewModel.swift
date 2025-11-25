import Foundation
import CoreData

/// ViewModel отвечает за бизнес-логику ленты:
/// - загрузку данных (локально и из сети)
/// - пагинацию
/// - оффлайн-кэширование через CoreData
/// - публикацию событий во ViewController
final class FeedViewModel {

    /// Размер страницы для ленивой пагинации.
    private let pageSize = 20

    /// Все посты, доступные сейчас в памяти.
    private(set) var allPosts: [Post] = []

    /// Посты, отображаемые пользователю (постепенное расширение списка).
    private(set) var visiblePosts: [Post] = []

    /// Callbacks для ViewController — MVVM binding.
    var onDataUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?

    /// Флаг загрузки — предотвращает повторные запросы.
    private var isLoading = false {
        didSet { onLoadingStateChanged?(isLoading) }
    }

    init() {
        // Начинаем с загрузки кэша, чтобы приложение работало оффлайн.
        loadFromCache()
    }

    /// Pull-to-refresh триггер.
    func refresh() {
        fetchPosts(remote: true)
    }

    /// Загружает посты либо из сети, либо из CoreData.
    func fetchPosts(remote: Bool = false) {
        if isLoading { return }
        isLoading = true

        if remote {
            NetworkService.shared.fetchPosts { [weak self] result in
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let posts):
                    // Сортируем по ID для стабильного отображения
                    self.allPosts = posts.sorted { $0.id < $1.id }

                    // Сохраняем в CoreData, затем перезагружаем из неё,
                    // чтобы сохранить корректный liked-статус.
                    CoreDataStack.shared.upsertPosts(posts) {
                        self.loadFromCache()
                    }

                case .failure(let error):
                    // Показываем ошибку, но продолжаем работать из кэша
                    self.onError?(error)
                    self.loadFromCache()
                }
            }

        } else {
            // Быстрая локальная загрузка
            loadFromCache()
            isLoading = false
        }
    }

    /// Загружает данные из CoreData и подготавливает первую страницу.
    private func loadFromCache() {
        let entities = CoreDataStack.shared.fetchSavedPosts()

        // Преобразуем CoreData entity в чистые модели
        self.allPosts = entities.map {
            Post(userId: Int($0.userId),
                 id: Int($0.id),
                 title: $0.title ?? "",
                 body: $0.body ?? "")
        }

        visiblePosts = Array(allPosts.prefix(pageSize))
        onDataUpdated?()
    }

    /// Запускает пагинацию, когда пользователь близко к концу списка.
    func loadMoreIfNeeded(currentIndex: Int) {
        guard currentIndex >= visiblePosts.count - 5 else { return }

        let nextCount = min(visiblePosts.count + pageSize, allPosts.count)
        guard nextCount > visiblePosts.count else { return }

        visiblePosts = Array(allPosts.prefix(nextCount))
        onDataUpdated?()
    }

    // MARK: - Likes

    /// Проверяет, лайкнут ли пост в CoreData.
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

    /// Переключает лайк и сохраняет состояние в CoreData.
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
            print("toggleLike error:", error)
        }
    }
}
