# HDXLSemanticEquivalence

A Swift library providing a precise framework for handling semantic equivalence classes and the grouping of elements into these classes - addressing the common need to distinguish between semantic equality and physical identity.

## Overview

In many programming contexts, we face a fundamental challenge: equality (`==`) is under-defined. For any given type, there's typically an obviously correct definition of equality, but there's no consistent way to access alternative notions of equality when needed.

Consider these two common scenarios:

1. **Equality is too weak** - In a `Rational` type where `1/2 == 2/4` (semantically equivalent), we may still need to distinguish between their physical representations.

2. **Equality is too strong** - In a `CoreData` entity like `Tag` where equality requires all fields to match, we need a weaker notion of "semantic equivalence" to identify tags with the same text but different UUIDs.

This library addresses these challenges by introducing:

1. A protocol-based system for defining and comparing semantic equivalence
2. Tools for grouping objects into equivalence classes
3. Utilities for managing and transforming those equivalence classes

The primary use case that inspired this library was implementing lazy deduplication for enforcing uniqueness constraints in Apple's CloudKit/CoreData synchronization infrastructure, but its applications extend beyond that specific scenario.

## Key Concepts

### `SemanticEquivalenceComparable`

The core protocol that types can adopt to express semantic equivalence:

```swift
protocol SemanticEquivalenceComparable: Equatable {
    static func <~> (lhs: Self, rhs: Self) -> SemanticEquivalenceComparisonResult
}
```

The `<~>` operator returns one of four results:

- `.distinct`: Values are semantically different
- `.identical`: Values are completely identical (both semantically and physically)
- `.equivalentPreferLHS`: Values are semantically equivalent, but the left-hand side is preferred
- `.equivalentPreferRHS`: Values are semantically equivalent, but the right-hand side is preferred

This rich comparison model allows you to express both equivalence and preference in a single operation.

### Equivalence Classes

The library provides infrastructure for grouping objects into their semantic equivalence classes:

- `SemanticEquivalenceClass<Element>`: A structure that maintains a reference element and other equivalent elements
- `SemanticEquivalenceTable<Element>`: A collection of equivalence classes with utilities for lookup and manipulation

## Installation

### Swift Package Manager

Add HDXLSemanticEquivalence to your package dependencies in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/plx/HDXLSemanticEquivalence.git", from: "0.0.1")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["HDXLSemanticEquivalence"]),
]
```

### Requirements

- Swift 6.0+
- iOS 18.0+, macOS 15.0+, tvOS 18.0+, watchOS 11.0+

## Usage Examples

### Example 1: A Rational Number Type

```swift
struct Rational {
    let numerator: Int
    let denominator: Int
    
    init(numerator: Int, denominator: Int) {
        // Initialization with validation omitted for brevity
        self.numerator = numerator
        self.denominator = denominator
    }
}

// Regular equality is based on semantic equivalence
extension Rational: Equatable {
    static func == (lhs: Rational, rhs: Rational) -> Bool {
        lhs.numerator * rhs.denominator == rhs.numerator * lhs.denominator
    }
}

// Semantic equivalence with preference for reduced forms
extension Rational: SemanticEquivalenceComparable {
    static func <~> (lhs: Rational, rhs: Rational) -> SemanticEquivalenceComparisonResult {
        // If not semantically equivalent, they're distinct
        guard lhs == rhs else {
            return .distinct
        }
        
        // If physically identical, they're identical
        if lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator {
            return .identical
        }
        
        // Prefer the representation with smaller denominator
        if lhs.denominator < rhs.denominator {
            return .equivalentPreferLHS
        } else if rhs.denominator < lhs.denominator {
            return .equivalentPreferRHS
        }
        
        // If denominators are equal, prefer smaller numerator
        if abs(lhs.numerator) < abs(rhs.numerator) {
            return .equivalentPreferLHS
        } else if abs(rhs.numerator) < abs(lhs.numerator) {
            return .equivalentPreferRHS
        }
        
        // If numerators are equal in magnitude, prefer positive
        if lhs.numerator > rhs.numerator {
            return .equivalentPreferLHS
        } else {
            return .equivalentPreferRHS
        }
    }
}

// Example of use
let a = Rational(numerator: 1, denominator: 2)
let b = Rational(numerator: 2, denominator: 4)
let c = Rational(numerator: 3, denominator: 4)

print(a == b)  // true (semantically equivalent)
print(a <~> b) // .equivalentPreferLHS (a is the more reduced form)

// Group equivalent rationals together
let rationals = [a, b, c]
let table = SemanticEquivalenceTable(elements: rationals)

// Get preferred representation for 1/2
if let preferredForm = table.referenceElement(forElement: b) {
    print(preferredForm) // Will be 1/2, not 2/4
}
```

### Example 2: Tag Deduplication in CoreData

```swift
class Tag: NSManagedObject, SemanticEquivalenceComparable {
    @NSManaged var text: String
    @NSManaged var uuid: UUID
    
