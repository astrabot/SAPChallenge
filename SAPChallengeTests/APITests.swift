//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Combine
import Foundation
import XCTest
@testable import SAPChallenge

final class APITests: XCTestCase {
    var apiService: APIServiceType!
    var apiProviderMock: APIProviderMock!
    private var cancellables: [AnyCancellable] = []

    override func setUpWithError() throws {
        apiProviderMock = APIProviderMock()
        apiService = APIService(provider: apiProviderMock, decoder: JSONDecoder())
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        apiService = nil
        apiProviderMock = nil
    }

    func test_searchTerm_badServerResponse() {
        apiProviderMock.mockedDataPublisher = Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()

        let expectation = self.expectation(description: #function)
        apiService.search(term: "text", paging: nil)
        .sink { result in
            switch result {
            case .failure(.networkError):
                break
            default:
                XCTFail("unexpected result")
            }
            expectation.fulfill()
        } receiveValue: { _ in }
        .store(in: &cancellables)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_earchTerm_noResults() throws {
        let response = makeMockAPIResponse(with: "{\"photos\":{\"page\":0,\"pages\":0,\"perpage\":0,\"total\":0,\"photo\":[]},\"stat\":\"ok\"}")
        let mockedDataPublisher = Just(response).setFailureType(to: URLError.self).eraseToAnyPublisher()
        apiProviderMock.mockedDataPublisher = mockedDataPublisher

        let expectation = self.expectation(description: #function)
        apiService.search(term: "AA", paging: nil)
        .sink { result in
            switch result {
            case .failure(let error):
                XCTFail("unexpected error \(error)")
                expectation.fulfill()
            case .finished:
                break
            }
        } receiveValue: { result in
            XCTAssertTrue(result.photos.isEmpty)
            expectation.fulfill()
        }
        .store(in: &cancellables)
        waitForExpectations(timeout: 1, handler: nil)
    }

    private func makeMockAPIResponse(with string: String) -> (data: Data, response: URLResponse) {
        let response = HTTPURLResponse(url: URL(string: "https://dev.null")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        let data = string.data(using: .utf8)!
        return (data, response as URLResponse)
    }
}
