//
//  SemanticEquivalenceTableEntry.swift
//

import Foundation
import HDXLCommonUtilities

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
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
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

extension SemanticEquivalenceTableEntry : Validatable {
  
  @inlinable
  internal var isValid: Bool {
    get {
      guard
        !self.equivalenceClasses.isEmpty,
        self.equivalenceClasses.allElementsAreValidOrIndifferent,
        self.equivalenceClasses.allSatisfy({$0.semanticEquivalenceClassIdentifier == self.semanticEquivalenceClassIdentifier}) else {
        return false
      }
      return true
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTableEntry - Support
// -------------------------------------------------------------------------- //

internal extension SemanticEquivalenceTableEntry {
  
  /// `true` iff any equivalence class in `self` contains `element`.
  @inlinable
  func contains(element: Element) -> Bool {
    guard element.semanticEquivalenceClassIdentifier == self.semanticEquivalenceClassIdentifier else {
      return false
    }
    for equivalenceClass in self.equivalenceClasses where equivalenceClass.contains(element: element) {
      return true
    }
    return false
  }
  
  /// Returns the reference element of the equivalence class for `element`, or
  /// `nil` if no such element can be found.
  @inlinable
  func referenceElement(forElement element: Element) -> Element? {
    guard element.semanticEquivalenceClassIdentifier == self.semanticEquivalenceClassIdentifier else {
      return nil
    }
    for equivalenceClass in self.equivalenceClasses where equivalenceClass.contains(element: element) {
      return equivalenceClass.referenceElement
    }
    return nil
  }
  
  @inlinable
  func equivalenceClass(forElement element: Element) -> EquivalenceClass? {
    guard element.semanticEquivalenceClassIdentifier == self.semanticEquivalenceClassIdentifier else {
      return nil
    }
    for equivalenceClass in self.equivalenceClasses where equivalenceClass.contains(element: element) {
      return equivalenceClass
    }
    return nil
  }
  
  /// Incorporates `element` into `self`, by either (a) adding it to a pre-existing
  /// equivalence-class or (b) establishing an equivalence class for `self`.
  @inlinable
  mutating func incorporate(element: Element) {
    precondition(element.semanticEquivalenceClassIdentifier == self.semanticEquivalenceClassIdentifier)
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    if let indexOfExistingIndexClass = self.equivalenceClasses.firstIndex(where: {$0.shouldInclude(element: element)}) {
      self.equivalenceClasses[indexOfExistingIndexClass].incorporate(
        element: element
      )
    } else {
      self.equivalenceClasses.append(
        EquivalenceClass(
          referenceElement: element
        )
      )
    }
  }

  /// Incorporates `element`, but only if it is a member of an already-known equivalence class.
  @inlinable
  mutating func weaklyIncorporate(element: Element) {
    precondition(element.semanticEquivalenceClassIdentifier == self.semanticEquivalenceClassIdentifier)
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    if let indexOfExistingIndexClass = self.equivalenceClasses.firstIndex(where: {$0.shouldInclude(element: element)}) {
      self.equivalenceClasses[indexOfExistingIndexClass].incorporate(
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
  mutating func unsafe_removeEquivalenceClassesSatisfying(predicate: (EquivalenceClass) -> Bool) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    // note: *unsafe* thus don't *want* any matching `defer{pedantic_assert(self.isValid)}`
    // /////////////////////////////////////////////////////////////////////////
    self.equivalenceClasses.removeAll(
      where: predicate
    )
    return self.equivalenceClasses.isEmpty
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
  mutating func unsafe_removeEquivalenceClassesFailing(predicate: (EquivalenceClass) -> Bool) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    // note: *unsafe* thus don't *want* any matching `defer{pedantic_assert(self.isValid)}`
    // /////////////////////////////////////////////////////////////////////////
    self.equivalenceClasses.removeAll(
      where: {
        !predicate($0)
      }
    )
    return self.equivalenceClasses.isEmpty
  }

}


// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTableEntry - Support - Objects
// -------------------------------------------------------------------------- //

internal extension SemanticEquivalenceTableEntry where Element:AnyObject {

  /// Disjointness-checking vis-a-vis a set-of-objects.
  @inlinable
  func isDisjoint(with elements: ObjectSet<Element>) -> Bool {
    guard !self.equivalenceClasses.isEmpty else {
      return true
    }
    return self.equivalenceClasses.allSatisfy() {
      $0.isDisjoint(with: elements)
    }
  }

  /// Removes entries for any equivalence classes that are disjoint from the *object set* `relevantElements`.
  ///
  /// In other words, if you start with equivalence classes `A`, `B`, and `C`,
  /// with members like `[a1, a2, ..., am]`, `[b1, b2, ... , bn]`, and `[c1, c2, ..., ck]`,
  /// with `relevantElements` like `[b1, d2]`, the result of this call will be:
  ///
  /// - `A` is discarded b/c it is disjoint-with `relevantElements`
  /// - `B` is preserved as-is (b/c it has `b1` in-common-with `relevantElements`)
  /// - `C` is discarded b/c it is disjoint-with `relevantElements`
  ///
  /// The point I'm trying to make, in other words, is that we keep-or-discard
  /// equivalence classes, but we don't *modify their contents*.
  ///
  /// The reason this exists, incidentally, is that e.g. when working with `CoreData`
  /// the sequence of operations can look like this:
  ///
  ///   1. get a "change digest" providing a set of modified objects (inserted/updated/deleted, etc.)
  ///   2. extract the set of equivalence-class *identifiers* from that modified-object set
  ///   3. fetch *all objects* with identifiers from that set of "relevant identifiers"
  ///   4. build an equivalence table for all of those fetched objects
  ///   5. strip out any equivalence classes that have zero overlap with the objects from step (1)
  ///
  /// ...with step (5) motivated by potential over-fetching in (4), and this method
  /// existing *in support* of step (4).
  ///
  /// - note: Use of `ObjectSet` is a deliberate belt-and-suspenders decision, here; the *premise* of the semantic-equivalence system is "elements that are `!=` but still *equivalent*". `Set<Element>` thus should work, too, but I'm just playing it extra-safe, here.
  /// - warning: When `true` is returned, you must immediately either (a) discard this entry or (b) repopulate the entry; entries *cannot* be empty once "at rest".
  ///
  @inlinable
  mutating func unsafe_prune(preservingOnlyThoseIntersecting relevantElements: ObjectSet<Element>) -> Bool {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    // note: *unsafe* thus don't *want* any matching `defer{pedantic_assert(self.isValid)}`
    // /////////////////////////////////////////////////////////////////////////
    guard !relevantElements.isEmpty else {
      self.equivalenceClasses.removeAll()
      return true
    }
    return self.unsafe_removeEquivalenceClassesSatisfying() {
      return $0.isDisjoint(with: relevantElements)
    }
  }

}
