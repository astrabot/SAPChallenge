//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Kingfisher
import UIKit

struct PhotoCellModel {
    let title: String
    let description: String?
    let imageUrl: URL?
}

final class PhotoCell: UICollectionViewCell {
    private enum Constants {
        static let cornerRadius: CGFloat = 5
        static let borderColor: UIColor = .gray
        static let borderWidth: CGFloat = 1.0 / UIScreen.main.scale
    }

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .tertiarySystemBackground
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textColor = .label
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .label
        label.numberOfLines = 2
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        return stackView
    }()

    private lazy var containerView: UIView = {
        let effectsView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        effectsView.translatesAutoresizingMaskIntoConstraints = false
        effectsView.contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: effectsView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: effectsView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: effectsView.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: effectsView.layoutMarginsGuide.bottomAnchor)
        ])
        return effectsView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = nil
        contentView.backgroundColor = .tertiarySystemBackground

        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Constants.borderColor.cgColor
        contentView.layer.cornerRadius = Constants.cornerRadius

        contentView.addSubview(imageView)
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
    }

    func configure(with cellModel: PhotoCellModel) {
        titleLabel.text = cellModel.title
        descriptionLabel.text = cellModel.description
        guard let imageUrl = cellModel.imageUrl else {
            imageView.image = UIImage(systemName: Images.System.questionmark)?.withRenderingMode(.alwaysTemplate)
            return
        }
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: imageUrl, options: [.transition(.fade(0.3))]) { [weak imageView] result in
            if case .failure = result {
                imageView?.image = UIImage(systemName: Images.System.exclamationmark)?.withRenderingMode(.alwaysTemplate)
            }
        }
    }
}
