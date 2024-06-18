import Foundation
import XCTest
//import HDXLCommonUtilities
import HDXLTestingUtilities
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
@usableFromInline
internal final class PrioritizedStringDuo {
  
  @usableFromInline
  let label: String

  @usableFromInline
  let caption: String

  @usableFromInline
  let priority: Int
  
  @inlinable
  init(label: String, caption: String, priority: Int) {
    self.label = label
    self.caption = caption
    self.priority = priority
  }
  
}

internal extension PrioritizedStringDuo {
  
  @inlinable
  func with(
    label: String,
    ensureUniqueCopy: Bool = true) -> PrioritizedStringDuo {
    guard
      ensureUniqueCopy || label != self.label else {
        return self
    }
    return PrioritizedStringDuo(
      label: label,
      caption: self.caption,
      priority: self.priority
    )
  }

  @inlinable
  func with(
    priority: Int,
    ensureUniqueCopy: Bool = true) -> PrioritizedStringDuo {
    guard
      ensureUniqueCopy || priority != self.priority else {
        return self
    }
    return PrioritizedStringDuo(
      label: self.label,
      caption: self.caption,
      priority: priority
    )
  }

}

extension PrioritizedStringDuo : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: PrioritizedStringDuo,
    rhs: PrioritizedStringDuo) -> Bool {
    guard lhs !== rhs else {
      return true
    }
    guard
      lhs.label == rhs.label,
      lhs.caption == rhs.caption,
      lhs.priority == rhs.priority else {
        return false
    }
    return true
  }
  
}

extension PrioritizedStringDuo : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.label.hash(into: &hasher)
    self.caption.hash(into: &hasher)
    self.priority.hash(into: &hasher)
  }

}

extension PrioritizedStringDuo : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      return "'\(self.label)': '\(self.caption)' @ \(self.priority)"
    }
  }
  
}

extension PrioritizedStringDuo : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      return "PrioritizedStringDuo(label: '\(self.label)', caption: '\(self.caption)', priority: \(self.priority))"
    }
  }
  
}

extension PrioritizedStringDuo : SemanticEquivalenceComparable {
  
  @inlinable
  internal static func <~> (
    lhs: PrioritizedStringDuo,
    rhs: PrioritizedStringDuo) -> SemanticEquivalenceComparisonResult {
    guard lhs !== rhs else {
      return .identical
    }
    guard
      lhs.label == rhs.label,
      lhs.caption == rhs.caption else {
        // ^ note we only use the label in the identifier,
        // and have a secondary field that factors into semantic equivalence.
      return .distinct
    }
    switch lhs.priority <=> rhs.priority {
    case .orderedAscending:
      return .equivalentPreferRHS
    case .orderedSame:
      return .identical
    case .orderedDescending:
      return .equivalentPreferLHS
    }
  }
  
}

extension PrioritizedStringDuo : SemanticEquivalenceClassIdentifierConvertible {
  
  @usableFromInline
  internal typealias SemanticEquivalenceClassIdentifier = String
  
  @inlinable
  internal var semanticEquivalenceClassIdentifier: String {
    get {
      return self.label
    }
  }
  
}
