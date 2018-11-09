//
//  ViewController.swift
//  RxDelete
//
//  Created by Piotr on 08/11/2018.
//  
//

import UIKit
import RxDataSources
import RxSwift

struct SectionOfBooks {
    var header: String?
    var items: [Book]
}

extension Book: Equatable { }

func == (lhs: Book, rhs: Book) -> Bool { return lhs.title == rhs.title }

extension SectionOfBooks: AnimatableSectionModelType {
    typealias Item = Book
    
    var identity: String { return self.header ?? "SectionOfBooks" }
    
    init(original: SectionOfBooks, items: [Book]) {
        self = original
        self.items = items
    }
}

fileprivate func createDataSource() -> RxTableViewSectionedAnimatedDataSource<SectionOfBooks> {
    return RxTableViewSectionedAnimatedDataSource(
        animationConfiguration: AnimationConfiguration(insertAnimation: .automatic, reloadAnimation: .automatic, deleteAnimation: .left),
        configureCell:{ (ds, tableView, indexPath, book) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
            cell.textLabel?.text = book.title
            return cell
        },
        canEditRowAtIndexPath: { _, _ in true }
    )
}

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let dataSource = createDataSource()

    let disposeBag = DisposeBag()
    
    var viewModel: BooksViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = BooksViewModel()
        
        viewModel.items
            .map { books in [SectionOfBooks(header: "My books", items: books)] }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.itemDeleted
            .bind(to: viewModel.deleteCommand)
            .disposed(by: disposeBag)
    }


}

