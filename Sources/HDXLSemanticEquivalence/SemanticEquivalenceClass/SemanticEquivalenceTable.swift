import Foundation
//import HDXLCommonUtilities

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
    defer { pedantic_assert(isValid) }
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
    incorporate(elements: elements)
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Validatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTable {
  
  @inlinable
  public var isValid: Bool {
    table
      .values
      .allSatisfy(\.isValid)
  }
  
  @inlinable
  internal mutating func withValidation<R>(_ perform: () throws -> R) rethrows -> R {
    pedantic_assert(isValid)
    defer { pedantic_assert(isValid) }
    
    return try perform()
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Support
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTable {
  
  /// Returns all contained `EquivalanceClass` records (in an unspecified order).
  ///
  /// - todo: Change to `some Collection` once I can constrain it appropriately with a `where` clause
  @inlinable
  public var equivalenceClasses: some Collection<EquivalenceClass> {
    table
    .values
    .lazy
    .map({ $0.equivalenceClasses })
    .joined()
  }
  
  /// `true` iff `self` has nothing in it.
  @inlinable
  public var isEmpty: Bool {
    table.isEmpty
  }
  
  /// Returns the set of all contained equivalence-class identifiers.
  @inlinable
  public var semanticEquivalenceClassIdentifiers: Set<Identifier> {
    Set(table.keys)
  }
  
  /// Updates `self` by incorporating an additional `element`.
  @inlinable
  public mutating func incorporate(element: Element) {
    withValidation {
      let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
      switch table.index(forKey: semanticEquivalenceClassIdentifier) {
      case .some(let indexOfExistingTableEntry):
        table.values[indexOfExistingTableEntry].incorporate(
          element: element
        )
      case .none:
        table[semanticEquivalenceClassIdentifier] = TableEntry(
          referenceElement: element
        )
      }
    }
  }

  /// Updates `self` by incorporating an additional `element`, but only if it is
  /// a member of a pre-existing equivalence class.
  @inlinable
  public mutating func conditionallyIncorporate(elementWhenEquivalenceClassIsKnown element: Element) {
    withValidation {
      let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
      guard let indexOfExistingTableEntry = table.index(forKey: semanticEquivalenceClassIdentifier) else {
        return
      }
      table.values[indexOfExistingTableEntry].weaklyIncorporate(
        element: element
      )
    }
  }

  /// Updates `self` by incorporating an additional `element`, but only if it is
  /// a member of a pre-existing equivalence class.
  @inlinable
  public mutating func conditionallyIncorporate(elementWhenIdentifierIsKnown element: Element) {
    withValidation {
      let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
      guard let indexOfExistingTableEntry = table.index(forKey: semanticEquivalenceClassIdentifier) else {
        return
      }
      table.values[indexOfExistingTableEntry].incorporate(
        element: element
      )
    }
  }

  /// Updates `self` by incorporating each element from `elements`.
  @inlinable
  public mutating func incorporate(elements: some Sequence<Element>) {
    withValidation {
      for element in elements {
        incorporate(element: element)
      }
    }
  }

  /// Updates `self` by incorporating each element from `elements`.
  @inlinable
  public mutating func conditionallyIncorporate(
    elementsWhenEquivalenceClassIsKnown elements: some Sequence<Element>
  ) {
    withValidation {
      for element in elements {
        conditionallyIncorporate(
          elementWhenEquivalenceClassIsKnown: element
        )
      }
    }
  }


  /// Updates `self` by incorporating each element from `elements`.
  @inlinable
  public mutating func conditionallyIncorporate(
    elementsWhenIdentifierIsKnown elements: some Sequence<Element>
  ) {
    withValidation {
      for element in elements {
        conditionallyIncorporate(
          elementWhenIdentifierIsKnown: element
        )
      }
    }
  }


  /// Updates `self` by removing all equivalence classes for which `predicate` evaluates to *true*.
  @inlinable
  public mutating func removeEquivalenceClassesSatisfying(
    predicate: (EquivalenceClass) throws -> Bool
  ) rethrows {
    try withValidation {
      guard !table.isEmpty else {
        return
      }
      for identifier in Set(table.keys) {
        guard let indexForIdentifier = table.index(forKey: identifier) else {
          continue
        }
        let becameEmpty = try table.values[indexForIdentifier].unsafe_removeEquivalenceClassesSatisfying(
          predicate: predicate
        )
        if becameEmpty {
          table.removeValue(
            forKey: identifier
          )
        }
      }
    }
  }

  /// Updates `self` by removing all equivalence classes for which `predicate` evaluates to *false*.
  @inlinable
  public mutating func removeEquivalenceClassesFailing(
    predicate: (EquivalenceClass) throws -> Bool
  ) rethrows {
    try withValidation {
      guard !table.isEmpty else {
        return
      }
      for identifier in Set(table.keys) {
        guard let indexForIdentifier = table.index(forKey: identifier) else {
          continue
        }
        let becameEmpty = try table.values[indexForIdentifier].unsafe_removeEquivalenceClassesFailing(
          predicate: predicate
        )
        if becameEmpty {
          table.removeValue(
            forKey: identifier
          )
        }
      }
    }
  }
  
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Queries
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTable {
  
  /// Returns `true` iff the table contains `element`.
  @inlinable
  public func contains(element: Element) -> Bool {
    table[element.semanticEquivalenceClassIdentifier]?
      .contains(
        element: element
    ) ?? false
  }
  
  /// Returns the current reference element semantically-equivalent to `element`,
  /// or `nil` if no such element exists.
  @inlinable
  public func referenceElement(forElement element: Element) -> Element? {
    self
      .table[element.semanticEquivalenceClassIdentifier]?
      .referenceElement(
        forElement: element
    )
  }
  
  @inlinable
  public func equivalenceClass(forElement element: Element) -> EquivalenceClass? {
    self
      .table[element.semanticEquivalenceClassIdentifier]?
      .equivalenceClass(
        forElement: element
    )
  }
  
}


// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Pruning
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTable where Element:AnyObject {

  /// In-place mutates `self` by pruning it down to *only* those equivalence
  /// classes that have at least one object in common with `relevantElements`.
  ///
  /// Motivated for use-cases involving `CoreData` deferred deduplication.
  @inlinable
  public mutating func prune(
    preservingOnlyThoseIntersecting relevantElements: ObjectSet<Element>
  ) {
    // /////////////////////////////////////////////////////////////////////////
    pedantic_assert(isValid)
    defer { pedantic_assert(isValid) }
    defer { pedantic_assert(table.values.allSatisfy({!$0.isDisjoint(with: relevantElements)}))}
    // /////////////////////////////////////////////////////////////////////////
    guard !table.isEmpty else {
      return
    }
    guard !relevantElements.isEmpty else {
      table.removeAll()
      return
    }
    for identifier in Set(table.keys) {
      guard let indexForIdentifier = table.index(forKey: identifier) else {
        continue
      }
      let becameEmpty = table.values[indexForIdentifier].unsafe_prune(
        preservingOnlyThoseIntersecting: relevantElements
      )
      if becameEmpty {
        table.removeValue(
          forKey: identifier
        )
      }
    }
  }
  
}
