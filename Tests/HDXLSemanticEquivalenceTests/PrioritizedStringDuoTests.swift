import Foundation
import Testing

@testable import HDXLSemanticEquivalence

private let testDepth: Int = 3
private let testPriorities = 0...3

extension PrioritizedStringDuo {

  fileprivate static var unorganizedTestValues: some Collection<PrioritizedStringDuo> {
    makeExamples(
      labels: ["foo", "bar", "baz", "quux"],
      captions: ["alpha", "beta", "gamma", "delta"],
      priorities: testPriorities,
      repeatCount: testDepth
    )
  }

}

@Test("`PrioritizedStringDuo` semantics")
func prioritizedStringDuoSemantics() {
  let unorganizedTestValues = PrioritizedStringDuo.unorganizedTestValues
  for (x, y) in cartesianProduct(unorganizedTestValues, unorganizedTestValues) {
    #expect(
      x.hasEquivalentSemantics(to: y)
        == (x.label == y.label && x.caption == y.caption)
    )
    if x.hasEquivalentSemantics(to: y) && x.priority > y.priority {
      #expect(x.shouldBeFavored(over: y))
    }

    switch x <~> y {
    case .distinct:
      #expect(x.label != y.label || x.caption != y.caption)
    case .identical:
      #expect(x == y)
      #expect(x.label == y.label)
      #expect(x.caption == y.caption)
      #expect(x.priority == y.priority)
    case .equivalentPreferLHS:
      #expect(x.label == y.label)
      #expect(x.caption == y.caption)
      #expect(x.priority > y.priority)
    case .equivalentPreferRHS:
      #expect(x.label == y.label)
      #expect(x.caption == y.caption)
      #expect(x.priority < y.priority)
    }
  }
}
