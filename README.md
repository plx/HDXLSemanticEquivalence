# HDXLSemanticEquivalence

Small package providing (a) a notion of "semantic equivalence classes" and also (b) tools for the grouping items into their equivalence classes. 

These tools, themselves, are abstract and generic, and their purpose and utility will likely seem obscure...unless, perchance, you've previously encountered the kinds of situations that would motivate such tools. 

In my case, that situation was implementing the lazy deduplication needed to enforce a "0 or 1"-type constraint when using Apple's `CloudKit`/`CoreData` synchronization infrastructure.

## Motivating Example

Apple's `CloudKit`/`CoreData` synchronization doesn't support uniqueness constraints. For models that need such constraints, it's up to the application to implement them via lazy eventual consistency.

Apple's example is a note-taking application that (a) allows one to take notes and (b) assign tags to those notes. Notes are represented via a `Note` entity, tags are represented via a `Tag` entity, and--theoretically--there should only ever be at-most one concrete `Tag` corresponding to any specific textual tag.

A locally-stored CoreData model can achieve uniqueness via CoreData infrastructure (which, in practice, achieves that via the underlying SQLite representation). For synchronization with CloudKit, however, what needs to be done is a bit fussy.

Firstly, the `Tag` needs a dummy field to help with deduplication--Apple's code uses a `UUID`, which seems reasonable. Newly-created tags should fill that dummy field appropriately--in this case, by generating a fresh UUID. Now for the fun part: the application should monitor the CoreData stack, detect when remote records have been merged into the stack, examine the merged records, and then lazily-deduplicate the `Tag` entities.

The actual code is a bit messier, but it looks like this *conceptually*:

```swift
// let's assume we're on the `NSManagedObjectContext`'s queue
func lazilyDeduplicate(
  tags tagsToBeInserted: [Tags],
  within context: NSManagedObjectContext) {
    for tag in tagsToBeInserted {
      // see if *other* tags for the same thing exist
      let equivalentTags = context.fetchTags(
        withTextualRepresentation: tag.textualRepresentation
      )
      // if we've never seen this tag, go on to the next one:
      guard !equivalentTags.isEmpty else {
        continue
      }
      // otherwise, we have (a) a new tag and (b) 1+ old tags
      // ...and thus we need (1) to pick a winner and (2) delete the losers:
      let (survivingTag,tagsToDelete) = self.determineDeduplicationFates(
        insertedTag: tag,
        existingTags: equivalentTags
      )
      // first we make the winner into the winner:
      for tagToDelete in tagsToDelete {
        // capturing `.notes` into an array to avoid
        // mutating-while-iterating...not optimal but 
        // makes the logic easier to follow
        for note in [Note](tagToDelete.notes) {
          note.tags.remove(note)
          note.tags.insert(survivingTag)
          survivingTag.notes.insert(note)
          tagToDelete.notes.remove(note)
          // ^ without capturing `.notes` into a list we
          // have to go back and do this removal after our iteration...
          // ...whence use of the capture for pedagogical purposes
        }
      }
      // now we *delete* the tags via a made-up helper method
      context.deleteTags(tagsToDelete)
    }
  } 
```

The above is a bit streamlined, but it conveys the idea:

1. identify semantically-equivalent duplicate values
2. for each set of duplicates pick a winner (and thus the loser(s))
3. modify the object graph like so:
  - substitute the winner for all references to any of the losers
  - delete the losers, keep the winner
  
...and in Apple's example code, the tag with the lowest `UUID` field is the winner. This results in a de-facto "oldest instance wins" scenario--thereby arguably minimizing object-graph churn for typical use cases. 

## This Project

This project grew out of a still-private package that implements the deduplication logic above in a highly-generic way--I wrote the functionality in *this* package to use in *that* package, only to realize that it had broader applicability. Not *broad* applicability, mind you--this is still a narrow-purpose library--but *broader* applicability.

There's an under-appreciated philosophical issue at play: (1) equality is under-defined, (2) for any given type there's typically an obviously-correct definition to use, but (3) there's no type-level way to know which definition any given type chose and, finally (4) there's no universally-agreed upon way to explicitly *access* most of the alternative notions of equality--object-identity generally being the sole exception.

Consider once more our `Tag` entity, using a representation like this:

```swift
class Tag : NSManagedObject {
  
  @NSManaged
  var textualRepresentation: String
  
  @NSManaged
  var dummyDeduplicationUUID: UUID
  
}
```

`CoreData` *requires* that equality between `Tag`s be physical equality:

```swift
// CoreData *requires* you let it synthesize the equality logic
// but that logic is *equivalent* to this:
extension Tag {
  
  static func == (
    lhs: Tag,
    rhs: Tag) -> Bool {
      return 
        (lhs.textualRepresentation,lhs.dummyDeduplicationUUI)
        ==
        (rhs.textualRepresentation,rhs.dummyDeduplicationUUI)
  }
    
}
```

