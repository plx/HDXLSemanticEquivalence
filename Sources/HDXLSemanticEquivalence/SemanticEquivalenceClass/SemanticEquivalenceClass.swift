//
//  SemanticEquivalenceClass.swift
//

import Foundation
import HDXLCommonUtilities
import HDXLAlgebraicUtilities

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Definition
// -------------------------------------------------------------------------- //

/// Structure containing:
///
/// 1. a reference element for the equivalence class
/// 2. zero or more *other* representatives of said equivalence class
///
/// ...maintaining the invariants that (a) the reference element is always the
/// most-preferred (known) representation for the class and (b) the collection
/// of other elements is kept sorted least-to-most favored.
///
/// The constructor and the mutating operations are kept internal-use only b/c
/// I don't see a way to expose them usefully (and they're rather special-purpose
/// vis-a-vis use with `SemanticEquivalenceTable`). That could change, someday.
///
public struct SemanticEquivalenceClass<Element:SemanticEquivalenceClassIdentifierConvertible> {

  public typealias Identifier = Element.SemanticEquivalenceClassIdentifier
  
  @usableFromInline
  internal var _referenceElement: Element
  
  @usableFromInline
  internal var _equivalentElements: [Element]
  
  // ------------------------------------------------------------------------ //
  // MARK: Exposed Properties
  // ------------------------------------------------------------------------ //
  
  /// The *reference element* will always be equivalence class's most-favored element.
  @inlinable
  public var referenceElement: Element {
    get {
      return self._referenceElement
    }
  }
  
