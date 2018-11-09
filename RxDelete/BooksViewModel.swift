//
//  ItemsViewModel.swift
//  RxDelete
//
//  Created by Piotr on 08/11/2018.
//
//

import RxSwift
import RxCocoa
import RxDataSources

struct Book {
    let title: String
}

extension Book: IdentifiableType {
    var identity: String {
        return title
    }
}

protocol Api {
    func getBooks() -> Observable<[Book]>
    func deleteBook(_ book: Book) -> Single<Book>
}

class DummyApi: Api {
    
    let books = BehaviorRelay<[Book]>(value: [
        Book(title: "Book 1"),
        Book(title: "Book 2"),
        Book(title: "Book 3")
    ])
    
    func getBooks() -> Observable<[Book]> {
        return books.asObservable()
    }
    
    func deleteBook(_ book: Book) -> Single<Book> {
        return Observable<Int>.timer(0.5, scheduler: MainScheduler.instance)
            .map { _ in book }
            .asSingle()
            .do(onSuccess: { [unowned self] (deletedBook) in
                self.books.accept(
                    self.books.value.filter { $0 != deletedBook }
                )
            })
    }
}

enum BookCollectionAction {
    case collectionRefreshed(withBooks: [Book])
    case bookMarkedForDeletion(_ book: Book)
}

class BooksViewModel {
    // MARK: inputs
    let deleteCommand = PublishRelay<IndexPath>()
    
    // MARK: outputs
    let items: Observable<[Book]>
    
    private let disposeBag = DisposeBag()
    private let collectionActions = ReplaySubject<BookCollectionAction>.create(bufferSize: 1)
    
    init(api: Api = DummyApi()) {
        items = collectionActions.scan([], accumulator: { (currentBooks, action) -> [Book] in
            switch action {
            case .bookMarkedForDeletion(let book):
                return currentBooks.filter { $0 != book }
            case .collectionRefreshed(withBooks: let books):
                return books
            }
        })
        
        api.getBooks()
            .map { books -> BookCollectionAction in return .collectionRefreshed(withBooks: books) }
            .bind(to: collectionActions)
            .disposed(by: disposeBag)
        
        let bookMarkedForDeletion =  deleteCommand
            .withLatestFrom(items) { index, items in return items[index.row] }
            .share()
        
        bookMarkedForDeletion
            .map { book -> BookCollectionAction in return .bookMarkedForDeletion(book) }
            .bind(to: collectionActions)
            .disposed(by: disposeBag)

        bookMarkedForDeletion
            .flatMap(api.deleteBook)
            .subscribe()
            .disposed(by: disposeBag)
    }
}

