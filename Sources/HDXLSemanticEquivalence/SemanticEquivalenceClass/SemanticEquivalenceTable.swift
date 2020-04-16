//
//  UniqueableManagedObjectEquivalenceTable.swift
//

import Foundation
import HDXLCommonUtilities

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Definition
// -------------------------------------------------------------------------- //

/// `SemanticEquivalenceTable` exists to organize potentially-equivalent elements
/// into a (collection of) their equivalence classes. Conceptually it is built like
/// a bucketing hash table, except (a) use the `SemanticEquivalenceClassIdentifier`
/// as the "hash" and (b) within our "hash buckets" we store the elements aggregated
/// into their *equivalence classes* (rather than just as individual elements).
///
/// Note that this is built atop `Dictionary` and `Array`, etc.--we aren't building
/// a custom hash table from scratch, there's no need! Also note that this implementation
/// is passably-efficient for the cases I use it for, but I make no guarantees it'll
/// scale to very large sizes; in particular I didn't want to constrain my elements
/// to be `Hashable`, which means I store the elements in `Array` and not `Set`.
///
/// For small numbers of generally-small equivalence classes even linear search
/// is perfectly-reasonable, but if you happened to have large numbers of large
/// equivalence classes this approach would eventually prove unusably-inefficient.
///
/// - todo: Adopt binary search where-appropriate (once I move that into this package).
///
public struct SemanticEquivalenceTable<Element:SemanticEquivalenceClassIdentifierConvertible> {

  public typealias EquivalenceClass = SemanticEquivalenceClass<Element>
  public typealias Identifier = EquivalenceClass.Identifier

  @usableFromInline
  internal typealias TableEntry = SemanticEquivalenceTableEntry<Element>
  
  @usableFromInline
  internal typealias Table = [Identifier:TableEntry]
  
  @usableFromInline
  internal var table: Table
  
  // ------------------------------------------------------------------------ //
  // MARK: Initialization
  // ------------------------------------------------------------------------ //
  
  /// Create an empty equivalence table.
  @inlinable
  public init() {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.table = Table()
  }
  
