import Foundation

// note: might add methods to check all elements are "equivalent-and-favored/equivalent-and-unfavored"
// vis-a-vis a reference element, or that elements are equivalent and arranged
// in order of ascending/descending favorability.
//
// Haven't needed them yet, but they're anticipatable...haven't done so, yet,
// because the names would be awkward.

extension Collection where Element:SemanticEquivalenceComparable {
  
  /// `true` iff all elements in `self` have *equivalent* semantics to each other.
  @inlinable
  public func allElementsHaveEquivalentSemantics() -> Bool {
    guard let firstElement = first else {
      return true
    }
    return lazy.dropFirst().allSatisfy() {
      firstElement.hasEquivalentSemantics(to: $0)
    }
  }
  
  /// `true` iff all elements in `self` have *equivalent* semantics to `self`.
  @inlinable
  func allElementsHaveSemantics(equivalentTo element: Element) -> Bool {
    allSatisfy() {
      element.hasEquivalentSemantics(to: $0)
    }
  }
    
}