    // Standard equality is based on all fields
    // This is required for CoreData to work properly
    
    // Semantic equivalence is based only on text
    static func <~> (lhs: Tag, rhs: Tag) -> SemanticEquivalenceComparisonResult {
        // If they're the same object instance
        if lhs === rhs {
            return .identical
        }
        
        // If the text is different, they're distinct
        guard lhs.text == rhs.text else {
            return .distinct
        }
        
        // If all fields match exactly
        if lhs.uuid == rhs.uuid {
            return .identical
        }
        
        // For equivalent tags, prefer the one with the "lower" UUID
        if lhs.uuid.uuidString < rhs.uuid.uuidString {
            return .equivalentPreferLHS
        } else {
            return .equivalentPreferRHS
        }
    }
}

// Function to deduplicate tags after CloudKit sync
func deduplicateTags(in context: NSManagedObjectContext) {
    // Fetch all tags
    let tags = try! context.fetch(Tag.fetchRequest())
    
    // Create a table of semantic equivalence classes
    let table = SemanticEquivalenceTable(elements: tags)
    
    // Perform deduplication by processing each class
    for equivalenceClass in table.equivalenceClasses {
        // Skip classes with only one element
        guard equivalenceClass.containsMultipleRepresentations else {
            continue
        }
        
        // The reference element is the "winner" that we'll keep
        let winningTag = equivalenceClass.referenceElement
        
        // Process all other representations
        for losingTag in equivalenceClass.equivalentElements {
            // Transfer all relationships from losing tag to winning tag
            for note in losingTag.notes.allObjects as! [Note] {
                note.removeFromTags(losingTag)
                note.addToTags(winningTag)
            }
            
            // Delete the losing tag
            context.delete(losingTag)
        }
    }
    
    // Save changes
    try! context.save()
}
```

## Advanced Features

### Custom Preference Logic

The `SemanticEquivalenceComparable` protocol allows for fine-grained control over which representation is preferred when objects are semantically equivalent:

```swift
// For a temperature type, prefer Celsius over Fahrenheit
struct Temperature: SemanticEquivalenceComparable {
    enum Unit {
        case celsius
        case fahrenheit
    }
    
    let value: Double
    let unit: Unit
    
    // Convert to Celsius for comparison
    private var asCelsius: Double {
        switch unit {
        case .celsius: return value
        case .fahrenheit: return (value - 32) * 5/9
        }
    }
    
    static func <~> (lhs: Temperature, rhs: Temperature) -> SemanticEquivalenceComparisonResult {
        let lhsCelsius = lhs.asCelsius
        let rhsCelsius = rhs.asCelsius
        
        // If temperatures differ by more than a tiny amount, they're distinct
        if abs(lhsCelsius - rhsCelsius) > 0.001 {
            return .distinct
        }
        
        // If completely identical
        if lhs.value == rhs.value && lhs.unit == rhs.unit {
            return .identical
        }
        
        // Prefer Celsius over Fahrenheit
        switch (lhs.unit, rhs.unit) {
        case (.celsius, .fahrenheit):
            return .equivalentPreferLHS
        case (.fahrenheit, .celsius):
            return .equivalentPreferRHS
        default:
            // Both same unit, prefer the one with less rounding error
            if abs(lhs.value.truncatingRemainder(dividingBy: 1)) < 
               abs(rhs.value.truncatingRemainder(dividingBy: 1)) {
                return .equivalentPreferLHS
            } else {
                return .equivalentPreferRHS
            }
        }
    }
}
```

### Working with Equivalence Classes

The library provides a rich API for working with equivalence classes:

```swift
// Create a table of equivalence classes
let table = SemanticEquivalenceTable(elements: myElements)

// Access the canonical (preferred) representation for an element
if let canonical = table.referenceElement(forElement: someElement) {
    // Use the canonical representation
}

// Work with all elements in a specific equivalence class
if let eqClass = table.equivalenceClass(forElement: someElement) {
    // Access the reference element
    let reference = eqClass.referenceElement
    
    // Access all equivalent elements (excluding the reference)
    let equivalents = eqClass.equivalentElements
    
    // Access all elements including reference (in least-to-most-favored order)
    let allElements = eqClass.equivalenceClassElements
}

// Filter equivalence classes
let filteredTable = table.removingEquivalenceClassesSatisfying { eqClass in
    // Return true to remove this class
    eqClass.referenceElement.someProperty > threshold
}
```

## Limitations and Considerations

- The library works with a "flat" notion of semantic equivalence. It doesn't handle deeply nested structures or complex equivalence relationships.
- Careful consideration of precedence and transitivity is needed when implementing the `<~>` operator.
- For very large collections, constructing equivalence tables can be computationally expensive.

## License

HDXLSemanticEquivalence is available under the MIT license. See the LICENSE file for details.