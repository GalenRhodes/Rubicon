//
//  RubiconTests.swift
//  RubiconTests
//
//  Created by Galen Rhodes on 3/19/20.
//  Copyright © 2020 Galen Rhodes. All rights reserved.
//

import XCTest
@testable import Rubicon

class RubiconTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testByteOrder() {
        let bo: CFByteOrder   = CFByteOrderGetCurrent()
        let be: __CFByteOrder = CFByteOrderBigEndian
        let le: __CFByteOrder = CFByteOrderLittleEndian

        print("/*===========================================================================================================================*/")
        print("CFByteOrderGetCurrent = \(bo); CFByteOrderBigEndian = \(be.rawValue); CFByteOrderLittleEndian = \(le.rawValue)")
        print("/*===========================================================================================================================*/")
    }

    /*===========================================================================================================================*/
    func testDir() {
        let fm: FileManager = FileManager.default
        let dr: String      = fm.currentDirectoryPath
        print("Current Dir: \"\(dr)\"")
    }

    /*===========================================================================================================================*/
    func testMemoryLayout() {
        print("UInt8:   size = \(MemoryLayout<UInt8>.size);  alignment = \(MemoryLayout<UInt8>.alignment);  stride = \(MemoryLayout<UInt8>.stride);")
        print("UInt16:  size = \(MemoryLayout<UInt16>.size);  alignment = \(MemoryLayout<UInt16>.alignment);  stride = \(MemoryLayout<UInt16>.stride);")
        print("UInt32:  size = \(MemoryLayout<UInt32>.size);  alignment = \(MemoryLayout<UInt32>.alignment);  stride = \(MemoryLayout<UInt32>.stride);")
        print("UInt64:  size = \(MemoryLayout<UInt64>.size);  alignment = \(MemoryLayout<UInt64>.alignment);  stride = \(MemoryLayout<UInt64>.stride);")
        print("Double:  size = \(MemoryLayout<Double>.size);  alignment = \(MemoryLayout<Double>.alignment);  stride = \(MemoryLayout<Double>.stride);")
        print("Float:   size = \(MemoryLayout<Float>.size);  alignment = \(MemoryLayout<Float>.alignment);  stride = \(MemoryLayout<Float>.stride);")
        // print("Float80: size = \(MemoryLayout<Float80>.size); alignment = \(MemoryLayout<Float80>.alignment); stride = \(MemoryLayout<Float80>.stride);")
    }

    //    func testPerformanceExample() {
    //        // This is an example of a performance test case.
    //        self.measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }
}
