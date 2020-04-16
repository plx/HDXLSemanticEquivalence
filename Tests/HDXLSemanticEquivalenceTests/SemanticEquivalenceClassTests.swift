//
//  SemanticEquivalenceClassTests.swift
//

import Foundation
import XCTest
import HDXLCommonUtilities
import HDXLTestingUtilities
import HDXLAlgebraicUtilities
@testable import HDXLSemanticEquivalence

class SemanticEquivalenceClassTests: XCTestCase {
  
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

  lazy var highestFoo = self.foos[self.testDepth]
  lazy var highestBar = self.bars[self.testDepth]
  
  func testSemanticEquivalenceClassBasics() {
    self.haltingOnFirstError {
      var fooEquivalenceClass = SemanticEquivalenceClass<PrioritizedString>(
        referenceElement: self.foos[0]
      )
      XCTAssertEqual(
        "foo",
        fooEquivalenceClass.semanticEquivalenceClassIdentifier
      )
      XCTAssertTrue(
        fooEquivalenceClass.isValid
      )
      for (fooIndex,foo) in self.foos.enumerated().dropFirst() {
        // ------------------------------------------------------------------ //
        // pre-update block
        // ------------------------------------------------------------------ //
        // confirm the equivalence class has valid internal state:
        XCTAssertTrue(
          fooEquivalenceClass.isValid
        )
        // confirm the earlier ones are still inside:
        for (lowerIndex, lowerFoo) in self.foos.enumerated() where lowerIndex < fooIndex {
          XCTAssertTrue(
            fooEquivalenceClass.contains(element: lowerFoo)
          )
        }
        // confirm we want nothing to do with the `bars`:
        for bar in self.bars {
          XCTAssertFalse(
            fooEquivalenceClass.shouldInclude(element: bar)
          )
        }
        // ...but not the one we're about to add:
        XCTAssertFalse(
          fooEquivalenceClass.contains(element: foo)
        )
        // ...which isn't equal to the reference element:
        XCTAssertNotEqual(
          foo,
          fooEquivalenceClass.referenceElement
        )
        // ...but should be incoporated into the equivalence class:
        XCTAssertTrue(
          fooEquivalenceClass.shouldInclude(element: foo)
        )
        // ...but has semantic equivalence to it:
        XCTAssertTrue(
          foo.hasEquivalentSemantics(to: fooEquivalenceClass.referenceElement)
        )
        // ...and should be favored over the reference:
        XCTAssertTrue(
          foo.shouldBeFavored(over: fooEquivalenceClass.referenceElement)
        )
        
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
        XCTAssertTrue(
          fooEquivalenceClass.isValid
        )
        // foo should've become the new reference element:
        XCTAssertEqual(
          foo,
          fooEquivalenceClass.referenceElement
        )
        // `fooEquivalenceClass` should contain foo, now
        XCTAssertTrue(
          fooEquivalenceClass.contains(element: foo)
        )
        // `fooEquivalenceClass` should still contain the previous reference element:
        XCTAssertTrue(
          fooEquivalenceClass.contains(element: previousReferenceElement)
        )
        // ...and should still have nothing to do with the `bars`:
        for bar in self.bars {
          XCTAssertFalse(
            fooEquivalenceClass.shouldInclude(element: bar)
          )
        }
        // ...and it should still contain the other earlier elements, too!
        for (lowerIndex, lowerFoo) in self.foos.enumerated() where lowerIndex < fooIndex {
          XCTAssertTrue(
            fooEquivalenceClass.contains(element: lowerFoo)
          )
        }
      }
      
      // now we test the end state:
      var expectation = fooEquivalenceClass
      expectation._referenceElement = self.highestFoo
      expectation._equivalentElements = self.foos.dropLast()
      XCTAssertEqual(
        expectation,
        fooEquivalenceClass
      )
      XCTAssertEqual(
        fooEquivalenceClass.referenceElement,
        self.highestFoo
      )
      XCTAssertEqual(
        fooEquivalenceClass.equivalentElements,
        self.foos.dropLast()
      )
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
  
  func testEquivalenceClassDetails() {
    self.haltingOnFirstError {
      for (label,caption) in CartesianProduct(self.labels,self.captions).asTuples() {
        var equivalenceClass = SemanticEquivalenceClass<PrioritizedStringDuo>(
          referenceElement: PrioritizedStringDuo(
            label: label,
            caption: caption,
            priority: -99
          )
        )
        XCTAssertTrue(equivalenceClass.isValid)
        for probe in self.unorganizedTestValues {
          XCTAssertTrue(equivalenceClass.isValid)
          XCTAssertEqual(
            equivalenceClass.shouldInclude(
              element: probe
            ),
            (probe.label == label && probe.caption == caption)
          )
          if equivalenceClass.shouldInclude(element: probe) {
            equivalenceClass.incorporate(element: probe)
          }
          XCTAssertTrue(equivalenceClass.isValid)
        }
        XCTAssertTrue(equivalenceClass.isValid)
        for probe in self.unorganizedTestValues {
          XCTAssertEqual(
            equivalenceClass.contains(
              element: probe
            ),
            (probe.label == label && probe.caption == caption)
          )
        }
      }
    }
  }
  
  
}
