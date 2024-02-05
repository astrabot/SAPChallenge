//
//  Created by Aliaksandr Strakovich on 21.03.22.
//

import UIKit

final class PhotoViewController: UIViewController {
    let viewModel: PhotoViewModelType

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    init(viewModel: PhotoViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(imageView)
        createImageViewConstraints()
    }

    private func createImageViewConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let imageUrl = viewModel.imageUrl {
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(with: imageUrl, options: [.transition(.fade(0.3))]) { [weak self] result in
                if case .failure = result {
                    self?.imageView.image = UIImage(systemName: Images.System.exclamationmark)?.withRenderingMode(.alwaysTemplate)
                }
            }
        } else {
            imageView.image = UIImage(systemName: Images.System.questionmark)?.withRenderingMode(.alwaysTemplate)
        }
    }
}
