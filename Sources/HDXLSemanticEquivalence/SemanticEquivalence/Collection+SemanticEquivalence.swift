import Foundation

extension Collection where Element:SemanticEquivalenceComparable {
  
  /// `true` iff all elements in `self` have *equivalent* semantics to each other.
  @inlinable
  public func allElementsHaveEquivalentSemantics() -> Bool {
    guard let firstElement = first else {
      return true
    }
    return lazy.dropFirst().allSatisfy {
      firstElement.hasEquivalentSemantics(to: $0)
    }
  }
  
  /// `true` iff all elements in `self` have *equivalent* semantics to `self`.
  @inlinable
  public func allElementsHaveSemantics(equivalentTo element: Element) -> Bool {
    allSatisfy {
      element.hasEquivalentSemantics(to: $0)
    }
  }
    
}