...but our de-duplication logic has us needing *semantic* equality like this:

```swift
extension Tag {
  
  func isSemanticallyEquivalent(to other: Tag) -> Bool {
    return self.textualRepresentation == other.textualRepresentation
  }
  
}
```

We can easily implement this ourselves, of course, but only in a one-off, ad-hoc way. 

While implementing my deduplication library I developed a simple concept that addresses the needs of deduplication:

```swift
/// Like spaceship operator, but for semantic equivalence.
infix operator <~> : ComparisonPrecedence

/// Protocol for objects supporting notions of semantic equivalence.
protocol SemanticEquivalenceComparable {
  
  static func <~> (lhs: Self, rhs: Self) -> SemanticEquivalenceComparisonResult
  
}

/// Potential semantic-equivalence relationships.
enum SemanticEquivalenceComparisonResult : Int {
  /// Corresponds to semantically-distinct values (tags with different text).
  case distinct
  
  /// Corresponds to completely-identical values (tags with same text, same UUID).
  case identical
  
  /// Corresponds to semantically-equivalent, physically-distinct values wherein we should prefer the LHS (two "foo" tags, but lower-UUID on left)
  case equivalentPreferLHS

  /// Corresponds to semantically-equivalent, physically-distinct values wherein we should prefer the RHS (two "foo" tags, but lower-UUID on right)
  case equivalentPreferRHS
}
```

This concept plays a key part of the `CoreData` deduplication logic, but proved to have other uses, too.

Consider for example a `Rational` type. Typical `Rational` implementations define `==` in terms of semantic equality--`1/2 == 2/4`, etc.--and are correct to choose that definition...but there's no widely-agreed-upon way to check if two rational values are semantically-equivalent but physically-distinct.

We can use the tools for this library to get that, however, defining the comparisons like so:

- `1/2 <~> 1/3 == .distinct` (etc.)
- `1/2 <~> 1/2 == .identical` (physically-identical)
- `1/2 <~> 2/4 == .equivalentPreferLHS` (equivalent, LHS more-reduced)
- `2/4 <~> 1/2 == .equivalentPreferRHS` (equivalent, RHS more-reduced)

...which illustrates the *broader* utility of those concepts.

I'll close out by noting that this illustrates distinct scenarios:

- `CoreData` defines `==` as *physical equality*, leaving us in want of access to a *semantic equality* comparison
- `Rational` defines `==` as *semantic equivalence*, leaving us in want of access to a *physical equality* comparison

The point isn't that, say, one is bad and one is good--that's entirely a contextual consideration. The point, instead, is just that `==` is generally one or the other, but there's no consistent way to ask for either *by name*.

## Remarks

This library also includes the deduplication logic, itself--that was easy to split out of the `CoreData`-related package, so I did. It's not fancy, but shows how deduplication relates to semantic equivalence without cluttering it up with `CoreData`-isms.

Finally, there's a bit of subtlety here: `<~>` helps distinguishes physical and semantic equality, but at a superficial, depth-one level. It's really not clear if this concept can be usefully-generalized to deeper examinations--it gets complicated fast.

Here's a hypothetical example, related to code I've actually written:

```swift
/// Represents a position on a circle in units of π-radians: Rotation(1.0) is π radians (e.g. 180°).
/// Type-constraint `T` supports `Float`, `Double`, etc., but also various flavors of `Rational`.
struct AngularCoordinate<T:RotationRepresentation> {  
  var storage: T  
}
```

Ignoring any considerations of precision, the obvious `SemanticEquivalenceComparisonResult` logic is this:

```swift
extension AngularCoordinate {
  static func <~> (
    lhs: AngularCoordinate<T>,
    rhs: AngularCoordinate<T>) -> SemanticEquivalenceComparisonResult {
      let difference = (lhs.storage - rhs.storage) % 2 // assume this % works
      guard difference == 0 else {
        return .distinct
      }
      // this is a utility function in `HDXLCommonUtilities`
      // fed into a constructor for `SemanticEquivalenceComparisonResult`:
      return SemanticEquivalenceComparisonResult(
        from: ComparisonResult.coalescing(
          // favor smaller representations over larger ones
          abs(lhs.storage) <=> abs(rhs.storage),
          // favor positive representations over negative ones
          (lhs.storage <=> rhs.storage).inverted
        )
      )
    }
}
```

...so far so good, I hope. 

For `T == Float` or `T == Double`, there's no issue to spot--the above is fine.

For `T == Rational<Int64>`, however, there's a potential problem: our implementation of `<~>` for `AngularCoordinate` works for `AngularCoordinate`, but doesn't leave us a way to distinguish between `AngularCoordinate(1/2)` and `AngularCoordinate(2/4)`--they'll wind up treated as `.identical`.
  
This feels wrong, but I never found a clean way to address it conceptually, let alone at the implmentation level--I consider the existence of a reasonable definition of a transitive version of semantic equivalence to be an open question.