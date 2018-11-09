//
//  RxDeleteTests.swift
//  RxDeleteTests
//
//  Created by Piotr on 08/11/2018.
//  
//

import XCTest
import RxTest
import RxSwift
@testable import RxDelete

class BooksViewModelTest: XCTestCase {
    
    var viewModel: BooksViewModel!
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!

    override func setUp() {
        viewModel = BooksViewModel(api: DummyApi())
        testScheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }
    
    func testDeleteCommandRemovesItemFromCollection() {
        let itemsObserver = testScheduler.createObserver([Book].self)
        
        viewModel.items.bind(to: itemsObserver)
            .disposed(by: disposeBag)
        
        testScheduler.createHotObservable(
                [Recorded.next(100, IndexPath(row: 0, section: 0))]
            )
            .bind(to: viewModel.deleteCommand)
            .disposed(by: disposeBag)
        
        testScheduler.start()
        
        XCTAssertRecordedElements(
            itemsObserver.events,
            [
                [Book(title: "Book 1"), Book(title: "Book 2"), Book(title: "Book 3")],
                [Book(title: "Book 2"), Book(title: "Book 3")]
            ]
        )
    }
}
