import Foundation
import XCTest
//import /*HDXLCommonUtilities*/
import HDXLTestingUtilities
@testable import HDXLSemanticEquivalence

/// Dummy class for testing the semantic-equivalence system: `label` determines
/// *semantics* and then `priority` determines favorability (with higher `priority`
/// corresponding to being more-favored).
@usableFromInline
internal final class PrioritizedString {
  
  @usableFromInline
  let label: String
  
  @usableFromInline
  let priority: Int
  
  @inlinable
  init(label: String, priority: Int) {
    self.label = label
    self.priority = priority
  }
  
}

internal extension PrioritizedString {
  
  @inlinable
  func with(
    label: String,
    ensureUniqueCopy: Bool = true) -> PrioritizedString {
    guard
      ensureUniqueCopy || label != self.label else {
        return self
    }
    return PrioritizedString(
      label: label,
      priority: self.priority
    )
  }

  @inlinable
  func with(
    priority: Int,
    ensureUniqueCopy: Bool = true) -> PrioritizedString {
    guard
      ensureUniqueCopy || priority != self.priority else {
        return self
    }
    return PrioritizedString(
      label: self.label,
      priority: priority
    )
  }

}

extension PrioritizedString : Equatable {
  
  @inlinable
  internal static func ==(
    lhs: PrioritizedString,
    rhs: PrioritizedString) -> Bool {
    guard lhs !== rhs else {
      return true
    }
    guard
      lhs.label == rhs.label,
      lhs.priority == rhs.priority else {
        return false
    }
    return true
  }
  
}

extension PrioritizedString : Hashable {
  
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    self.label.hash(into: &hasher)
    self.priority.hash(into: &hasher)
  }

}

extension PrioritizedString : CustomStringConvertible {
  
  @inlinable
  internal var description: String {
    get {
      return "'\(self.label)' @ \(self.priority)"
    }
  }
  
}

extension PrioritizedString : CustomDebugStringConvertible {
  
  @inlinable
  internal var debugDescription: String {
    get {
      return "PrioritizedString(label: '\(self.label)', priority: \(self.priority))"
    }
  }
  
}

extension PrioritizedString : SemanticEquivalenceComparable {
  
  @inlinable
  internal static func <~> (
    lhs: PrioritizedString,
    rhs: PrioritizedString) -> SemanticEquivalenceComparisonResult {
    guard lhs !== rhs else {
      return .identical
    }
    guard lhs.label == rhs.label else {
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

extension PrioritizedString : SemanticEquivalenceClassIdentifierConvertible {
  
  @usableFromInline
  internal typealias SemanticEquivalenceClassIdentifier = String
  
  @inlinable
  internal var semanticEquivalenceClassIdentifier: String {
    get {
      return self.label
    }
  }
  
}
