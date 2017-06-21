//
//  BreadcrumbsTests.swift
//  BreadcrumbsTests
//
//  Created by Nicholas Outram on 20/06/2017.
//  Copyright © 2017 Plymouth University. All rights reserved.
//

import XCTest
import CoreLocation

fileprivate let N = 100

class BreadcrumbsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        print("**************************UP********************************")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        print("*************************DOWN*******************************")
        super.tearDown()
    }
    
    // Populate the model with N samples
    func populateSequentially(with N : Int) {
        let exp1 = expectation(description: "Array was populated successfully")
        
        func iter(_ count : Int) {
            if (count <= 0) {
                exp1.fulfill()
                return
            }
            let loc = CLLocation(latitude: 0.1*Double(count), longitude: 0.1*Double(count))
            globalModel.addRecord(loc) {
                //print("Added a location - count = \(count)")
                iter(count - 1)
            }
        }
        
        iter(N)
        wait(for: [exp1], timeout: 5)//5s timeout
    }
    
    func clear() {
        //*************************
        //Now clear all values down
        //*************************
        let exp3 = expectation(description: "Array was cleared successfully")
        
        globalModel.erase {
            globalModel.getArray() { (arr : [CLLocation]) in
                XCTAssert(arr.isEmpty == true, "ARRAY NOT EMPTY!")
                exp3.fulfill()
            }
        }
        wait(for: [exp3], timeout: 5)//5s timeout
    }
    
    func testReadAll() {
        //*************************************
        // Add 100 elements in rapid succession
        //*************************************
        clear()
        populateSequentially(with: 100)
        
        
        //***********************************************
        //Now read back and check the values are the same
        //***********************************************
        let exp2 = expectation(description: "Array was read successfully")
        globalModel.getArray { (arr : [CLLocation]) in
            var idx = N
            for loc in arr {
                print("Lat: \(loc.coordinate.latitude)  Long: \(loc.coordinate.longitude)")
                XCTAssert(loc.coordinate.latitude == Double(idx)*0.1, "INCORRECT LATTITUDE")
                XCTAssert(loc.coordinate.longitude == Double(idx)*0.1, "INCORRECT LONGITUDE")
                idx -= 1
            }
            XCTAssert(idx == 0, "WRONG NUMBER OF ELEMENTS")
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 5)//5s timeout
        
        
        // ***********************
        // Clear down all elements
        // ***********************
        clear()
        
    }
    
    func testSave() {
        clear()
        populateSequentially(with: 200)
        let exp = expectation(description: "Array was saved and loaded successfully")
        globalModel.save {
            print("Saved")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
        
        clear()
        globalModel.reload() //blocking and potentially slow - a known issue to be addressed (needs a delegate)
        
        let exp1 = expectation(description: "Array was saved and loaded successfully")
        globalModel.getArray { (arr : [CLLocation]) in
            XCTAssert(arr.count == 200, "Expecting 200 samples unarchived - found \(arr.count)")
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 5)
    }
    
    //Big claim I know - just trying to aggravate it
    func testForDeadlock() {
        clear()
        populateSequentially(with: 10000)
        let exp = expectation(description: "Array was previously saved and initialised with the saved data")
        globalModel.addRecord(CLLocation()) {
            globalModel.addRecord(CLLocation()) {
                globalModel.addRecord(CLLocation()) {
                    globalModel.save() {
                        globalModel.reload()
                        globalModel.addRecord(CLLocation()) {
                            globalModel.save() {
                                exp.fulfill()
                            }
                        }
                    }
                }
            }
        }
        wait(for: [exp], timeout: 30)
        
        let exp1 = expectation(description: "Array has 1004 samples as expected")
        
        globalModel.reload()
        globalModel.getArray { (arr : [CLLocation]) in
            XCTAssert(arr.count == 10004, "Expecting 10004 samples unarchived - found \(arr.count)")
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 5)
        
        let exp2 = expectation(description: "Array is reset and saved")
        populateSequentially(with: 200)
        globalModel.save {
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 5)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
