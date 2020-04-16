import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PrioritizedStringTests.allTests),
        testCase(PrioritizedStringDuoTests.allTests),
        testCase(SemanticEquivalenceClassTests.allTests),
        testCase(SemanticEquivalenceTableTests.allTests)
    ]
}
#endif
