public protocol SemanticItemIdentifiable<SemanticItem, EquivalencePriority> {
  associatedtype SemanticItem: Hashable
  associatedtype EquivalencePriority: Comparable

  var semanticItemIdentifier: SemanticItemIdentifier<SemanticItem, EquivalencePriority> { get }
}

extension SemanticEquivalenceClassIdentifierProviding
where
  Self: SemanticItemIdentifiable,
  SemanticEquivalenceClassIdentifier == SemanticItem
{

  @inlinable
  public var semanticEquivalenceClassIdentifier: SemanticEquivalenceClassIdentifier {
    semanticItemIdentifier.semanticItem
  }

}

extension SemanticEquivalenceComparable where Self: SemanticItemIdentifiable {

  @inlinable
  public static func <~> (
    lhs: Self,
    rhs: Self
  ) -> SemanticEquivalenceComparisonResult {
    lhs.semanticItemIdentifier <~> rhs.semanticItemIdentifier
  }

}