  /// The *equivalent elements* will always consist of "all elements *other than* the `referenceElement`,
  /// arranged from least-to-most favored.
  @inlinable
  public var equivalentElements: [Element] {
    get {
      return self._equivalentElements
    }
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: Initialization
  // ------------------------------------------------------------------------ //

  /// Construct an equivalence class from an initial reference element.
  @inlinable
  public init(
    referenceElement: Element) {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self._referenceElement = referenceElement
    self._equivalentElements = []
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Support
// -------------------------------------------------------------------------- //

public extension SemanticEquivalenceClass {
  
  /// The (common) `SemanticEquivalenceClassIdentifier` for this equivalence class.
  @inlinable
  var semanticEquivalenceClassIdentifier: Identifier {
    get {
      return self.referenceElement.semanticEquivalenceClassIdentifier
    }
  }
  
  /// Count of all elements within `self` (e.g. count *including* the reference element *and* the equivalent elements).
  @inlinable
  var elementCount: Int {
    get {
      return 1 + self.equivalentElementCount
    }
  }
  
  /// Count of the *equivalent elements* (e.g. count *without* the reference element).
  @inlinable
  var equivalentElementCount: Int {
    get {
      return self.equivalentElements.count
    }
  }
  
  /// `true` iff this equivalence class contains more than just the reference element.
  @inlinable
  var containsMultipleRepresentations: Bool {
    get {
      return !self.equivalentElements.isEmpty
    }
  }
  
  /// `true` iff this equivalence class contains `element`.
  @inlinable
  func contains(element: Element) -> Bool {
    guard self.referenceElement != element else {
      return true
    }
    return self.equivalentElements.contains(
      element
    )
  }
  
  /// Returns the least-favored element within `self`.
  @inlinable
  var leastFavoredElement: Element {
    get {
      return self.equivalentElements.first ?? self.referenceElement
    }
  }
  
  /// Returns the most-favored element within `self`.
  @inlinable
  var mostFavoredElement: Element {
    get {
      return self.referenceElement
    }
  }
  
  /// `true` iff the members of this equivalence class have semantics distinct
  /// from those of `equivalenceClass`. Note that when all invariants have been
  /// properly-maintained, all elements within `self` will have equivalent
  /// semantics with each other and all elements within `equivalenceClass` will
  /// have equivalent semantics with each other; if that holds, comparing the
  /// semantics of the reference elements suffices for comparing the semantics of
  /// the equivalence classes.
  @inlinable
  func hasDistinctSemantics(from equivalenceClass: SemanticEquivalenceClass<Element>) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(equivalenceClass.isValid)
    pedantic_assert(self.isValid)
    // /////////////////////////////////////////////////////////////////////////
    return !self.referenceElement.hasEquivalentSemantics(to: equivalenceClass.referenceElement)
  }
  
  /// `true` iff there is no elementwise-intersection between `self` and `equivalenceClass`.
  ///
  /// - note: The implementation expects the invariants to be upheld, and won't work if they aren't.
  @inlinable
  func isDisjoint(with equivalenceClass: SemanticEquivalenceClass<Element>) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(equivalenceClass.isValid)
    pedantic_assert(self.isValid)
    // /////////////////////////////////////////////////////////////////////////
    // first pre-flight sanity checks:
    guard
      self.semanticEquivalenceClassIdentifier == equivalenceClass.semanticEquivalenceClassIdentifier,
      self.referenceElement.hasEquivalentSemantics(to: equivalenceClass.referenceElement) else {
        return true
    }
    // identical reference elements mean we're done:
    guard self.referenceElement != equivalenceClass.referenceElement else {
        return false
    }
    switch (self.equivalentElements.isEmpty,equivalenceClass.equivalentElements.isEmpty) {
    case (true,true):
      // no alternates, distinct semantics for reference elements, so we're done
      return true
    case (false,true):
      // self has alternates, other doesn't, one last check:
      return !self.equivalentElements.contains(equivalenceClass.referenceElement)
    case (true,false):
      // other has alternates, self doesn't, one last check:
      return !equivalenceClass.equivalentElements.contains(self.referenceElement)
    case (false,false):
      // both have alternates, so we have work to do.
      // First, keeping our equivalents arranged ascending from least-to-most
      // favored means that we can quickly detect disjointness by seeing if our
      // equivalent classes *can't* overlap b/c everything in one is favored
      // over everything in the other.
      //
      // In pictures, say, if one has favorabilities `([1,2,3,4,5],6)` and the
      // other has favorabilities `([10,11,12,13,14,15],16)`, then we can quickly
      // see that `6 < 10`--"most-favored in one is less-favored than least-favored
      // in the other"--and determine we *must* be disjoint.
      guard
        !self.leastFavoredElement.shouldBeFavored(over: equivalenceClass.mostFavoredElement),
        !equivalenceClass.leastFavoredElement.shouldBeFavored(over: self.mostFavoredElement) else {
          return true
      }
      // with that out of the way, we check disjointness; first check is
      // for disjointness of the reference element:
      guard
        !self.equivalentElements.contains(equivalenceClass.referenceElement),
        !equivalenceClass.equivalentElements.contains(self.referenceElement) else {
          return false
      }
      // then we go item-by-item from `smallerClass` to `largerClass`:
      let (smallerClass,largerClass) = projectedAscendingArrangement(self,equivalenceClass) {
        $0.equivalentElementCount
      }
      for candidate in smallerClass.equivalentElements {
        guard !largerClass.contains(element: candidate) else {
          return false
        }
      }
      return true
      // as a final note, the above can be radically-improved and made linear
      // and I may return here to do exactly that if performance becomes a bottleneck;
      // I *haven't* b/c, honestly, it's been rare for individual classes to have
      // even 3 total members in them in my use cases, making even the above logic
      // arguably overkill (when evaluated in "is it likely to be buggy vs speedup potential".
      //
      // To make it *linear* (I think, better than O(n^2) for sure though) the
      // trick is to do a joint, simultaneous iteration over both classes, basically
      // like so:
      //
      // - have `xIterator, yIterator` from `self` and `other`
      // - get current `x` and `y` from them (early-exit if either returns `nil`)
      // - check for `x` and `y` equivalence relation:
      //   - if `x` and `y` are distinct, we have a precondition failure!
      //   - if `x` and `y` are identical, we conclude non-disjointness
      //   - if `x` favored over `y`, get next `y` (early exit if no more `y`)
      //   - if `y` favored over `x`, get next `x` (early exit if no more `x`)
      //
      // ...which works b/c basically to show non-disjointness we need a match,
      // and matching implies equal favorability; if we visit elements in order
      // of ever-increasing favorability we can then see "which side needs to
      // catch up" at each step, iterate appropriately, and either find a match
      // or conclude no match is found.
    }
  }

  /// Returns `true` iff `self` *should incorporate* `element`.
  ///
  /// - note: Have considered merging this with `incorporate(element:)` but keeping it distinct for now.
  ///
  @inlinable
  internal func shouldInclude(element: Element) -> Bool {
    return self.referenceElement.hasEquivalentSemantics(to: element)
  }
  
  /// Updates `self` by incorporating `element`.
  ///
  /// - precondition: `self.shouldInclude(element: element)`.
  ///
  @inlinable
  internal mutating func incorporate(element: Element) {
    precondition(self.referenceElement.hasEquivalentSemantics(to: element))
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    guard !self.contains(element: element) else {
      return
    }
    switch element.shouldBeFavored(over: self.referenceElement) {
    case true:
      self._equivalentElements.append(self.referenceElement)
      self._referenceElement = element
    case false:
      if let firstDisfavoredIndex = self.equivalentElements.firstIndex(where: { !element.shouldBeFavored(over: $0)}) {
        self._equivalentElements.insert(
          element,
          at: firstDisfavoredIndex
        )
      } else {
        self._equivalentElements.append(element)
      }
    }
  }
  
  /// "Safely incorporate" an `element` that may or may not actually-belong in `self`.
  @inlinable
  mutating func weaklyIncorporate(element: Element) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    if self.shouldInclude(element: element) {
      self.incorporate(element:
        element
      )
    }
  }
  
