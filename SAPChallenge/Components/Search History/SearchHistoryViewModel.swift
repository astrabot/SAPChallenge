//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Combine
import UIKit

final class SearchHistoryViewModel {
    @Published var searchTerms: [String] = ["Hello", "World"]
    var onSelectRecentSearch: ((String) -> Void)?

    func selectItem(at indexPath: IndexPath) {
        onSelectRecentSearch?(searchTerms[indexPath.row])
    }

    func appendTerm(_ term: String) {
        searchTerms.append(term)
    }
}
