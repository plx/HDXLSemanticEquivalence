import Foundation
import Testing
@testable import HDXLSemanticEquivalence
fileprivate let testDepth = 3
fileprivate let testPriorities = 0...3

@Test("`SemanticEquivalenceTable` manual checks")
func semanticEquivalenceTableManualChecks() {
  
  let foos = PrioritizedString.makeExamples(
    label: "foo",
    priorities: testPriorities
  )
  
  let bars = PrioritizedString.makeExamples(
    label: "bar",
    priorities: testPriorities
  )
  
  let bazs = PrioritizedString.makeExamples(
    label: "foo",
    priorities: testPriorities
  )
  
  let quuxes = PrioritizedString.makeExamples(
    label: "quuxes",
    priorities: testPriorities
  )
  
  let everythingButQuuxes = foos + bars + bazs
  
  let highestFoo = foos[testDepth]
  let highestBar = bars[testDepth]
  let highestBaz = bazs[testDepth]
  let highestQuux = quuxes[testDepth]
  
  let completeTable = SemanticEquivalenceTable<PrioritizedString>(
    elements: everythingButQuuxes
  )
  
  #expect(completeTable.isValid)
  #expect(!completeTable.isEmpty)
  let highestNonQuuxes = [highestFoo, highestBar, highestBaz]
  for exampleElement in highestNonQuuxes {
    #expect(nil != completeTable.equivalenceClass(forElement: exampleElement))
    
    #expect(
      completeTable.equivalenceClass(forElement: exampleElement)
      ==
      completeTable.equivalenceClass(forElement: exampleElement)
    )
  }
  
  for (lhs, rhs) in cartesianProduct(highestNonQuuxes, highestNonQuuxes) {
    #expect(
      (lhs == rhs)
      ==
      (
        completeTable.equivalenceClass(forElement: lhs)
        ==
        completeTable.equivalenceClass(forElement: rhs)
      )
    )
  }

  let examplesWithExpectedReferenceElements: [([PrioritizedString], PrioritizedString)] = [
    (foos, highestFoo),
    (bars, highestBar),
    (bazs, highestBaz)
  ]
  
  for (elements, expectedReferenceElement) in examplesWithExpectedReferenceElements {
    for element in elements {
      #expect(completeTable.contains(element: element))
      #expect(expectedReferenceElement == completeTable.referenceElement(forElement: element))
    }
  }
    
  let elementsWithExpectedEquivalenceClasses: [([PrioritizedString], SemanticEquivalenceClass<PrioritizedString>)] = [
    (
      foos,
      SemanticEquivalenceClass<PrioritizedString>(
        referenceElement: highestFoo,
        equivalentElements: foos.dropLast()
      )
    ),
    (
      bars,
      SemanticEquivalenceClass<PrioritizedString>(
        referenceElement: highestBar,
        equivalentElements: bars.dropLast()
      )
    ),
    (
      bazs,
      SemanticEquivalenceClass<PrioritizedString>(
        referenceElement: highestBaz,
        equivalentElements: bazs.dropLast()
      )
    )
  ]
  
  for (elements, expectedEquivalenceClass) in elementsWithExpectedEquivalenceClasses {
    for element in elements {
      #expect(
        element.hasEquivalentSemantics(to: expectedEquivalenceClass.referenceElement)
      )
      #expect(
        expectedEquivalenceClass
        ==
        completeTable.equivalenceClass(forElement: element)
      )
    }
  }

  for quux in quuxes {
    #expect(!completeTable.contains(element: quux))
    #expect(nil == completeTable.referenceElement(forElement: quux))
    #expect(nil == completeTable.equivalenceClass(forElement: quux))
  }
  
  let removalReferences = [
    highestFoo,
    highestBar,
    highestBaz
  ]
  
  // for our first trick: try removing just-x:
  for removalTarget in [foos, bars, bazs, quuxes].flatMap({$0}) {
    var scratchTable = completeTable
    scratchTable.removeEquivalenceClassesSatisfying(predicate: {$0.contains(element: removalTarget)})
    for removalCandidate in removalReferences {
      #expect(
        removalTarget.hasEquivalentSemantics(to: removalCandidate)
        ==
        !scratchTable.contains(element: removalCandidate)
      )
      #expect(
        removalTarget.hasEquivalentSemantics(to: removalCandidate)
        ==
        (nil == scratchTable.equivalenceClass(forElement: removalCandidate))
      )
      #expect(
        removalTarget.hasEquivalentSemantics(to: removalCandidate)
        ==
        (nil == scratchTable.referenceElement(forElement: removalCandidate))
      )
    }
    #expect(
      !scratchTable.contains(element: highestQuux)
    )
    #expect(
      nil == scratchTable.equivalenceClass(forElement: highestQuux)
    )
    #expect(
      nil == scratchTable.referenceElement(forElement: highestQuux)
    )
  }
}

@Test("`SemanticEquivalenceTable` additional checks against `PrioritizedStringDuo`")
func semanticEquivalenceTableChecksAgainstPrioritizedStringDuo() throws {
  let unorganizedTestValues = PrioritizedStringDuo.makeExamples(
    labels: ["foo", "bar", "baz", "quux"],
    captions: ["alpha", "beta", "gamma", "delta"],
    priorities: testPriorities,
    repeatCount: testDepth
  )
  
  let table = SemanticEquivalenceTable<PrioritizedStringDuo>(
    elements: unorganizedTestValues
  )
  #expect(table.isValid)
  
  for example in unorganizedTestValues {
    #expect(table.contains(element: example))
    let referenceElement = try #require(table.referenceElement(forElement: example))
    #expect(referenceElement.hasEquivalentSemantics(to: example))
    #expect(referenceElement.label == example.label)
    #expect(referenceElement.caption == example.caption)
    #expect(referenceElement.priority >= example.priority)
    
    let equivalenceClass = try #require(table.equivalenceClass(forElement: example))
    #expect(equivalenceClass.contains(element: example))
    #expect(equivalenceClass.isValid)
    
    for otherEquivalenceClass in table.equivalenceClasses {
      #expect(
        (otherEquivalenceClass == equivalenceClass)
        ==
        otherEquivalenceClass.contains(element: example)
      )
    }
  }
  
  for (lhs, rhs) in cartesianProduct(unorganizedTestValues, unorganizedTestValues) {
    let lhsClass = try #require(table.equivalenceClass(forElement: lhs))
    #expect(lhsClass.contains(element: lhs))
    let rhsClass = try #require(table.equivalenceClass(forElement: rhs))
    #expect(rhsClass.contains(element: rhs))
    #expect(
      lhs.hasEquivalentSemantics(to: rhs)
      ==
      (lhsClass == rhsClass)
    )
  }
}
