//
//  SemanticEquivalenceTableTests.swift
//

import Foundation
import XCTest
import HDXLCommonUtilities
import HDXLTestingUtilities
import HDXLAlgebraicUtilities
@testable import HDXLSemanticEquivalence

class SemanticEquivalenceTableTests: XCTestCase {
  
  let testDepth: Int = 10
  lazy var testRange = 0...self.testDepth
  
  // ------------------------------------------------------------------------ //
  // MARK: PrioritizedString Setup
  // ------------------------------------------------------------------------ //
  
  lazy var foos = self.testRange.map() {
    PrioritizedString(
      label: "foo",
      priority: $0
    )
  }
  
  lazy var bars = self.testRange.map() {
    PrioritizedString(
      label: "bar",
      priority: $0
    )
  }
  
  lazy var bazs = self.testRange.map() {
    PrioritizedString(
      label: "baz",
      priority: $0
    )
  }
  
  lazy var quuxes = self.testRange.map() {
    PrioritizedString(
      label: "quux",
      priority: $0
    )
  }

  lazy var highestFoo = self.foos[self.testDepth]
  lazy var highestBar = self.bars[self.testDepth]
  lazy var highestBaz = self.bazs[self.testDepth]
  lazy var highestQuux = self.quuxes[self.testDepth]
  
  func testSemanticEquivalenceTableAgainstCannedPrioritizedStrings() {
    self.haltingOnFirstError {
      
      let completeTable = SemanticEquivalenceTable<PrioritizedString>(
        elements: ChainCollection(self.foos, self.bars, self.bazs)
      )
      XCTAssertTrue(
        completeTable.isValid
      )
      XCTAssertFalse(
        completeTable.isEmpty
      )

      XCTAssertNotNil(
        completeTable.equivalenceClass(
          forElement: self.highestFoo
        )
      )
      XCTAssertNotNil(
        completeTable.equivalenceClass(
          forElement: self.highestBar
        )
      )
      XCTAssertNotNil(
        completeTable.equivalenceClass(
          forElement: self.highestBaz
        )
      )
      
      XCTAssertEqual(
        completeTable.equivalenceClass(
          forElement: self.highestFoo
        ),
        completeTable.equivalenceClass(
          forElement: self.highestFoo
        )
      )
      XCTAssertEqual(
        completeTable.equivalenceClass(
          forElement: self.highestBar
        ),
        completeTable.equivalenceClass(
          forElement: self.highestBar
        )
      )
      XCTAssertEqual(
        completeTable.equivalenceClass(
          forElement: self.highestBaz
        ),
        completeTable.equivalenceClass(
          forElement: self.highestBaz
        )
      )


      XCTAssertNotEqual(
        completeTable.equivalenceClass(
          forElement: self.highestFoo
        ),
        completeTable.equivalenceClass(
          forElement: self.highestBar
        )
      )
      XCTAssertNotEqual(
        completeTable.equivalenceClass(
          forElement: self.highestFoo
        ),
        completeTable.equivalenceClass(
          forElement: self.highestBaz
        )
      )
      XCTAssertNotEqual(
        completeTable.equivalenceClass(
          forElement: self.highestBar
        ),
        completeTable.equivalenceClass(
          forElement: self.highestBaz
        )
      )

      for foo in self.foos {
        XCTAssertTrue(
          completeTable.contains(
            element: foo
          )
        )
        XCTAssertEqual(
          self.highestFoo,
          completeTable.referenceElement(
            forElement: foo
          )
        )
      }
      for bar in self.bars {
        XCTAssertTrue(
          completeTable.contains(
            element: bar
          )
        )
        XCTAssertEqual(
          self.highestBar,
          completeTable.referenceElement(
            forElement: bar
          )
        )
      }
      for baz in self.bazs {
        XCTAssertTrue(
          completeTable.contains(
            element: baz
          )
        )
        XCTAssertEqual(
          self.highestBaz,
          completeTable.referenceElement(
            forElement: baz
          )
        )
      }
      for quux in self.quuxes {
        XCTAssertFalse(
          completeTable.contains(
            element: quux
          )
        )
        XCTAssertNil(
          completeTable.referenceElement(
            forElement: quux
          )
        )
      }
      
      // check our results make sense:
      
      var expectedFooClass = SemanticEquivalenceClass<PrioritizedString>(
        referenceElement: self.highestFoo
      )
      expectedFooClass._equivalentElements = self.foos.dropLast()
      
      var expectedBarClass = SemanticEquivalenceClass<PrioritizedString>(
        referenceElement: self.highestBar
      )
      expectedBarClass._equivalentElements = self.bars.dropLast()
      
      var expectedBazClass = SemanticEquivalenceClass<PrioritizedString>(
        referenceElement: self.highestBaz
      )
      expectedBazClass._equivalentElements = self.bazs.dropLast()
      
      for foo in self.foos {
        XCTAssertEqual(
          completeTable.equivalenceClass(forElement: foo),
          expectedFooClass
        )
      }

      for bar in self.bars {
        XCTAssertEqual(
          completeTable.equivalenceClass(forElement: bar),
          expectedBarClass
        )
      }
      
      for baz in self.bazs {
        XCTAssertEqual(
          completeTable.equivalenceClass(forElement: baz),
          expectedBazClass
        )
      }
      
      for quux in self.quuxes {
        XCTAssertNil(
          completeTable.equivalenceClass(forElement: quux)
        )
      }
      
      
      let removalReferences = [
        self.highestFoo,
        self.highestBar,
        self.highestBaz
      ]

      // for our first trick: try removing just-x:
      for removalTarget in ChainCollection(self.foos,self.bars,self.bazs,self.quuxes) {
        var scratchTable = completeTable
        scratchTable.removeEquivalenceClassesSatisfying(predicate: {$0.contains(element: removalTarget)})
        for removalCandidate in removalReferences {
          XCTAssertEqual(
            removalTarget.hasEquivalentSemantics(to: removalCandidate),
            !scratchTable.contains(element: removalCandidate)
          )
          XCTAssertEqual(
            removalTarget.hasEquivalentSemantics(to: removalCandidate),
            nil == scratchTable.equivalenceClass(forElement: removalCandidate)
          )
          XCTAssertEqual(
            removalTarget.hasEquivalentSemantics(to: removalCandidate),
            nil == scratchTable.referenceElement(forElement: removalCandidate)
          )
        }
        XCTAssertFalse(
          scratchTable.contains(element: self.highestQuux)
        )
        XCTAssertNil(
          scratchTable.equivalenceClass(forElement: self.highestQuux)
        )
        XCTAssertNil(
          scratchTable.referenceElement(forElement: self.highestQuux)
        )
      }

      // now for our next trick: try removing all-but-x:
      for removalTarget in ChainCollection(self.foos,self.bars,self.bazs,self.quuxes) {
        var scratchTable = completeTable
        scratchTable.removeEquivalenceClassesFailing(predicate: {$0.contains(element: removalTarget)})
        for removalCandidate in removalReferences {
          XCTAssertEqual(
            removalTarget.hasEquivalentSemantics(to: removalCandidate),
            scratchTable.contains(element: removalCandidate)
          )
          XCTAssertEqual(
            removalTarget.hasEquivalentSemantics(to: removalCandidate),
            nil != scratchTable.equivalenceClass(forElement: removalCandidate)
          )
          XCTAssertEqual(
            removalTarget.hasEquivalentSemantics(to: removalCandidate),
            nil != scratchTable.referenceElement(forElement: removalCandidate)
          )
        }
        XCTAssertFalse(
          scratchTable.contains(element: self.highestQuux)
        )
        XCTAssertNil(
          scratchTable.equivalenceClass(forElement: self.highestQuux)
        )
        XCTAssertNil(
          scratchTable.referenceElement(forElement: self.highestQuux)
        )
      }
    }
  }

