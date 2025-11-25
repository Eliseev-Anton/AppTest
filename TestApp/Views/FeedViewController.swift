import UIKit

/// Контроллер ленты отвечает только за:
/// - отображение UI
/// - подписку на события ViewModel
/// - управление таблицей
///
/// Вся логика вынесена во ViewModel (MVVM).
final class FeedViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    /// ViewModel с бизнес-логикой.
    private let viewModel = FeedViewModel()

    /// Локальный кэш лайков (часть UI-логики).
    private var likedSet = Set<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feed"
        view.backgroundColor = .systemBackground

        setupTableView()
        bindViewModel()

        // Сначала показываем оффлайн-кэш
        viewModel.fetchPosts(remote: false)

        // Потом подгружаем свежие данные
        viewModel.fetchPosts(remote: true)
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.register(PostTableViewCell.self,
                           forCellReuseIdentifier: PostTableViewCell.reuseId)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140

        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    /// Подписываемся на события ViewModel (однонаправленный поток данных).
    private func bindViewModel() {
        viewModel.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                self?.tableView.reloadData()
            }
        }

        viewModel.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                self?.showError(error)
            }
        }

    }

    @objc private func pulledToRefresh() {
        viewModel.refresh()
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
// MARK: - TableView
extension FeedViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.visiblePosts.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PostTableViewCell.reuseId,
            for: indexPath
        ) as? PostTableViewCell else {
            return UITableViewCell()
        }

        let post = viewModel.visiblePosts[indexPath.row]

        // Передаем актуальное состояние лайка
        cell.configure(with: post, liked: viewModel.isLiked(postId: post.id))

        // Обработка лайка
        cell.onLikeTapped = { [weak self] in
            guard let self else { return }

            self.viewModel.toggleLike(postId: post.id)

            // Обновляем только одну ячейку, без reloadData — предотвращает мигание
            if let row = self.viewModel.visiblePosts.firstIndex(where: { $0.id == post.id }) {
                let path = IndexPath(row: row, section: 0)
                if let visibleCell = self.tableView.cellForRow(at: path) as? PostTableViewCell {
                    let liked = self.viewModel.isLiked(postId: post.id)
                    visibleCell.setLikedState(liked)
                }
            }
        }

        // Триггер пагинации
        viewModel.loadMoreIfNeeded(currentIndex: indexPath.row)
        return cell
    }
}
