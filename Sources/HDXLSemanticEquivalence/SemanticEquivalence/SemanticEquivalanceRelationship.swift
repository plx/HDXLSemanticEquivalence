import Foundation

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceRelationship - Definition
// -------------------------------------------------------------------------- //

/// `SemanticEquivalenceRelationship` defines the possible outcomes when
/// comparing two values for *semantic equivalence*, but without delving into
/// issues of favored representations.
///
/// For fuller details see the documentation for `SemanticEquivalanceComparable`.
///
@objc(HDXLSemanticEquivalenceRelationship)
public enum SemanticEquivalenceRelationship: Int {

  /// Case for when the represented values have distinct semantics (e.g. `1/2` and `1/3`).
  case distinct

  /// Case for when the values, themselves, are identical (e.g. `1/2` and `1/2`).
  case identical

  /// Case for when the represented values are equivalent but not *identical* (e.g. `1/2` vs `2/4`).
  case equivalent

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceRelationship - Support
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship {

  /// `true` iff `self` implies the compared values are semantically-distinct.
  @inlinable
  public var impliesDistinctness: Bool {
    switch self {
    case .distinct:
      true
    case .identical:
      false
    case .equivalent:
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
    case .equivalent:
      true
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship: Sendable {}
extension SemanticEquivalenceRelationship: Equatable {}
extension SemanticEquivalenceRelationship: Hashable {}
extension SemanticEquivalenceRelationship: Codable {}
extension SemanticEquivalenceRelationship: CaseIterable {}

// -------------------------------------------------------------------------- //
// MARK: - Identifiable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship: Identifiable {
  public typealias ID = Self

  @inlinable
  public var id: ID { self }
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship: CustomStringConvertible {

  @inlinable
  public var description: String {
    switch self {
    case .distinct:
      ".distinct"
    case .identical:
      ".identical"
    case .equivalent:
      ".equivalent"
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship: CustomDebugStringConvertible {

  @inlinable
  public var debugDescription: String {
    switch self {
    case .distinct:
      "SemanticEquivalenceRelationship.distinct"
    case .identical:
      "SemanticEquivalenceRelationship.identical"
    case .equivalent:
      "SemanticEquivalenceRelationship.equivalent"
    }
  }

}
