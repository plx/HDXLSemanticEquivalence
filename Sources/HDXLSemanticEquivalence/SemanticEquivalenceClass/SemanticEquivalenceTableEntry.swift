import Foundation

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTableEntry - Definition
// -------------------------------------------------------------------------- //

/// `SemanticEquivalenceTableEntry` is used by `SemanticEquivalenceTable` to
/// hold the known equivalence classes for some equivalence-class identifier.
///
/// Recall that, conceptually, `SemanticEquivalenceClassIdentifier` behaves like
/// a hash: truly-equivalent values *must* have the same identifier, but values
/// with the same identifier *may not*, in fact, be equivalent.
///
/// I mention that because values of this type captures what we know about the
/// following question: "what equivalence **classes** do we know of for some specific
/// `semanticEquivalenceClassIdentifier`?"--note the pluralization.
///
/// With that out of the way, note that (a) this is an internal type with and
/// that (b) its implementation isn't that interesting: it wraps an array of
/// equivalence classes, it (generally) ensures the maintenance of certain invariants,
/// it does all that in straightforward ways, and that's really about all there is to see.
///
/// That said, I keep this type an `internal` type because the natural API for
/// fitting it into the rest of the package would be awkward to expose for general,
/// public use. In particular, *in general* this type expects the wrapped array to
/// be non-empty, but this isn't quite right: practical use of the package requires
/// that this type support filtering operations--e.g. operations that *shrink* the
/// contents--which then introduce the possibility of the wrapped array becoming empty.
///
/// The other types in this system make sure that that invariant-violation isn't
/// problematic--all such filtering operations take place in contexts wherein
/// newly-empty entries will be discarded, promptly. Making this type public, however,
/// would either require relaxing those invariants, changing the public API, or
/// increasing the risk of unexpected outcomes (due to "API misuse", so to speak).
///
@usableFromInline
internal struct SemanticEquivalenceTableEntry<Element:SemanticEquivalenceClassIdentifierConvertible> {

  /// Shorthand for the corresponding equivalence-class type.
  @usableFromInline
  internal typealias EquivalenceClass = SemanticEquivalenceClass<Element>
  
  /// Shorthand for the semantic identifier.
  @usableFromInline
  internal typealias Identifier = Element.SemanticEquivalenceClassIdentifier
  
  /// The identifier corresponding to this table entry.
  @usableFromInline
  internal let semanticEquivalenceClassIdentifier: Identifier
  
  /// The identifier corresponding to this table entry.
  @usableFromInline
  internal var equivalenceClasses: [EquivalenceClass]
  
  @inlinable
  internal init(referenceElement: Element) {
#if HEAVY_DEBUG
    defer { pedantic_assert(isValid) }
#endif
    self.semanticEquivalenceClassIdentifier = referenceElement.semanticEquivalenceClassIdentifier
    self.equivalenceClasses = [
      EquivalenceClass(
        referenceElement: referenceElement
      )
    ]
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTableEntry - Validatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTableEntry {
  
  @inlinable
  internal var isValid: Bool {
    guard
      !equivalenceClasses.isEmpty,
      equivalenceClasses.allSatisfy({$0.semanticEquivalenceClassIdentifier == semanticEquivalenceClassIdentifier})
    else {
      return false
    }
    return true
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTableEntry - Support
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTableEntry {
  
  /// `true` iff any equivalence class in `self` contains `element`.
  @inlinable
  internal func contains(element: Element) -> Bool {
    guard element.semanticEquivalenceClassIdentifier == semanticEquivalenceClassIdentifier else {
      return false
    }
    for equivalenceClass in equivalenceClasses where equivalenceClass.contains(element: element) {
      return true
    }
    return false
  }
  
  /// Returns the reference element of the equivalence class for `element`, or
  /// `nil` if no such element can be found.
  @inlinable
  internal func referenceElement(forElement element: Element) -> Element? {
    guard element.semanticEquivalenceClassIdentifier == semanticEquivalenceClassIdentifier else {
      return nil
    }
    for equivalenceClass in equivalenceClasses where equivalenceClass.contains(element: element) {
      return equivalenceClass.referenceElement
    }
    return nil
  }
  
  @inlinable
  internal func equivalenceClass(forElement element: Element) -> EquivalenceClass? {
    guard element.semanticEquivalenceClassIdentifier == semanticEquivalenceClassIdentifier else {
      return nil
    }
    for equivalenceClass in equivalenceClasses where equivalenceClass.contains(element: element) {
      return equivalenceClass
    }
    return nil
  }
  
  /// Incorporates `element` into `self`, by either (a) adding it to a pre-existing
  /// equivalence-class or (b) establishing an equivalence class for `self`.
  @inlinable
  internal mutating func incorporate(element: Element) {
    precondition(element.semanticEquivalenceClassIdentifier == semanticEquivalenceClassIdentifier)
#if HEAVY_DEBUG
    pedantic_assert(isValid)
    defer { pedantic_assert(isValid) }
#endif
    if let indexOfExistingIndexClass = equivalenceClasses.firstIndex(where: {$0.shouldInclude(element: element)}) {
      equivalenceClasses[indexOfExistingIndexClass].incorporate(
        element: element
      )
    } else {
      equivalenceClasses.append(
        EquivalenceClass(
          referenceElement: element
        )
      )
    }
  }

  /// Incorporates `element`, but only if it is a member of an already-known equivalence class.
  @inlinable
  mutating func weaklyIncorporate(element: Element) {
    precondition(element.semanticEquivalenceClassIdentifier == semanticEquivalenceClassIdentifier)
#if HEAVY_DEBUG
    pedantic_assert(isValid)
    defer { pedantic_assert(isValid) }
#endif
    if let indexOfExistingIndexClass = equivalenceClasses.firstIndex(where: {$0.shouldInclude(element: element)}) {
      equivalenceClasses[indexOfExistingIndexClass].incorporate(
        element: element
      )
    }
  }
  
  /// Removes entries for any equivalence classes for-which `predicate` evaluates to `true`.
  ///
  /// - parameter predicate: The predicate for-which *failing* means removal.
  ///
  /// - returns: `true` iff we should remove this entry (b/c it has become empty).
  ///
  /// - todo: Change to a purpose-specific `keep/remove` enumeration instead of `Bool`.
  ///
  @inlinable
  mutating func unsafe_removeEquivalenceClassesSatisfying(
    predicate: (EquivalenceClass) throws -> Bool
  ) rethrows -> Bool {
#if HEAVY_DEBUG
    pedantic_assert(isValid)
    // note: *unsafe* thus don't *want* any matching `defer{pedantic_assert(self.isValid)}`
#endif
    try equivalenceClasses.removeAll(
      where: predicate
    )
    return equivalenceClasses.isEmpty
  }

  /// Removes entries for any equivalence classes for-which `predicate` evaluates to `false`.
  ///
  /// - parameter predicate: The predicate for-which *failing* means removal.
  ///
  /// - returns: `true` iff we should remove this entry (b/c it has become empty).
  ///
  /// - todo: Change to a purpose-specific `keep/remove` enumeration instead of `Bool`.
  ///
  @inlinable
  mutating func unsafe_removeEquivalenceClassesFailing(
    predicate: (EquivalenceClass) throws -> Bool
  ) rethrows -> Bool {
#if HEAVY_DEBUG
    pedantic_assert(isValid)
    // note: *unsafe* thus don't *want* any matching `defer{pedantic_assert(self.isValid)}`
#endif
    try equivalenceClasses.removeAll(
      where: {
        !(try predicate($0))
      }
    )
    return equivalenceClasses.isEmpty
  }

}

