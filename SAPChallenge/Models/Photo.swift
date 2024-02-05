//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Foundation

struct Photo: Decodable, Equatable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
    let title: String?
}

// Simple extension to build image url https://farm{farm}.static.flickr.com/{server}/{id}_{secret}.jpg
// A separate builder can be also implemented 
extension Photo {
    var imageUrl: URL? {
        let imageUrlString = "https://farm\(farm).static.flickr.com/\(server)/\(id)_\(secret).jpg"
        return URL(string: imageUrlString)
    }
}
