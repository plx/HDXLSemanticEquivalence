import Foundation

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClassIdentifierConvertible - Definition
// -------------------------------------------------------------------------- //

/// `SemanticEquivalenceClassIdentifierConvertible` can be adopted by types that can provide some
/// sort of a "rich `hashValue`" with the semantics familiar to all hashes:
///
/// - *equivalent* values must have *identical* `semanticDigest` values
/// - *identical* `semanticDigest` values need *not* imply *equivalence*
///
/// Moreover, in the same way that hashes need not incorporate all of the fields
/// relevant for `==`, a `semanticDigest` need not incorporate all of the fields
/// relevant for semantic equivalance--it can incorporate only a subset of them
/// for, say, efficiency's sake.
///
/// Finally, note that `SemanticEquivalenceClassIdentifier` need only be `Hashable`,
/// and thus can be some structured, composite type--e.g. a struct with a subset of
/// the fields--rather than, say, *requiring* digesting everything down to a `String`
/// or an `Int` or whatever.
///
/// This is a deliberate choice meant to make it easy to get *stable* identifiers
/// from our data objects; e.g. for a CoreData type a struct equivalent-to `(String,String,URL)`
/// would be easier to get correct than, say, getting consistent strings out of
/// some combination of the values.
/// 
public protocol SemanticEquivalenceClassIdentifierConvertible : SemanticEquivalenceComparable {

  /// The type of the equivalence-class identifier.
  associatedtype SemanticEquivalenceClassIdentifier: Hashable
  
  /// The equivalence-class identifier for `self`.
  ///
  /// - note: Not guaranteed to remain stable between mutations of `self` (should be obvious, but just sayin').
  ///
  var semanticEquivalenceClassIdentifier: SemanticEquivalenceClassIdentifier { get }
  
}
