//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Combine
import Foundation

enum APIError: Error, Equatable {
    case unknown
    case networkError
    case jsonDecodingError
    case cannotBuildURL
}

protocol APIServiceType {
    func search(term: String, paging: Paging?) -> AnyPublisher<SearchResult, APIError>
}

// Simple API service
final class APIService: APIServiceType {
    private enum Constants {
        static let APIKey = "818b8d81781722211335ef0db49be806"
        static let DefaultPageSize = 50
    }

    private let provider: APIProviderType
    private let decoder: JSONDecoder

    let baseURL = URL(string: "https://api.flickr.com/services/rest")!

    init(provider: APIProviderType, decoder: JSONDecoder) {
        self.provider = provider
        self.decoder = decoder
    }

    /// Returns a search result.
    ///
    /// - Parameters:
    ///   - term: A search term.
    func search(term: String, paging: Paging?) -> AnyPublisher<SearchResult, APIError> {
        debugPrint("Search term: '\(term)'")
        guard !term.isEmpty else {
            // exit early if nothing to seach
            return Just(SearchResult(page: 1, totalPages: 1, totalItems: 0, itemsPerPage: 0, photos: []))
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }

        var components = URLComponents() // NOTE: URLComponents automatically encodes query items
        components.queryItems = [
            URLQueryItem(name: "method", value: "flickr.photos.search"),
            URLQueryItem(name: "api_key", value: Constants.APIKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "nojsoncallback", value: "1"),
            URLQueryItem(name: "safe_search", value: "1"),
            URLQueryItem(name: "text", value: term)
        ]

        if let paging = paging {
            components.queryItems?.append(URLQueryItem(name: "page", value: "\(paging.page)"))
            components.queryItems?.append(URLQueryItem(name: "per_page", value: "\(paging.itemsPerPage)"))
        } else {
            components.queryItems?.append(URLQueryItem(name: "per_page", value: "\(Constants.DefaultPageSize)"))
        }

        guard let url = components.url(relativeTo: baseURL) else {
            return Fail(error: .cannotBuildURL).eraseToAnyPublisher()
        }
        let request: AnyPublisher<SearchResponse, APIError> = request(for: url)
        return request
            .map { $0.result }
            .eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func request<T: Decodable>(for url: URL) -> AnyPublisher<T, APIError> {
        provider.dataPublisher(for: URLRequest(url: url))
            .tryMap {
                guard let httpResponse =  $0.response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                    throw URLError(.badServerResponse)
                }
                return $0.data
            }
            .mapError { _ in APIError.networkError }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> APIError in
                guard let error = error as? APIError else { return APIError.jsonDecodingError }
                return error
            }
            .eraseToAnyPublisher()
    }
}
