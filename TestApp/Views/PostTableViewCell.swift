import UIKit

final class PostTableViewCell: UITableViewCell {

    static let reuseId = "PostCell"

    // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowRadius = 5
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 28
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        return iv
    }()

    private let avatarSkeleton: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        v.layer.cornerRadius = 28
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
        contentView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Prepare For Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        currentPostId = nil
        avatarImageView.image = nil
        avatarSkeleton.isHidden = false
        avatarSkeleton.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    // MARK: - Setup UI

    private func setupViews() {
        contentView.addSubview(cardView)
        cardView.addSubview(avatarImageView)
        cardView.addSubview(avatarSkeleton)
        cardView.addSubview(titleLabel)
        cardView.addSubview(bodyLabel)
        cardView.addSubview(likeButton)

        NSLayoutConstraint.activate([
            // cardView
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // avatar
            avatarImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            avatarImageView.widthAnchor.constraint(equalToConstant: 56),
            avatarImageView.heightAnchor.constraint(equalToConstant: 56),

            avatarSkeleton.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            avatarSkeleton.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            avatarSkeleton.widthAnchor.constraint(equalTo: avatarImageView.widthAnchor),
            avatarSkeleton.heightAnchor.constraint(equalTo: avatarImageView.heightAnchor),

            // titleLabel
            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),

            // bodyLabel
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            // likeButton
            likeButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            likeButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            likeButton.widthAnchor.constraint(equalToConstant: 28),
            likeButton.heightAnchor.constraint(equalToConstant: 28),
            likeButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12) 
        ])

        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(with post: Post, liked: Bool) {
        currentPostId = post.id

        titleLabel.text = post.title.capitalized
        bodyLabel.text = post.body
        setLikedState(liked)

        avatarImageView.image = nil
        avatarSkeleton.isHidden = false
        startSkeleton()

        if let url = post.avatarURL {

            let expectedId = post.id

            ImageLoader.shared.load(url: url) { [weak self] image in
                guard let self = self else { return }

                // важно! иначе будет мигать
                guard self.currentPostId == expectedId else { return }

                DispatchQueue.main.async {
                    self.stopSkeleton()
                    UIView.transition(with: self.avatarImageView,
                                      duration: 0.25,
                                      options: .transitionCrossDissolve) {
                        self.avatarImageView.image = image
                    }
                }
            }
        }
    }

    func setLikedState(_ liked: Bool) {
        likeButton.setTitle(liked ? "♥︎" : "♡", for: .normal)
        likeButton.setTitleColor(liked ? .systemRed : .label, for: .normal)
    }

    @objc private func likeTapped() {
        UIView.animate(withDuration: 0.12, animations: {
            self.likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: { _ in
            UIView.animate(withDuration: 0.12) {
                self.likeButton.transform = .identity
            }
        })

        if currentPostId != nil {
            onLikeTapped?()
        }
    }

    // MARK: - Skeleton

    private func startSkeleton() {
        avatarSkeleton.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        avatarSkeleton.isHidden = false

        let shimmer = CAGradientLayer()
        shimmer.frame = avatarSkeleton.bounds
        shimmer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmer.colors = [
            UIColor(white: 0.85, alpha: 1).cgColor,
            UIColor(white: 0.95, alpha: 1).cgColor,
            UIColor(white: 0.85, alpha: 1).cgColor
        ]
        shimmer.locations = [0, 0.5, 1]

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [0, 0, 0.2]
        anim.toValue   = [0.8, 1, 1]
        anim.duration = 1.2
        anim.repeatCount = .infinity

        shimmer.add(anim, forKey: "shimmerAnimation")
        avatarSkeleton.layer.addSublayer(shimmer)
    }

    private func stopSkeleton() {
        avatarSkeleton.isHidden = true
        avatarSkeleton.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}
