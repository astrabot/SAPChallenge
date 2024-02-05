//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Combine
import UIKit

final class HomeViewController: UIViewController {
    private var cancellables: Set<AnyCancellable> = []
    var viewModel: HomeViewModelType? {
        didSet { bind(to: viewModel) }
    }

    private var searchHistoryViewModel = SearchHistoryViewModel()

    private lazy var searchHistoryViewController: SearchHistoryViewController = {
        let viewController = SearchHistoryViewController()
        viewController.viewModel = searchHistoryViewModel
        return viewController
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: searchHistoryViewController)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.loadViewIfNeeded()
        searchController.searchBar.enablesReturnKeyAutomatically = false
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.placeholder = Strings.searchBarPlaceholder
        return searchController
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = HomeViewLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(PhotoCell.self)
        collectionView.register(LoadingFooterView.self, ofKind: UICollectionView.elementKindSectionFooter)
        return collectionView
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .systemOrange
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private lazy var emptyView: UIView = {
        let emptyView = EmptyView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        return emptyView
    }()

    private enum Constants {
        static let visibleFooterHeight: CGFloat = 56
        static let hiddenFooterHeight: CGFloat = 0
    }

    private var loadingFooterHeight: CGFloat = Constants.hiddenFooterHeight

    deinit { print("deinit \(Swift.type(of: self))") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        view.addSubview(spinner)
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func bind(to viewModel: HomeViewModelType?) {
        cancellables.removeAll()
        guard let viewModel = viewModel else { return }

        viewModel.titlePublisher.receive(on: DispatchQueue.main).sink { [weak self] title in
            self?.title = title
        }.store(in: &cancellables)
        viewModel.statePublisher.receive(on: DispatchQueue.main).sink { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .initial:
                self.collectionView.reloadData()
            case .loading:
                self.emptyView.isHidden = true
                self.spinner.startAnimating()
                self.setFooterVisible(true)
            case .loaded:
                self.emptyView.isHidden = true
                self.spinner.stopAnimating()
                self.collectionView.reloadData()
                self.setFooterVisible(false)
                self.updateTitle()
            case .failed(let error):
                self.emptyView.isHidden = true
                self.spinner.stopAnimating()
                self.setFooterVisible(false)
                self.showNetworkError(error)
            }
        }.store(in: &cancellables)

        searchHistoryViewModel.onSelectRecentSearch = { [weak self ] string in
            self?.dismissSearchInput()
            self?.searchController.searchBar.text = string
            self?.viewModel?.startSearch(term: string)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let viewModel = viewModel else { return }
        let height = scrollView.frame.size.height
        let contentYOffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYOffset

        updateTitle()

        if case .loading = viewModel.state { return } // break if loading still in progress

        if distanceFromBottom < height, viewModel.hasMorePhotosToDisplay {
            viewModel.fetchMoreResults()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateTitle()
    }

    // MARK: - Helpers

    private func setFooterVisible(_ isVisible: Bool) {
        guard let viewModel = viewModel, !viewModel.photos.isEmpty else { return }
        loadingFooterHeight = isVisible ? Constants.visibleFooterHeight : Constants.hiddenFooterHeight
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func showNetworkError(_ error: Error) {
        let alertController = UIAlertController(title: Strings.errorAlertTitle, message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.errorAlertOKAction, style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(UIAlertAction(title: Strings.errorAlertRetryAction, style: .default) { _ in
            self.viewModel?.retryFailedFetch()
            alertController.dismiss(animated: true, completion: nil)
        })
        present(alertController, animated: true, completion: nil)
    }

    private func updateTitle() {
        viewModel?.updateTitleForVisibleItems(collectionView.indexPathsForVisibleItems)
    }

    private func dismissSearchInput() {
        searchController.isActive = false
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel?.photos.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(for: indexPath) as PhotoCell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? PhotoCell else { return }
        guard let cellModel = viewModel?.makePhotoCellModel(forItemAt: indexPath) else { return }
        cell.configure(with: cellModel)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, for: indexPath) as LoadingFooterView
        default:
            assertionFailure("Unsupported supplementary element of kind " + kind)
            return UICollectionReusableView()
        }
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        CGSize(width: view.frame.size.width, height: loadingFooterHeight)
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel?.selectPhoto(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        UIView.animate(withDuration: 0.15) {
            cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        UIView.animate(withDuration: 0.1) {
            cell.transform = .identity
        }
    }
}

// MARK: - Search

extension HomeViewController: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        print(#function)
        searchController.showsSearchResultsController = true
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text
        if let text = text {
            searchHistoryViewModel.appendTerm(text)
            viewModel?.startSearch(term: text)
        }
        dismissSearchInput()
        searchBar.text = text // restore text input after dismissing search controller
    }
}

extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        print(#function)
    }
}
