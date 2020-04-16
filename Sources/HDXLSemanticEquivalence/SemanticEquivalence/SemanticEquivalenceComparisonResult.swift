//
//  SemanticEquivalenceComparison.swift
//

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

public extension SemanticEquivalenceComparisonResult {

  /// `true` iff `self` implies the compared values are semantically-distinct.
  @inlinable
  var impliesDistinctness: Bool {
    get {
      switch self {
      case .distinct:
        return true
      case .identical:
        return false
      case .equivalentPreferLHS:
        return false
      case .equivalentPreferRHS:
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
      case .equivalentPreferLHS:
        return true
      case .equivalentPreferRHS:
        return true
      }
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceComparisonResult - Equatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : Equatable {
  
  @inlinable
  public static func ==(
    lhs: SemanticEquivalenceComparisonResult,
    rhs: SemanticEquivalenceComparisonResult) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  @inlinable
  public static func !=(
    lhs: SemanticEquivalenceComparisonResult,
    rhs: SemanticEquivalenceComparisonResult) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceComparisonResult - Hashable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : Hashable {
  
  @inlinable
  public func hash(into hasher: inout Hasher) {
    self.rawValue.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceComparisonResult - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : CustomStringConvertible {

  @inlinable
  public var description: String {
    get {
      switch self {
      case .distinct:
        return ".distinct"
      case .identical:
        return ".identical"
      case .equivalentPreferLHS:
        return ".equivalentPreferLHS"
      case .equivalentPreferRHS:
        return ".equivalentPreferRHS"
      }
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceComparisonResult - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    get {
      switch self {
      case .distinct:
        return "SemanticEquivalenceComparisonResult.distinct"
      case .identical:
        return "SemanticEquivalenceComparisonResult.identical"
      case .equivalentPreferLHS:
        return "SemanticEquivalenceComparisonResult.equivalentPreferLHS"
      case .equivalentPreferRHS:
        return "SemanticEquivalenceComparisonResult.equivalentPreferRHS"
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceComparisonResult - Codable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : Codable {
  
  // synthesized ok
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceComparisonResult - CaseIterable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceComparisonResult : CaseIterable {
  
  public typealias AllCases = [SemanticEquivalenceComparisonResult]
  
  public static let allCases: AllCases = [
    .distinct,
    .identical,
    .equivalentPreferLHS,
    .equivalentPreferRHS
  ]
  
}
