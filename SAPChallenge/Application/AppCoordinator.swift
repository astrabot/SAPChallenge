//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import UIKit

class AppCoordinator {
    let navigationController: UINavigationController
    lazy var apiService: APIServiceType = {
        let configuration = URLSessionConfiguration.default // or URLSessionConfiguration.ephemeral to do not use persistent storage for caches, cookies, or credentials
        configuration.timeoutIntervalForRequest = 5 // make request timeout shorter
        let session = URLSession(configuration: configuration)
        return APIService(provider: session, decoder: JSONDecoder())
    }()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = HomeViewModel(api: apiService)
        viewModel.onSelectPhoto = { [weak self] photo in
            self?.selectPhoto(photo)
        }

        // a. Constructor injection of a view model
        // let homeViewController = HomeViewController(viewModel: viewModel)
        // or
        // b. Property injection of a view model
        let homeViewController = HomeViewController()
        homeViewController.viewModel = viewModel
        navigationController.pushViewController(homeViewController, animated: true)
    }

    func selectPhoto(_ photo: Photo) {
        let viewModel = PhotoViewModel(photo: photo)
        let photoViewController = PhotoViewController(viewModel: viewModel)
        navigationController.pushViewController(photoViewController, animated: true)
    }
}
