import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(GetTests.allTests),
        testCase(PutTests.allTests),
        testCase(QueryTests.allTests),
    ]
}
#endif