  /// Create an equivalence table incorporating the elements from `elements`.
  @inlinable
  public init<S:Sequence>(elements: S) where S.Element == Element {
    // /////////////////////////////////////////////////////////////////////////
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    self.init()
    self.incorporate(elements: elements)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Validatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTable : Validatable {
  
  @inlinable
  public var isValid: Bool {
    get {
      return self.table.allValuesAreValid
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Support
// -------------------------------------------------------------------------- //

public extension SemanticEquivalenceTable {
  
  /// Returns all contained `EquivalanceClass` records (in an unspecified order).
  ///
  /// - todo: Change to `some Collection` once I can constrain it appropriately with a `where` clause
  @inlinable
  var equivalenceClasses: AnyCollection<EquivalenceClass> {
    get {
      return AnyCollection<EquivalenceClass>(
        self
          .table
          .values
          .lazy
          .map({ $0.equivalenceClasses })
          .joined()
      )
    }
  }
  
  /// `true` iff `self` has nothing in it.
  @inlinable
  var isEmpty: Bool {
    get {
      return self.table.isEmpty
    }
  }
  
  /// Returns the set of all contained equivalence-class identifiers.
  @inlinable
  var semanticEquivalenceClassIdentifiers: Set<Identifier> {
    get {
      return self.table.keySet
    }
  }
  
  /// Updates `self` by incorporating an additional `element`.
  @inlinable
  mutating func incorporate(element: Element) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
    if let indexOfExistingTableEntry = self.table.index(forKey: semanticEquivalenceClassIdentifier) {
      self.table.values[indexOfExistingTableEntry].incorporate(
        element: element
      )
    } else {
      self.table[semanticEquivalenceClassIdentifier] = TableEntry(
        referenceElement: element
      )
    }
  }

  /// Updates `self` by incorporating an additional `element`, but only if it is
  /// a member of a pre-existing equivalence class.
  @inlinable
  mutating func conditionallyIncorporate(elementWhenEquivalenceClassIsKnown element: Element) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
    if let indexOfExistingTableEntry = self.table.index(forKey: semanticEquivalenceClassIdentifier) {
      self.table.values[indexOfExistingTableEntry].weaklyIncorporate(
        element: element
      )
    }
  }

  /// Updates `self` by incorporating an additional `element`, but only if it is
  /// a member of a pre-existing equivalence class.
  @inlinable
  mutating func conditionallyIncorporate(elementWhenIdentifierIsKnown element: Element) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
    if let indexOfExistingTableEntry = self.table.index(forKey: semanticEquivalenceClassIdentifier) {
      self.table.values[indexOfExistingTableEntry].incorporate(
        element: element
      )
    }
  }

  /// Updates `self` by incorporating each element from `elements`.
  @inlinable
  mutating func incorporate<S:Sequence>(elements: S) where S.Element == Element {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    for element in elements {
      self.incorporate(element: element)
    }
  }

  /// Updates `self` by incorporating each element from `elements`.
  @inlinable
  mutating func conditionallyIncorporate<S:Sequence>(elementsWhenEquivalenceClassIsKnown elements: S) where S.Element == Element {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    for element in elements {
      self.conditionallyIncorporate(
        elementWhenEquivalenceClassIsKnown: element
      )
    }
  }


  /// Updates `self` by incorporating each element from `elements`.
  @inlinable
  mutating func conditionallyIncorporate<S:Sequence>(elementsWhenIdentifierIsKnown elements: S) where S.Element == Element {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    for element in elements {
      self.conditionallyIncorporate(
        elementWhenIdentifierIsKnown: element
      )
    }
  }


  /// Updates `self` by removing all equivalence classes for which `predicate` evaluates to *true*.
  @inlinable
  mutating func removeEquivalenceClassesSatisfying(predicate: (EquivalenceClass) -> Bool) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    guard !self.table.isEmpty else {
      return
    }
    for identifier in self.table.keySet {
      guard let indexForIdentifier = self.table.index(forKey: identifier) else {
        continue
      }
      let becameEmpty = self.table.values[indexForIdentifier].unsafe_removeEquivalenceClassesSatisfying(
        predicate: predicate
      )
      if becameEmpty {
        self.table.removeValue(
          forKey: identifier
        )
      }
    }
  }

  /// Updates `self` by removing all equivalence classes for which `predicate` evaluates to *false*.
  @inlinable
  mutating func removeEquivalenceClassesFailing(predicate: (EquivalenceClass) -> Bool) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    // /////////////////////////////////////////////////////////////////////////
    guard !self.table.isEmpty else {
      return
    }
    for identifier in self.table.keySet {
      guard let indexForIdentifier = self.table.index(forKey: identifier) else {
        continue
      }
      let becameEmpty = self.table.values[indexForIdentifier].unsafe_removeEquivalenceClassesFailing(
        predicate: predicate
      )
      if becameEmpty {
        self.table.removeValue(
          forKey: identifier
        )
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Queries
// -------------------------------------------------------------------------- //

public extension SemanticEquivalenceTable {
  
  /// Returns `true` iff the table contains `element`.
  @inlinable
  func contains(element: Element) -> Bool {
    return self
      .table[element.semanticEquivalenceClassIdentifier]?
      .contains(
        element: element
    ) ?? false
  }
  
  /// Returns the current reference element semantically-equivalent to `element`,
  /// or `nil` if no such element exists.
  @inlinable
  func referenceElement(forElement element: Element) -> Element? {
    return self
      .table[element.semanticEquivalenceClassIdentifier]?
      .referenceElement(
        forElement: element
    )
  }
  
  @inlinable
  func equivalenceClass(forElement element: Element) -> EquivalenceClass? {
    return self
      .table[element.semanticEquivalenceClassIdentifier]?
      .equivalenceClass(
        forElement: element
    )
  }
  
}


// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Pruning
// -------------------------------------------------------------------------- //

public extension SemanticEquivalenceTable where Element:AnyObject {

  /// In-place mutates `self` by pruning it down to *only* those equivalence
  /// classes that have at least one object in common with `relevantElements`.
  ///
  /// Motivated for use-cases involving `CoreData` deferred deduplication.
  @inlinable
  mutating func prune(preservingOnlyThoseIntersecting relevantElements: ObjectSet<Element>) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(self.isValid)
    defer { pedantic_assert(self.isValid) }
    defer { pedantic_assert(self.table.values.allSatisfy({!$0.isDisjoint(with: relevantElements)}))}
    // /////////////////////////////////////////////////////////////////////////
    guard !self.table.isEmpty else {
      return
    }
    guard !relevantElements.isEmpty else {
      self.table.removeAll()
      return
    }
    for identifier in self.table.keySet {
      guard let indexForIdentifier = self.table.index(forKey: identifier) else {
        continue
      }
      let becameEmpty = self.table.values[indexForIdentifier].unsafe_prune(
        preservingOnlyThoseIntersecting: relevantElements
      )
      if becameEmpty {
        self.table.removeValue(
          forKey: identifier
        )
      }
    }
  }
  
}
