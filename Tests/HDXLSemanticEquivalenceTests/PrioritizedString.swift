import Foundation
import Testing

@testable import HDXLSemanticEquivalence

/// Dummy class for testing the semantic-equivalence system: `label` determines
/// *semantics* and then `priority` determines favorability (with higher `priority`
/// corresponding to being more-favored).
internal final class PrioritizedString: @unchecked Sendable {

  let label: String
  let priority: Int

  init(label: String, priority: Int) {
    self.label = label
    self.priority = priority
  }

}

extension PrioritizedString {

  func with(
    label newLabel: String,
    ensureUniqueCopy: Bool = true
  ) -> PrioritizedString {
    guard
      ensureUniqueCopy || newLabel != label
    else {
      return self
    }
    return PrioritizedString(
      label: newLabel,
      priority: priority
    )
  }

  func with(
    priority newPriority: Int,
    ensureUniqueCopy: Bool = true
  ) -> PrioritizedString {
    guard
      ensureUniqueCopy || newPriority != priority
    else {
      return self
    }
    return PrioritizedString(
      label: label,
      priority: newPriority
    )
  }

}

extension PrioritizedString: Equatable {

  internal static func == (
    lhs: PrioritizedString,
    rhs: PrioritizedString
  ) -> Bool {
    guard lhs !== rhs else {
      return true
    }
    guard
      lhs.label == rhs.label,
      lhs.priority == rhs.priority
    else {
      return false
    }
    return true
  }

}

extension PrioritizedString: Hashable {

  internal func hash(into hasher: inout Hasher) {
    label.hash(into: &hasher)
    priority.hash(into: &hasher)
  }

}

extension PrioritizedString: CustomStringConvertible {

  internal var description: String {
    "'\(label)' @ \(priority)"
  }

}

extension PrioritizedString: CustomDebugStringConvertible {

  internal var debugDescription: String {
    "PrioritizedString(label: '\(label)', priority: \(priority))"
  }

}

extension PrioritizedString: SemanticEquivalenceComparable {

  internal static func <~> (
    lhs: PrioritizedString,
    rhs: PrioritizedString
  ) -> SemanticEquivalenceComparisonResult {
    guard lhs !== rhs else {
      return .identical
    }
    guard lhs.label == rhs.label else {
      return .distinct
    }

    return if lhs.priority < rhs.priority {
      .equivalentPreferRHS
    } else if lhs.priority > rhs.priority {
      .equivalentPreferLHS
    } else {
      .identical
    }
  }

}

extension PrioritizedString: SemanticItemIdentifiable {
  internal typealias SemanticItem = String
  internal typealias EquivalencePriority = Int

  internal var semanticItemIdentifier: SemanticItemIdentifier<String, Int> {
    SemanticItemIdentifier<String, Int>(
      semanticItem: label,
      equivalencePriority: priority
    )
  }
}

extension PrioritizedString: SemanticEquivalenceClassIdentifierProviding {}

extension PrioritizedString {

  static func makeExamples(
    label: String,
    priorities: some Collection<Int>,
    repeatCount: Int = 1
  ) -> [PrioritizedString] {
    makeExamples(
      labels: CollectionOfOne(label),
      priorities: priorities,
      repeatCount: repeatCount
    )
  }

  static func makeExamples(
    labels: some Collection<String>,
    priorities: some Collection<Int>,
    repeatCount: Int = 1
  ) -> [PrioritizedString] {
    var result: [PrioritizedString] = []
    result.reserveCapacity(
      labels.count * priorities.count
    )

    for label in labels {
      for priority in priorities {
        for _ in 0..<repeatCount {
          result.append(
            PrioritizedString(
              label: label,
              priority: priority
            )
          )
        }
      }
    }

    return result
  }
}