  /// "Safely incorporate" `elements` that may or may not actually-belong in `self`.
  @inlinable
  mutating func weaklyIncorporate<S>(elements: S)
    where
    S:Sequence,
    S.Element == Element {
      // ///////////////////////////////////////////////////////////////////////
      pedantic_assert(self.isValid)
      defer { pedantic_assert(self.isValid) }
      // ///////////////////////////////////////////////////////////////////////
      for element in elements {
        self.weaklyIncorporate(
          element: element
        )
      }
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Support - Objects
// -------------------------------------------------------------------------- //

internal extension SemanticEquivalenceClass where Element:AnyObject {
  
  /// Returns `true` iff `self` is disjoint with the *objects* contained in `objects`.
  ///
  /// - note: Special case for objects; motivated for use with `CoreData`.
  ///
  @inlinable
  func isDisjoint(with objects: ObjectSet<Element>) -> Bool {
    guard
      !objects.contains(self.referenceElement),
      objects.isDisjoint(with: self.equivalentElements) else {
        return false
    }
    return true
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Validatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : Validatable {
  
  @inlinable
  public var isValid: Bool {
    get {
      guard
        isValidOrIndifferent(self.referenceElement),
        self.equivalentElements.allElementsAreValidOrIndifferent,
        !self.equivalentElements.contains(self.referenceElement),
        self.equivalentElements.allSatisfy({self.referenceElement.semanticEquivalenceClassIdentifier == $0.semanticEquivalenceClassIdentifier}),
        self.equivalentElements.allSatisfy({self.referenceElement.hasEquivalentSemantics(to: $0)}),
        self.equivalentElements.allSatisfy({self.referenceElement.shouldBeFavored(over: $0)}),
        self.hasMaintainedPreferenceOrdering() else {
          return false
      }
      return true
    }
  }
  
  /// This is an O(n^2) algorithm *but that's ok* b/c (a) we only use it (much)
  /// in heavy debug builds and (b) we want to find the errors it catches!
  @inlinable
  internal func hasMaintainedPreferenceOrdering() -> Bool {
    guard self.equivalentElements.count >= 2 else {
      return true
    }
    // note: if you trust the implementation of the favorability comparison,
    // then we can do `for (lessFavored,moreFavored) in self.equivalentElements.adjacentPairs()`,
    // but for now I'm doing *all* comparisons to help shake out potential favorability bugs.
    for upperIndex in 1..<self.equivalentElements.count {
      // yeah, yeah, enumerated().dropFirst() could work but keep it easy:
      let favoredElement = self.equivalentElements[upperIndex]
      for lowerIndex in 0..<upperIndex {
        let unfavoredElement = self.equivalentElements[lowerIndex]
        guard favoredElement.shouldBeFavored(over: unfavoredElement) else {
          return false
        }
      }
    }
    return true
  }
  
}


// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Equatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : Equatable {
  
  @inlinable
  public static func ==(
    lhs: SemanticEquivalenceClass<Element>,
    rhs: SemanticEquivalenceClass<Element>) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    // note: below *won't work* unless the invariants are maintained correctly!
    guard
      lhs.referenceElement == rhs.referenceElement,
      lhs.equivalentElements == rhs.equivalentElements else {
        return false
    }
    return true
  }

  @inlinable
  public static func !=(
    lhs: SemanticEquivalenceClass<Element>,
    rhs: SemanticEquivalenceClass<Element>) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(lhs.isValid)
    pedantic_assert(rhs.isValid)
    // /////////////////////////////////////////////////////////////////////////
    // note: below *won't work* unless the invariants are maintained correctly!
    guard
      lhs.referenceElement == rhs.referenceElement,
      lhs.equivalentElements == rhs.equivalentElements else {
        return true
    }
    return false
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Hashable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : Hashable {
  
  @inlinable
  public func hash(into hasher: inout Hasher) {
    self.semanticEquivalenceClassIdentifier.hash(into: &hasher)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : CustomStringConvertible {
  
  @inlinable
  public var description: String {
    get {
      return "class `\(String(describing: self.semanticEquivalenceClassIdentifier))` w/reference \(String(describing: self.referenceElement)) and \(self.equivalentElements.count) equivalent representations"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    get {
      return "SemanticEquivalenceClass<\(String(reflecting: Element.self))>(referenceElement: \(String(reflecting: self.referenceElement)), equivalentElements: \(self.equivalentElements.arrayLikeElementDebugDescriptions()))"
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Codable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : Codable where Element:Codable {
  
  // synthesized ok
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Element-Exposure
// -------------------------------------------------------------------------- //

public extension SemanticEquivalenceClass {
  
  typealias Elements = Chain2Collection<[Element],CollectionOfOne<Element>>
  
  /// Returns all elements in `self`, arranged least-to-most favored.
  ///
  /// - todo: use `some Collection` once I can suitably constrain with a `where` clause.
  @inlinable
  var equivalenceClassElements: Elements {
    get {
      return Chain2Collection<[Element],CollectionOfOne<Element>>(
        self.equivalentElements,
        CollectionOfOne<Element>(self.referenceElement)
      )
    }
  }
   
}
