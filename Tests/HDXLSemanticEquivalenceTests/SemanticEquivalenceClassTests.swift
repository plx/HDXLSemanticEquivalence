import Foundation
import Testing
@testable import HDXLSemanticEquivalence
fileprivate let testDepth: Int = 10
fileprivate let testPriorities = 0...testDepth

extension PrioritizedString {
    
  fileprivate static let foos = makeExamples(label: "foo", priorities: 0...testDepth)
  fileprivate static let bars = makeExamples(label: "bar", priorities: 0...testDepth)
}

@Test("`SemanticEquivalenceClass` basic semantics")
func semanticEquivalenceClassBasics() {
  let foos = PrioritizedString.foos
  let bars = PrioritizedString.bars
  
  var fooEquivalenceClass = SemanticEquivalenceClass<PrioritizedString>(referenceElement: foos[0])
  #expect("foo" == fooEquivalenceClass.semanticEquivalenceClassIdentifier)
  #expect(fooEquivalenceClass.isValid)
  
  for (fooIndex, foo) in foos.enumerated().dropFirst() {
    // ------------------------------------------------------------------ //
    // pre-update block
    // ------------------------------------------------------------------ //
    // confirm the equivalence class has valid internal state:
    #expect(fooEquivalenceClass.isValid)

    // confirm we want nothing to do with the `bars`:
    for bar in bars {
      #expect(!fooEquivalenceClass.shouldInclude(element: bar))
    }

    // confirm the earlier ones are still inside:
    for (lowerIndex, lowerFoo) in foos.enumerated() where lowerIndex < fooIndex {
      #expect(fooEquivalenceClass.contains(element: lowerFoo))
    }
    // ...but not the one we're about to add:
    #expect(!fooEquivalenceClass.contains(element: foo))

    // ...which isn't equal to the reference element:
    #expect(foo != fooEquivalenceClass.referenceElement)
    
    // ...but should be incoporated into the equivalence class:
    #expect(fooEquivalenceClass.shouldInclude(element: foo))
    // ...but has semantic equivalence to it:
    #expect(foo.hasEquivalentSemantics(to: fooEquivalenceClass.referenceElement))
    // ...and should be favored over the reference:
    #expect(foo.shouldBeFavored(over: fooEquivalenceClass.referenceElement))
    
    // ...thus it should become the reference element once we add it.
    // ------------------------------------------------------------------ //
    
    // so let's grab the previous reference element real quick:
    let previousReferenceElement = fooEquivalenceClass.referenceElement
    // ...and now let's add it:
    fooEquivalenceClass.incorporate(element: foo)
    // ...and see how it turned out.
    
    // ------------------------------------------------------------------ //
    // post-update block
    // ------------------------------------------------------------------ //
    // confirm the equivalence class has valid internal state:
    #expect(fooEquivalenceClass.isValid)
    // foo should've become the new reference element:
    #expect(foo == fooEquivalenceClass.referenceElement)
    // `fooEquivalenceClass` should contain foo, now
    #expect(fooEquivalenceClass.contains(element: foo))
    // `fooEquivalenceClass` should still contain the previous reference element:
    #expect(fooEquivalenceClass.contains(element: previousReferenceElement))
    // ...and should still have nothing to do with the `bars`:
    for bar in bars {
      #expect(!fooEquivalenceClass.shouldInclude(element: bar))
    }
    // ...and it should still contain the other earlier elements, too!
    for (lowerIndex, lowerFoo) in foos.enumerated() where lowerIndex < fooIndex {
      #expect(fooEquivalenceClass.contains(element: lowerFoo))
    }
  }
  
  // now we test the end state:
  var expectation = fooEquivalenceClass
  let highestFoo = foos[foos.count - 1]
  expectation._referenceElement = highestFoo
  expectation._equivalentElements = foos.dropLast()
  #expect(expectation == fooEquivalenceClass)
  #expect(fooEquivalenceClass.referenceElement == highestFoo)
  #expect(fooEquivalenceClass.equivalentElements == foos.dropLast())
}
