public struct SemanticItemIdentifier<SemanticItem, EquivalencePriority>
where SemanticItem: Hashable, EquivalencePriority: Comparable {

  public var semanticItem: SemanticItem
  public var equivalencePriority: EquivalencePriority

  @inlinable
  public init(
    semanticItem: SemanticItem,
    equivalencePriority: EquivalencePriority
  ) {
    self.semanticItem = semanticItem
    self.equivalencePriority = equivalencePriority
  }
}

extension SemanticItemIdentifier: Sendable
where SemanticItem: Sendable, EquivalencePriority: Sendable {}
extension SemanticItemIdentifier: Equatable
where SemanticItem: Equatable, EquivalencePriority: Equatable {}
extension SemanticItemIdentifier: Hashable
where SemanticItem: Hashable, EquivalencePriority: Hashable {}
extension SemanticItemIdentifier: Encodable
where SemanticItem: Encodable, EquivalencePriority: Encodable {}
extension SemanticItemIdentifier: Decodable
where SemanticItem: Decodable, EquivalencePriority: Decodable {}

extension SemanticItemIdentifier: Identifiable
where SemanticItem: Hashable, EquivalencePriority: Hashable {
  public typealias ID = Self

  @inlinable
  public var id: ID { self }
}

extension SemanticItemIdentifier: CaseIterable
where SemanticItem: CaseIterable, EquivalencePriority: CaseIterable {

  @inlinable
  public static var allCases: [Self] {
    var result: [Self] = []
    let semanticItems = SemanticItem.allCases
    let equivalencePriorities = EquivalencePriority.allCases
    result.reserveCapacity(semanticItems.count * equivalencePriorities.count)
    for semanticItem in semanticItems {
      for equivalencePriority in equivalencePriorities {
        result.append(
          Self(
            semanticItem: semanticItem,
            equivalencePriority: equivalencePriority
          )
        )
      }
    }
    return result
  }
}

extension SemanticItemIdentifier: SemanticEquivalenceComparable {

  @inlinable
  public static func <~> (
    lhs: Self,
    rhs: Self
  ) -> SemanticEquivalenceComparisonResult {
    guard lhs.semanticItem == rhs.semanticItem else {
      return .distinct
    }

    return if lhs.equivalencePriority < rhs.equivalencePriority {
      .equivalentPreferRHS
    } else if lhs.equivalencePriority > rhs.equivalencePriority {
      .equivalentPreferLHS
    } else {
      .identical
    }
  }

}