  // ------------------------------------------------------------------------ //
  // MARK: PrioritizedStringDuo Setup
  // ------------------------------------------------------------------------ //
  
  let labels: [String] = ["foo", "bar", "baz", "quux"]
  let captions: [String] = ["alpha", "beta", "gamma"]
  let priorities: [Int] = [1, 2, 3]
  let repeatCount: Int = 3
  lazy var repeats: Range<Int> = 0..<self.repeatCount
  
  lazy var unorganizedTestValues: [PrioritizedStringDuo] = CartesianProduct(
    self.repeats,
    self.labels,
    self.captions,
    self.priorities).asTuples().map() {
      (_,label,caption,priority) -> PrioritizedStringDuo
      in
      return PrioritizedStringDuo(
        label: label,
        caption: caption,
        priority: priority
      )
  }
  
  func testSemanticEquivalenceTableAgainstCannedPrioritizedStringDuos() {
    self.haltingOnFirstError {
      
      let table = SemanticEquivalenceTable<PrioritizedStringDuo>(
        elements: self.unorganizedTestValues
      )
      XCTAssertTrue(table.isValid)
      
      for example in self.unorganizedTestValues {
        XCTAssertTrue(
          table.contains(element: example)
        )
        let referenceElement = try! XCTUnwrap(table.referenceElement(forElement: example))
        XCTAssertTrue(
          referenceElement.hasEquivalentSemantics(to: example)
        )
        XCTAssertEqual(
          referenceElement.label,
          example.label
        )
        XCTAssertEqual(
          referenceElement.caption,
          example.caption
        )
        XCTAssertGreaterThanOrEqual(
          referenceElement.priority,
          example.priority
        )

        let equivalenceClass = try! XCTUnwrap(table.equivalenceClass(forElement: example))
        XCTAssertTrue(
          equivalenceClass.contains(element: example)
        )
        XCTAssertTrue(
          equivalenceClass.isValid
        )
        
        for otherEquivalenceClass in table.equivalenceClasses {
          XCTAssertEqual(
            otherEquivalenceClass == equivalenceClass,
            otherEquivalenceClass.contains(element: example)
          )
        }
        
      }
      
      for (x,y) in CartesianProduct(self.unorganizedTestValues, self.unorganizedTestValues).asTuples() {
        let xClass = try! XCTUnwrap(table.equivalenceClass(forElement: x))
        XCTAssertTrue(xClass.contains(element: x))
        let yClass = try! XCTUnwrap(table.equivalenceClass(forElement: y))
        XCTAssertTrue(yClass.contains(element: y))
        XCTAssertEqual(
          x.hasEquivalentSemantics(to: y),
          xClass == yClass
        )
      }
      
    }
  }
  


}
