import UIKit

final class FeedViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let viewModel = FeedViewModel()
    var onDataUpdated: (() -> Void)?
    var onLikeChanged: ((Int) -> Void)? // новый callback

        private var likedSet = Set<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feed"
        view.backgroundColor = .systemBackground
        setupTableView()
        bindViewModel()
        viewModel.fetchPosts(remote: false)
        // fetch remote in background
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
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

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
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }

        viewModel.onLoadingStateChanged = { isLoading in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
            }
        }
    }

    @objc private func pulledToRefresh() {
        viewModel.refresh()
    }
    

        func isLiked(postId: Int) -> Bool {
            likedSet.contains(postId)
        }

        func toggleLike(postId: Int) {
            if likedSet.contains(postId) {
                likedSet.remove(postId)
            } else {
                likedSet.insert(postId)
            }

            // НЕ вызываем onDataUpdated() — это бы триггерило reloadData()
            onLikeChanged?(postId)
        }
}

// MARK: - TableView DataSource & Delegate
extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.visiblePosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.reuseId, for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        let post = viewModel.visiblePosts[indexPath.row]
        cell.configure(with: post, liked: viewModel.isLiked(postId: post.id))
        cell.onLikeTapped = { [weak self] in
            guard let self else { return }

            self.viewModel.toggleLike(postId: post.id)

            if let row = self.viewModel.visiblePosts.firstIndex(where: { $0.id == post.id }) {
                let indexPath = IndexPath(row: row, section: 0)
                if let cell = self.tableView.cellForRow(at: indexPath) as? PostTableViewCell {
                    let liked = self.viewModel.isLiked(postId: post.id)
                    cell.setLikedState(liked)
                }
            }
        }

        // pagination trigger
        viewModel.loadMoreIfNeeded(currentIndex: indexPath.row)

        return cell
    }
}
