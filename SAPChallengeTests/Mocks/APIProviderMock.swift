//
//  Created by Aliaksandr Strakovich on 21.03.22.
//

import Combine
import Foundation
@testable import SAPChallenge

class APIProviderMock: APIProviderType {
    var mockedDataPublisher: AnyPublisher<APIResponse, URLError>!
    func dataPublisher(for request: URLRequest) -> AnyPublisher<APIResponse, URLError> {
        mockedDataPublisher
    }
}
