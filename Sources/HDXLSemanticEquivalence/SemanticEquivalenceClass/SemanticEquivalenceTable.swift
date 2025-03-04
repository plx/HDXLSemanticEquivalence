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
public struct SemanticEquivalenceTable<Element>
where Element: Equatable & SemanticEquivalenceClassIdentifierProviding {

  public typealias EquivalenceClass = SemanticEquivalenceClass<Element>
  public typealias Identifier = EquivalenceClass.Identifier

  @usableFromInline
  internal typealias TableEntry = SemanticEquivalenceTableEntry<Element>

  @usableFromInline
  internal typealias Table = [Identifier: TableEntry]

  @usableFromInline
  internal var table: Table

  // ------------------------------------------------------------------------ //
  // MARK: Initialization
  // ------------------------------------------------------------------------ //

  /// Create an empty equivalence table.
  @inlinable
  public init() {
    #if HEAVY_DEBUG
      defer { pedanticAssert(isValid) }
    #endif
    self.table = Table()
  }

  /// Create an equivalence table incorporating the elements from `elements`.
  @inlinable
  public init(elements: some Sequence<Element>) {
    #if HEAVY_DEBUG
      defer { pedanticAssert(self.isValid) }
    #endif
    self.init()
    incorporate(elements: elements)
  }

}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Validatable
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTable {

  @inlinable
  internal var isValid: Bool {
    table
      .values
      .allSatisfy(\.isValid)
  }

}

@inlinable
internal func withValidation<T, R>(
  of target: inout SemanticEquivalenceTable<T>,
  perform closure: (inout SemanticEquivalenceTable<T>) throws -> R
) rethrows -> R {
  #if HEAVY_DEBUG
    pedanticAssert(target.isValid)
    defer { pedanticAssert(target.isValid) }
  #endif

  return try closure(&target)
}

// -------------------------------------------------------------------------- //
// MARK: SemanticEquivalenceTable - Support
// -------------------------------------------------------------------------- //

extension SemanticEquivalenceTable {

  /// Returns all contained `EquivalanceClass` records (in an unspecified order).
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
    withValidation(of: &self) {
      let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
      switch $0.table.index(forKey: semanticEquivalenceClassIdentifier) {
      case .some(let indexOfExistingTableEntry):
        $0.table.values[indexOfExistingTableEntry].incorporate(
          element: element
        )
      case .none:
        $0.table[semanticEquivalenceClassIdentifier] = TableEntry(
          referenceElement: element
        )
      }
    }
  }

  /// Updates `self` by incorporating an additional `element`, but only if it is
  /// a member of a pre-existing equivalence class.
  @inlinable
  public mutating func conditionallyIncorporate(elementWhenEquivalenceClassIsKnown element: Element)
  {
    withValidation(of: &self) {
      let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
      guard
        let indexOfExistingTableEntry = $0.table.index(forKey: semanticEquivalenceClassIdentifier)
      else {
        return
      }
      $0.table.values[indexOfExistingTableEntry].weaklyIncorporate(
        element: element
      )
    }
  }

  /// Updates `self` by incorporating an additional `element`, but only if it is
  /// a member of a pre-existing equivalence class.
  @inlinable
  public mutating func conditionallyIncorporate(elementWhenIdentifierIsKnown element: Element) {
    withValidation(of: &self) {
      let semanticEquivalenceClassIdentifier = element.semanticEquivalenceClassIdentifier
      guard
        let indexOfExistingTableEntry = $0.table.index(forKey: semanticEquivalenceClassIdentifier)
      else {
        return
      }
      $0.table.values[indexOfExistingTableEntry].incorporate(
        element: element
      )
    }
  }

  /// Updates `self` by incorporating each element from `elements`.
  @inlinable
  public mutating func incorporate(elements: some Sequence<Element>) {
    withValidation(of: &self) {
      for element in elements {
        $0.incorporate(element: element)
      }
    }
  }

  /// Updates `self` by incorporating each element from `elements`.
  @inlinable
  public mutating func conditionallyIncorporate(
    elementsWhenEquivalenceClassIsKnown elements: some Sequence<Element>
  ) {
    withValidation(of: &self) {
      for element in elements {
        $0.conditionallyIncorporate(
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
    withValidation(of: &self) {
      for element in elements {
        $0.conditionallyIncorporate(
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
    try withValidation(of: &self) {
      guard !$0.table.isEmpty else {
        return
      }
      for identifier in Set($0.table.keys) {
        guard let indexForIdentifier = $0.table.index(forKey: identifier) else {
          continue
        }
        let becameEmpty = try $0.table.values[indexForIdentifier]
          .unsafeRemoveEquivalenceClassesSatisfying(
            predicate: predicate
          )
        if becameEmpty {
          $0.table.removeValue(
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
    try withValidation(of: &self) {
      guard !$0.table.isEmpty else {
        return
      }
      for identifier in Set($0.table.keys) {
        guard let indexForIdentifier = $0.table.index(forKey: identifier) else {
          continue
        }
        let becameEmpty = try $0.table.values[indexForIdentifier]
          .unsafeRemoveEquivalenceClassesFailing(
            predicate: predicate
          )
        if becameEmpty {
          $0.table.removeValue(
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
