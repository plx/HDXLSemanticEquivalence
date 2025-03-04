import Foundation
import Testing

@testable import HDXLSemanticEquivalence

/// Dummy class for testing the semantic-equivalence system: `label` is used as
/// the `semanticEquivalenceClassIdentifier`, but we get *identity* only in the
/// event that the `caption` is also equal.
///
/// We need this in additino to `PrioritizedString` to test cases where we map
/// multiple equivalence classes to a common class-identifier.
///
/// `priority` remains how we determine favorability, with higher `priority`
/// corresponding to being more-favored.
internal final class PrioritizedStringDuo: @unchecked Sendable {

  let label: String
  let caption: String
  let priority: Int

  init(label: String, caption: String, priority: Int) {
    self.label = label
    self.caption = caption
    self.priority = priority
  }

}

extension PrioritizedStringDuo {

  func with(
    label newLabel: String,
    ensureUniqueCopy: Bool = true
  ) -> PrioritizedStringDuo {
    guard
      ensureUniqueCopy || newLabel != label
    else {
      return self
    }
    return PrioritizedStringDuo(
      label: newLabel,
      caption: caption,
      priority: priority
    )
  }

  @inlinable
  func with(
    priority newPriority: Int,
    ensureUniqueCopy: Bool = true
  ) -> PrioritizedStringDuo {
    guard
      ensureUniqueCopy || newPriority != priority
    else {
      return self
    }
    return PrioritizedStringDuo(
      label: label,
      caption: caption,
      priority: newPriority
    )
  }

}

extension PrioritizedStringDuo: Equatable {

  @inlinable
  internal static func == (
    lhs: PrioritizedStringDuo,
    rhs: PrioritizedStringDuo
  ) -> Bool {
    guard lhs !== rhs else {
      return true
    }
    guard
      lhs.label == rhs.label,
      lhs.caption == rhs.caption,
      lhs.priority == rhs.priority
    else {
      return false
    }
    return true
  }

}

extension PrioritizedStringDuo: Hashable {

  internal func hash(into hasher: inout Hasher) {
    label.hash(into: &hasher)
    caption.hash(into: &hasher)
    priority.hash(into: &hasher)
  }

}

extension PrioritizedStringDuo: CustomStringConvertible {

  internal var description: String {
    "'\(label)': '\(caption)' @ \(priority)"
  }

}

extension PrioritizedStringDuo: CustomDebugStringConvertible {

  internal var debugDescription: String {
    "PrioritizedStringDuo(label: '\(label)', caption: '\(caption)', priority: \(priority))"
  }

}

extension PrioritizedStringDuo: CustomTestStringConvertible {

  internal var testDescription: String {
    "(\(label), \(caption)) @ \(priority)"
  }
}

extension PrioritizedStringDuo: SemanticEquivalenceComparable {

  internal static func <~> (
    lhs: PrioritizedStringDuo,
    rhs: PrioritizedStringDuo
  ) -> SemanticEquivalenceComparisonResult {
    guard lhs !== rhs else {
      return .identical
    }
    guard
      lhs.label == rhs.label,
      lhs.caption == rhs.caption
    else {
      // ^ note we only use the label in the identifier,
      // and have a secondary field that factors into semantic equivalence.
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

struct StringPair: Hashable {
  var label: String
  var caption: String
}

extension PrioritizedStringDuo: SemanticItemIdentifiable {
  internal typealias SemanticItem = StringPair
  internal typealias EquivalencePriority = Int

  internal var semanticItemIdentifier: SemanticItemIdentifier<StringPair, Int> {
    SemanticItemIdentifier<StringPair, Int>(
      semanticItem: StringPair(
        label: label,
        caption: caption
      ),
      equivalencePriority: priority
    )
  }
}

extension PrioritizedStringDuo: SemanticEquivalenceClassIdentifierProviding {}

extension PrioritizedStringDuo {

  static func makeExamples(
    labels: some Collection<String>,
    captions: some Collection<String>,
    priorities: some Collection<Int>,
    repeatCount: Int = 1
  ) -> [PrioritizedStringDuo] {
    var result: [PrioritizedStringDuo] = []
    result.reserveCapacity(
      labels.count
        * captions.count
        * priorities.count
        * repeatCount
    )

    for label in labels {
      for caption in captions {
        for priority in priorities {
          for _ in 0..<repeatCount {
            result.append(
              PrioritizedStringDuo(
                label: label,
                caption: caption,
                priority: priority
              )
            )
          }
        }
      }
    }

    return result
  }

}
