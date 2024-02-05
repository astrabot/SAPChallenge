//
//  Created by Aliaksandr Strakovich on 19.03.22.
//

import Combine
import UIKit

final class SearchHistoryViewController: UIViewController {
    var viewModel: SearchHistoryViewModel? {
        didSet {
            if isViewLoaded {
                bind(to: viewModel)
            }
        }
    }

    private var cancellables: Set<AnyCancellable> = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        tableView.delegate = self
        return tableView
    }()

    lazy var dataSource: SearchHistoryTableViewDataSource = {
        let dataSource = SearchHistoryTableViewDataSource(tableView: tableView) { [weak self] tableView, indexPath, searchTerm in
            self?.createCell(forSearchTerm: searchTerm, in: tableView, at: indexPath)
        }
        return dataSource
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        view.addSubview(tableView)
        bind(to: viewModel)
    }

    private func bind(to viewModel: SearchHistoryViewModel?) {
        cancellables.removeAll()
        viewModel?.$searchTerms.sink { [weak self] terms in
            let snapshot = SearchHistoryTableViewDataSource.snapshot(with: terms)
            self?.dataSource.apply(snapshot)
        }.store(in: &cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        tableView.reloadData()
    }

    private func createCell(forSearchTerm term: String, in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        cell.textLabel?.text = term
        return cell
    }
}

extension SearchHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel?.selectItem(at: indexPath)
    }
}
