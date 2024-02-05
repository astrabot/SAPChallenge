//
//  Created by Aliaksandr Strakovich on 21.03.22.
//

import UIKit

protocol PhotoViewModelType {
    var imageUrl: URL? { get }
}

final class PhotoViewModel: PhotoViewModelType {
    let photo: Photo

    init(photo: Photo) {
        self.photo = photo
    }

    var imageUrl: URL? { photo.imageUrl }
}
