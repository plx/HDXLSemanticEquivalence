import Foundation
import Testing

@testable import HDXLSemanticEquivalence

extension PrioritizedString {

  fileprivate static let foos: [PrioritizedString] = PrioritizedString.makeExamples(
    label: "foo",
    priorities: 1...2,
    repeatCount: 2
  )

  fileprivate static let bars: [PrioritizedString] = PrioritizedString.makeExamples(
    label: "bar",
    priorities: 1...2,
    repeatCount: 2
  )

  static let examples: [PrioritizedString] = PrioritizedString.foos + PrioritizedString.bars

}

@Test("`PrioritizedString.examples` self-equal and self-equivalent")
func prioritzedStringExamplesSelfEqualAndSelfEquivalent() {
  let examples = PrioritizedString.examples
  for example in examples {
    #expect(example == example)
    #expect(example.hasEquivalentSemantics(to: example))
    #expect(example.hasIdenticalSemantics(to: example))
    #expect(!example.shouldBeFavored(over: example))
  }
}

@Test("`PrioritizedString.foos` well-constructed")
func prioritizedFoosWellConstructed() {
  let foos = uniquePairs(from: PrioritizedString.foos)
  for (lhs, rhs) in foos {
    #expect(lhs.label == rhs.label)
    #expect(
      (lhs == rhs)
        == (lhs.priority == rhs.priority)
    )
    #expect(lhs !== rhs)
    #expect(lhs.hasEquivalentSemantics(to: rhs))
    #expect(
      lhs.hasIdenticalSemantics(to: rhs)
        == (lhs.priority == rhs.priority)
    )
    if lhs.priority < rhs.priority {
      #expect(rhs.shouldBeFavored(over: lhs))
      #expect(!lhs.shouldBeFavored(over: rhs))
    }
    if lhs.priority > rhs.priority {
      #expect(lhs.shouldBeFavored(over: rhs))
      #expect(!rhs.shouldBeFavored(over: lhs))
    }
  }
}

@Test("`PrioritizedString.bars` well-constructed")
func prioritizedBarsWellConstructed() {
  let bars = uniquePairs(from: PrioritizedString.bars)
  for (lhs, rhs) in bars {
    #expect(lhs.label == rhs.label)
    #expect(
      (lhs == rhs)
        == (lhs.priority == rhs.priority)
    )
    #expect(lhs !== rhs)
    #expect(lhs.hasEquivalentSemantics(to: rhs))
    #expect(
      lhs.hasIdenticalSemantics(to: rhs)
        == (lhs.priority == rhs.priority)
    )
    if lhs.priority < rhs.priority {
      #expect(rhs.shouldBeFavored(over: lhs))
      #expect(!lhs.shouldBeFavored(over: rhs))
    }
    if lhs.priority > rhs.priority {
      #expect(lhs.shouldBeFavored(over: rhs))
      #expect(!rhs.shouldBeFavored(over: lhs))
    }
  }
}

@Test("`PrioritizedString.foos` and `PrioritizedString.bars` are distinct")
func prioritizedFoosNotEqualToBars() {
  for (foo, bar) in cartesianProduct(PrioritizedString.foos, PrioritizedString.bars) {
    #expect(foo != bar)
    #expect(!foo.hasEquivalentSemantics(to: bar))
    #expect(!foo.hasIdenticalSemantics(to: bar))
    #expect(foo.semanticEquivalenceRelationship(with: bar) == .distinct)
  }
}
