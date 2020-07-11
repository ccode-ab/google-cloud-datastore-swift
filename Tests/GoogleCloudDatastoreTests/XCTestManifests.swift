import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DeleteTests.allTests),
        testCase(GetTests.allTests),
        testCase(IDTests.allTests),
        testCase(PutTests.allTests),
        testCase(QueryTests.allTests),
    ]
}
#endif
