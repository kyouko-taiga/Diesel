import XCTest

import DieselTests

var tests = [XCTestCaseEntry]()
tests += DieselTests.__allTests()

XCTMain(tests)
