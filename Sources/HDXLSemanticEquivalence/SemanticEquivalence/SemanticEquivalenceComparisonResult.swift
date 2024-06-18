import Foundation

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceComparisonResult - Definition
// -------------------------------------------------------------------------- //

/// `SemanticEquivalenceComparisonResult` defines the possible outcomes when
/// comparing two values for *semantic equivalence*
///
/// For fuller details see the documentation for `SemanticEquivalanceComparable`.
///
@objc(HDXLSemanticEquivalenceComparisonResult)
public enum SemanticEquivalenceComparisonResult : Int {
  
  /// Case for when the represented values have distinct semantics (e.g. `1/2` and `1/3`).
  case distinct
  
  /// Case for when the values, themselves, are identical (e.g. `1/2` and `1/2`).
  case identical

  /// Case for when the represented values are equivalent, but we should prefer the `lhs` (e.g. `1/2` vs `2/4`).
  ///
  /// - note: the *reason* for that preference will necessarily be type-specific.
  ///
  case equivalentPreferLHS

  /// Case for when the represented values are equivalent, but we should prefer the `rhs` (e.g. `2/4` vs `1/2`).
  ///
  /// - note: the *reason* for that preference will necessarily be type-specific.
  ///
  case equivalentPreferRHS
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceComparisonResult - Support
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult {

  /// `true` iff `self` implies the compared values are semantically-distinct.
  @inlinable
  public var impliesDistinctness: Bool {
    switch self {
    case .distinct:
      true
    case .identical:
      false
    case .equivalentPreferLHS:
      false
    case .equivalentPreferRHS:
      false
    }
  }

  /// `true` iff `self` implies the compared types are semantically-equivalent.
  @inlinable
  public var impliesEquivalence: Bool {
    switch self {
    case .distinct:
      false
    case .identical:
      true
    case .equivalentPreferLHS:
      true
    case .equivalentPreferRHS:
      true
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : Sendable { }
extension SemanticEquivalenceComparisonResult : Equatable { }
extension SemanticEquivalenceComparisonResult : Hashable { }
extension SemanticEquivalenceComparisonResult : Codable { }
extension SemanticEquivalenceComparisonResult : CaseIterable { }

// -------------------------------------------------------------------------- //
// MARK: - Identifiable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : Identifiable {
  public typealias ID = Self
  
  @inlinable
  public var id: ID { self }
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : CustomStringConvertible {

  @inlinable
  public var description: String {
    switch self {
    case .distinct:
      ".distinct"
    case .identical:
      ".identical"
    case .equivalentPreferLHS:
      ".equivalentPreferLHS"
    case .equivalentPreferRHS:
      ".equivalentPreferRHS"
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    switch self {
    case .distinct:
      "SemanticEquivalenceComparisonResult.distinct"
    case .identical:
      "SemanticEquivalenceComparisonResult.identical"
    case .equivalentPreferLHS:
      "SemanticEquivalenceComparisonResult.equivalentPreferLHS"
    case .equivalentPreferRHS:
      "SemanticEquivalenceComparisonResult.equivalentPreferRHS"
    }
  }
  
}
