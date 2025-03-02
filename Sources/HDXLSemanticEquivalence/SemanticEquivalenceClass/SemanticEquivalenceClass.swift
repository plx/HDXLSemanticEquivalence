import Foundation

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
public struct SemanticEquivalenceClass<Element>
where Element: SemanticEquivalenceClassIdentifierConvertible
{

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
    _referenceElement
  }
  
  /// The *equivalent elements* will always consist of "all elements *other than* the `referenceElement`,
  /// arranged from least-to-most favored.
  @inlinable
  public var equivalentElements: [Element] {
    _equivalentElements
  }
  
  // ------------------------------------------------------------------------ //
  // MARK: Initialization
  // ------------------------------------------------------------------------ //

  /// Construct an equivalence class from an initial reference element.
  @inlinable
  public init(
    referenceElement: Element
  ) {
    #if HEAVY_DEBUG
    defer { pedantic_assert(isValid) }
    #endif
    self._referenceElement = referenceElement
    self._equivalentElements = []
  }
  
  @inlinable
  internal init(
    referenceElement: Element,
    equivalentElements: [Element]
  ) {
#if HEAVY_DEBUG
    defer { pedantic_assert(isValid) }
#endif
    self._referenceElement = referenceElement
    self._equivalentElements = equivalentElements
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Support
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass {
  
  /// The (common) `SemanticEquivalenceClassIdentifier` for this equivalence class.
  @inlinable
  public var semanticEquivalenceClassIdentifier: Identifier {
    referenceElement.semanticEquivalenceClassIdentifier
  }
  
  /// Count of all elements within `self` (e.g. count *including* the reference element *and* the equivalent elements).
  @inlinable
  public var elementCount: Int {
    1 + equivalentElementCount
  }
  
  /// Count of the *equivalent elements* (e.g. count *without* the reference element).
  @inlinable
  public var equivalentElementCount: Int {
    equivalentElements.count
  }
  
  /// `true` iff this equivalence class contains more than just the reference element.
  @inlinable
  public var containsMultipleRepresentations: Bool {
    !equivalentElements.isEmpty
  }
  
  /// `true` iff this equivalence class contains `element`.
  @inlinable
  public func contains(element: Element) -> Bool {
    referenceElement == element
    ||
    equivalentElements.contains(element)
  }
  
  /// Returns the least-favored element within `self`.
  @inlinable
  public var leastFavoredElement: Element {
    equivalentElements.first ?? referenceElement
  }
  
  /// Returns the most-favored element within `self`.
  @inlinable
  public var mostFavoredElement: Element {
    referenceElement
  }
  
  /// `true` iff the members of this equivalence class have semantics distinct
  /// from those of `equivalenceClass`. Note that when all invariants have been
  /// properly-maintained, all elements within `self` will have equivalent
  /// semantics with each other and all elements within `equivalenceClass` will
  /// have equivalent semantics with each other; if that holds, comparing the
  /// semantics of the reference elements suffices for comparing the semantics of
  /// the equivalence classes.
  @inlinable
  public func hasDistinctSemantics(
    from equivalenceClass: SemanticEquivalenceClass<Element>
  ) -> Bool {
    #if HEAVY_DEBUG
    pedantic_assert(equivalenceClass.isValid)
    pedantic_assert(isValid)
    #endif
    return !referenceElement.hasEquivalentSemantics(to: equivalenceClass.referenceElement)
  }
  
  /// `true` iff there is no elementwise-intersection between `self` and `equivalenceClass`.
  ///
  /// - note: The implementation expects the invariants to be upheld, and won't work if they aren't.
  @inlinable
  public func isDisjoint(
    with equivalenceClass: SemanticEquivalenceClass<Element>
  ) -> Bool {
    #if HEAVY_DEBUG
    pedantic_assert(equivalenceClass.isValid)
    pedantic_assert(isValid)
    #endif
    // first pre-flight sanity checks:
    guard
      semanticEquivalenceClassIdentifier == equivalenceClass.semanticEquivalenceClassIdentifier,
      referenceElement.hasEquivalentSemantics(to: equivalenceClass.referenceElement) 
    else {
      return true
    }
    // identical reference elements mean we're done:
    guard referenceElement != equivalenceClass.referenceElement else {
      return false
    }
    switch (equivalentElements.isEmpty, equivalenceClass.equivalentElements.isEmpty) {
    case (true,true):
      // no alternates, distinct semantics for reference elements, so we're done
      return true
    case (false,true):
      // self has alternates, other doesn't, one last check:
      return !equivalentElements.contains(equivalenceClass.referenceElement)
    case (true,false):
      // other has alternates, self doesn't, one last check:
      return !equivalenceClass.equivalentElements.contains(referenceElement)
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
        !leastFavoredElement.shouldBeFavored(
          over: equivalenceClass.mostFavoredElement
        ),
        !equivalenceClass.leastFavoredElement.shouldBeFavored(
          over: mostFavoredElement
        )
      else {
        return true
      }
      // with that out of the way, we check disjointness; first check is
      // for disjointness of the reference element:
      guard
        !equivalentElements.contains(equivalenceClass.referenceElement),
        !equivalenceClass.equivalentElements.contains(referenceElement)
      else {
        return false
      }
      // then we go item-by-item from `smallerClass` to `largerClass`:
      let (smallerClass,largerClass) = projectedAscendingArrangement(self, equivalenceClass) {
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
    referenceElement.hasEquivalentSemantics(to: element)
  }
  
  /// Updates `self` by incorporating `element`.
  ///
  /// - precondition: `self.shouldInclude(element: element)`.
  ///
  @inlinable
  internal mutating func incorporate(element: Element) {
    precondition(referenceElement.hasEquivalentSemantics(to: element))
    #if HEAVY_DEBUG
    pedantic_assert(isValid)
    defer { pedantic_assert(isValid) }
    #endif
    guard !contains(element: element) else {
      return
    }
    switch element.shouldBeFavored(over: referenceElement) {
    case true:
      _equivalentElements.append(referenceElement)
      _referenceElement = element
    case false:
      if let firstDisfavoredIndex = equivalentElements.firstIndex(where: { !element.shouldBeFavored(over: $0)}) {
        _equivalentElements.insert(
          element,
          at: firstDisfavoredIndex
        )
      } else {
        _equivalentElements.append(element)
      }
    }
  }
  
  /// "Safely incorporate" an `element` that may or may not actually-belong in `self`.
  @inlinable
  public mutating func weaklyIncorporate(element: Element) {
    #if HEAVY_DEBUG
    pedantic_assert(isValid)
    defer { pedantic_assert(isValid) }
    #endif
    if shouldInclude(element: element) {
      incorporate(element:
        element
      )
    }
  }
  
  /// "Safely incorporate" `elements` that may or may not actually-belong in `self`.
  @inlinable
  public mutating func weaklyIncorporate(elements: some Sequence<Element>) {
    #if HEAVY_DEBUG
    pedantic_assert(isValid)
    defer { pedantic_assert(isValid) }
    #endif
    for element in elements {
      weaklyIncorporate(
        element: element
      )
    }
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceClass - Validatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass {
  
  @usableFromInline
  internal var isValid: Bool {
    guard
      !equivalentElements.contains(referenceElement),
      equivalentElements.allSatisfy({referenceElement.semanticEquivalenceClassIdentifier == $0.semanticEquivalenceClassIdentifier}),
      equivalentElements.allSatisfy({referenceElement.hasEquivalentSemantics(to: $0)}),
      equivalentElements.allSatisfy({referenceElement.shouldBeFavored(over: $0)}),
      hasMaintainedPreferenceOrdering() 
    else {
      return false
    }
    return true
  }
  
  /// This is an O(n^2) algorithm *but that's ok* b/c (a) we only use it (much)
  /// in heavy debug builds and (b) we want to find the errors it catches!
  @usableFromInline
  internal func hasMaintainedPreferenceOrdering() -> Bool {
    guard equivalentElements.count >= 2 else {
      return true
    }
    // note: if you trust the implementation of the favorability comparison,
    // then we can do `for (lessFavored,moreFavored) in self.equivalentElements.adjacentPairs()`,
    // but for now I'm doing *all* comparisons to help shake out potential favorability bugs.
    for upperIndex in 1..<equivalentElements.count {
      // yeah, yeah, enumerated().dropFirst() could work but keep it easy:
      let favoredElement = equivalentElements[upperIndex]
      for lowerIndex in 0..<upperIndex {
        let unfavoredElement = equivalentElements[lowerIndex]
        guard favoredElement.shouldBeFavored(over: unfavoredElement) else {
          return false
        }
      }
    }
    return true
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Synthesized Conformances
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : Sendable where Element: Sendable { }
extension SemanticEquivalenceClass : Equatable { }
extension SemanticEquivalenceClass : Hashable where Element: Hashable { }
extension SemanticEquivalenceClass : Encodable where Element: Encodable { }
extension SemanticEquivalenceClass : Decodable where Element: Decodable { }

// -------------------------------------------------------------------------- //
// MARK: - Identifiable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : Identifiable {
  public typealias ID = Identifier
  
  @inlinable
  public var id: ID { referenceElement.semanticEquivalenceClassIdentifier }
}

// -------------------------------------------------------------------------- //
// MARK: - CustomStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : CustomStringConvertible {
  
  @inlinable
  public var description: String {
    "class `\(String(describing: semanticEquivalenceClassIdentifier))` w/reference \(String(describing: referenceElement)) and \(equivalentElements.count) equivalent representations"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - CustomDebugStringConvertible
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass : CustomDebugStringConvertible {
  
  @inlinable
  public var debugDescription: String {
    let elementDebugDescriptions = equivalentElements
      .lazy
      .map { String(reflecting: $0) }
      .joined(separator: ", ")
    
    return "SemanticEquivalenceClass<\(String(reflecting: Element.self))>(referenceElement: \(String(reflecting: referenceElement)), equivalentElements: [ \(elementDebugDescriptions) ])"
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: - Element-Exposure
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceClass {
    
  /// Returns all elements in `self`, arranged least-to-most favored.
  ///
  /// - todo: use `some Collection` once I can suitably constrain with a `where` clause.
  @inlinable
  public var equivalenceClassElements: some Collection<Element> {
    // TODO: consider dropping in a "caboose-collection" use once collections library is revamped
    var result = equivalentElements
    result.append(referenceElement)
    return result
  }
   
}
