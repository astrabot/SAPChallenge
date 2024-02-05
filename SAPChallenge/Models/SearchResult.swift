//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Foundation

struct SearchResult: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case page, totalPages = "pages", totalItems = "total", itemsPerPage = "perpage", photos = "photo"
    }
    let page: Int
    let totalPages: Int
    let totalItems: Int
    let itemsPerPage: Int
    let photos: [Photo]

    var paging: Paging {
        .init(page: page, itemsPerPage: itemsPerPage)
    }
}

struct SearchResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case result = "photos", stat
    }
    let result: SearchResult
    let stat: String
}
