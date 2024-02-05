//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Combine
import UIKit

protocol HomeViewModelType {
    var state: HomeViewModel.State { get }
    var isEmpty: Bool { get }
    var photos: [Photo] { get } // we expose photos here just for our convenience
    var hasMorePhotosToDisplay: Bool { get }
    var titlePublisher: AnyPublisher<String?, Never> { get }
    var statePublisher: AnyPublisher<HomeViewModel.State, Never> { get }
    var searchInput: CurrentValueSubject<String, Never> { get }
    func updateTitleForVisibleItems(_ indexPaths: [IndexPath])
    func startSearch(term: String)
    func fetchMoreResults()
    func retryFailedFetch()
    func makePhotoCellModel(forItemAt indexPath: IndexPath) -> PhotoCellModel
    func selectPhoto(at indexPath: IndexPath)
}

final class HomeViewModel: HomeViewModelType {
    var onSelectPhoto: ((Photo) -> Void)?

    enum State {
        case initial, loading, loaded(SearchResult), failed(APIError)
    }

    @Published var state: State = .initial
    var statePublisher: AnyPublisher<HomeViewModel.State, Never> { $state.eraseToAnyPublisher() }

    @Published var title: String?
    var titlePublisher: AnyPublisher<String?, Never> { $title.removeDuplicates().eraseToAnyPublisher() }

    var searchInput = CurrentValueSubject<String, Never>("")
    private var cancellables: Set<AnyCancellable> = []

    private var lastLoadedResult: SearchResult? // cached last loaded search result
    private var currentVisiblePage = -1 // current visible page while scrolling. -1 means initial state
    private var photosPerPage = [Int: [Photo]]()
    var photos: [Photo] {
        photosPerPage.sorted { $0.key < $1.key }.flatMap { $0.value }
    }

    var isEmpty: Bool { photos.isEmpty }

    var hasMorePhotosToDisplay: Bool {
        guard let seachResult = lastLoadedResult else { return false }
        return seachResult.page < seachResult.totalPages
    }

    private let api: APIServiceType
    private var fetchCancellation: AnyCancellable?

    init(api: APIServiceType) {
        self.api = api
    }

    deinit { print("deinit \(Swift.type(of: self))") }

    func updateTitleForVisibleItems(_ indexPaths: [IndexPath]) {
        guard let seachResult = lastLoadedResult, seachResult.totalPages > 0 else {
            title = nil
            return
        }
        let maxVisibleItem = indexPaths.map { $0.item }.max() ?? 0
        let currentVisiblePage = seachResult.itemsPerPage > 0 ? Int(maxVisibleItem / seachResult.itemsPerPage) + 1 : 1
        title = "\(currentVisiblePage) of \(seachResult.totalPages)"
    }

    func startSearch(term: String) {
        state = .initial
        fetchCancellation = nil
        lastLoadedResult = nil
        photosPerPage.removeAll()
        searchInput.send(term)
        search(term: searchInput.value, paging: nil)
    }

    func fetchMoreResults() {
        guard case let .loaded(result) = state else { return }
        search(term: searchInput.value, paging: Paging(page: result.page + 1, itemsPerPage: result.itemsPerPage))
    }

    func retryFailedFetch() {
        guard case .failed = state else { return } // nothing to retry
        let paging: Paging?
        if let searchResult = lastLoadedResult {
            paging = Paging(page: searchResult.page + 1, itemsPerPage: searchResult.itemsPerPage)
        } else {
            paging = nil
        }
        search(term: searchInput.value, paging: paging)
    }

    func makePhotoCellModel(forItemAt indexPath: IndexPath) -> PhotoCellModel {
        let photo = photos[indexPath.item]
        return PhotoCellModel(title: photo.id, description: photo.title, imageUrl: photo.imageUrl)
    }

    func selectPhoto(at indexPath: IndexPath) {
        onSelectPhoto?(photos[indexPath.item])
    }

    // MARK: - Helpers

    private func search(term: String, paging: Paging?) {
        state = .loading
        fetchCancellation = api.search(term: term, paging: paging)
            .sink(receiveCompletion: { [weak self] result in
                if case let .failure(error) = result {
                    print(error)
                    self?.state = .failed(error)
                }
            }, receiveValue: { [weak self] result in
                print("Did fetch search result: page \(result.page) | " +
                      "items per page \(result.photos.count) | " +
                      "total items \(result.totalItems) | " +
                      "total pages \(result.totalPages)")
                guard let self = self else { return }
                self.photosPerPage[result.page] = result.photos
                self.lastLoadedResult = result
                self.state = .loaded(result)
            })
    }
}
