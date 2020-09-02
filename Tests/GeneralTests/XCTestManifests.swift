//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(GeneralTests.allTests)
    ]
}
#endif
