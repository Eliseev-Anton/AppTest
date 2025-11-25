import UIKit

final class PostTableViewCell: UITableViewCell {

    static let reuseId = "PostCell"

    // MARK: - UI

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 28
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.widthAnchor.constraint(equalToConstant: 56).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return iv
    }()

    /// Skeleton loader for avatar
    private let avatarSkeleton: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        v.layer.cornerRadius = 28
        v.clipsToBounds = true
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.preferredFont(forTextStyle: .headline)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.numberOfLines = 4
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let likeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("♡", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 28)
        return b
    }()

    // MARK: - Data

    var onLikeTapped: (() -> Void)?
    private var currentPostId: Int?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    private func setupViews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(avatarSkeleton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(likeButton)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
         
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            avatarImageView.widthAnchor.constraint(equalToConstant: 56),
            avatarImageView.heightAnchor.constraint(equalToConstant: 56),
            
            likeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            likeButton.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor, constant: 2),

            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),

            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        likeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        likeButton.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(with post: Post, liked: Bool) {
        currentPostId = post.id

        titleLabel.text = post.title.capitalized
        bodyLabel.text = post.body
        setLikedState(liked)

        startSkeleton()

        if let url = post.avatarURL {
            ImageLoader.shared.load(url: url) { [weak self] image in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.stopSkeleton()
                    UIView.transition(with: self.avatarImageView,
                                      duration: 0.25,
                                      options: .transitionCrossDissolve) {
                        self.avatarImageView.image = image
                    }
                }
            }
        } else {
            stopSkeleton()
            avatarImageView.image = UIImage(systemName: "person.crop.circle")
        }
    }

    private func setLikedState(_ liked: Bool) {
        likeButton.setTitle(liked ? "♥︎" : "♡", for: .normal)
        likeButton.transform = .identity
    }

    // MARK: - Like animation

    @objc private func likeTapped() {
        UIView.animate(withDuration: 0.12, animations: {
            self.likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: { _ in
            UIView.animate(withDuration: 0.12) {
                self.likeButton.transform = .identity
            }
        })
        onLikeTapped?()
    }

    // MARK: - Skeleton Loader

    private func startSkeleton() {
        avatarSkeleton.isHidden = false
        avatarSkeleton.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let shimmer = CAGradientLayer()
        shimmer.name = "shimmer"
        shimmer.frame = avatarSkeleton.bounds
        shimmer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmer.colors = [
            UIColor(white: 0.85, alpha: 1).cgColor,
            UIColor(white: 0.95, alpha: 1).cgColor,
            UIColor(white: 0.85, alpha: 1).cgColor
        ]
        shimmer.locations = [0, 0.5, 1]

        avatarSkeleton.layer.addSublayer(shimmer)

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [0, 0, 0.2]
        anim.toValue   = [0.8, 1, 1]
        anim.duration = 1.2
        anim.repeatCount = .infinity

        shimmer.add(anim, forKey: "shimmerAnimation")
    }

    private func stopSkeleton() {
        avatarSkeleton.isHidden = true
        avatarSkeleton.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}
