//
//  SemanticEquivalenceComparison.swift
//

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
public enum SemanticEquivalenceRelationship : Int {
  
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

public extension SemanticEquivalenceRelationship {

  /// `true` iff `self` implies the compared values are semantically-distinct.
  @inlinable
  var impliesDistinctness: Bool {
    get {
      switch self {
      case .distinct:
        return true
      case .identical:
        return false
      case .equivalent:
        return false
      }
    }
  }

  /// `true` iff `self` implies the compared types are semantically-equivalent.
  @inlinable
  var impliesEquivalence: Bool {
    get {
      switch self {
      case .distinct:
        return false
      case .identical:
        return true
      case .equivalent:
        return true
      }
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceRelationship - Equatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship : Equatable {
  
  @inlinable
  public static func ==(
    lhs: SemanticEquivalenceRelationship,
    rhs: SemanticEquivalenceRelationship) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  @inlinable
  public static func !=(
    lhs: SemanticEquivalenceRelationship,
    rhs: SemanticEquivalenceRelationship) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceRelationship - Hashable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship : Hashable {
  
  @inlinable
  public func hash(into hasher: inout Hasher) {
    self.rawValue.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceRelationship - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship : CustomStringConvertible {

  @inlinable
  public var description: String {
    get {
      switch self {
      case .distinct:
        return ".distinct"
      case .identical:
        return ".identical"
      case .equivalent:
        return ".equivalent"
      }
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceRelationship - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    get {
      switch self {
      case .distinct:
        return "SemanticEquivalenceRelationship.distinct"
      case .identical:
        return "SemanticEquivalenceRelationship.identical"
      case .equivalent:
        return "SemanticEquivalenceRelationship.equivalent"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceRelationship - Codable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship : Codable {
  
  // synthesized ok
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceRelationship - CaseIterable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceRelationship : CaseIterable {
  
  public typealias AllCases = [SemanticEquivalenceRelationship]
  
  public static let allCases: AllCases = [
    .distinct,
    .identical,
    .equivalent
  ]
  
}
