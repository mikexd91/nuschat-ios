//
//  nuschatUITests.swift
//  nuschatUITests
//
//  Created by Mike Zhang Xunda on 17/7/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import XCTest

class nuschatUITests: XCTestCase {
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // 1
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        // 2
        snapshot("00UserEntries")
        let googleButton = app.buttons["googleLogin"]
//        let cells = app.collectionViews.cells
//        let n = arc4random_uniform(UInt32(cells.count))
//        let randomCell = cells.element(boundBy: UInt(n))
        googleButton.tap()
        snapshot("01UserEntries")
        
       // let cells = app.tableRows.cells.element(boundBy: UInt(0))
        //cells.tap()
        //snapshot("02UserEntries")

    }
    
    
    func testExample2() {
        let app = XCUIApplication()
//        setupSnapshot(app)
        app.launch()
        app.buttons["googleLogin"].tap()
        
        let tabBarsQuery = app.tabBars
//        tabBarsQuery.buttons["Contacts"].tap()
//        
        let tablesQuery2 = app.tables
//        let searchContactsSearchField = tablesQuery2.searchFields[" Search Contacts..."]
//        searchContactsSearchField.tap()
//        searchContactsSearchField.typeText("m")
//        searchContactsSearchField.typeText("s")
//        searchContactsSearchField.tap()
//        app.typeText("")
//        tabBarsQuery.buttons["Recents"].tap()
        
        let tablesQuery = tablesQuery2
        tablesQuery.staticTexts["sabre: La"].tap()
        
        let toolbarsQuery = app.toolbars
        let newMessageTextView = toolbarsQuery.textViews["New Message"]
        newMessageTextView.tap()
        newMessageTextView.typeText("hello")
        toolbarsQuery.buttons["Send"].tap()
        
        let nuschatButton = app.navigationBars["nba"].buttons["#nuschat"]
        nuschatButton.tap()
        tablesQuery.staticTexts["You: Hello"].swipeLeft()
        nuschatButton.tap()

    }
    
}
