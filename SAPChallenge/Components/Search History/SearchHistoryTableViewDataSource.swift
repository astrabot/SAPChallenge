//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import UIKit

enum Section { case main }

final class SearchHistoryTableViewDataSource: UITableViewDiffableDataSource<Section, String> {
    static func snapshot(with terms: [String]) -> NSDiffableDataSourceSnapshot<Section, String> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(terms)
        return snapshot
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Strings.recentSearches
    }
}
