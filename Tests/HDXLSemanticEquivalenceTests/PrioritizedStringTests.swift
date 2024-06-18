import Foundation
import XCTest
//import HDXLCommonUtilities
import HDXLTestingUtilities
import HDXLAlgebraicUtilities
@testable import HDXLSemanticEquivalence

class PrioritizedStringTests: XCTestCase {
  
  func testBasicSemantics() {
    self.haltingOnFirstError {
      let foo1a = PrioritizedString(
        label: "foo",
        priority: 1
      )
      let foo1b = PrioritizedString(
        label: "foo",
        priority: 1
      )
      let foo2a = PrioritizedString(
        label: "foo",
        priority: 2
      )
      let foo2b = PrioritizedString(
        label: "foo",
        priority: 2
      )
      
      let bar1a = PrioritizedString(
        label: "bar",
        priority: 1
      )
      let bar1b = PrioritizedString(
        label: "bar",
        priority: 1
      )
      let bar2a = PrioritizedString(
        label: "bar",
        priority: 2
      )
      let bar2b = PrioritizedString(
        label: "bar",
        priority: 2
      )
      
      let foos = [foo1a, foo1b, foo2a, foo2b]
      let bars = [bar1a, bar1b, bar2a, bar2b]

      for (li,l) in foos.enumerated() {
        for (ri,r) in foos.enumerated() where ri <= li {
          XCTAssertTrue(
            l.hasEquivalentSemantics(to: r)
          )
        }
      }
      
      XCTAssertEqual(
        foo2a,
        foo2b
      )
      XCTAssertEqual(
        foo1a,
        foo1b
      )
      XCTAssertNotEqual(
        foo1a,
        foo2a
      )
      XCTAssertNotEqual(
        foo1a,
        foo2b
      )
      XCTAssertNotEqual(
        foo1b,
        foo2a
      )
      XCTAssertNotEqual(
        foo1b,
        foo2b
      )

      XCTAssertEqual(
        bar2a,
        bar2b
      )
      XCTAssertEqual(
        bar1a,
        bar1b
      )
      XCTAssertNotEqual(
        bar1a,
        bar2a
      )
      XCTAssertNotEqual(
        bar1a,
        bar2b
      )
      XCTAssertNotEqual(
        bar1b,
        bar2a
      )
      XCTAssertNotEqual(
        bar1b,
        bar2b
      )
      
      for (foo,bar) in CartesianProduct(foos,bars).asTuples() {
        XCTAssertNotEqual(
          foo,
          bar
        )
      }
    }
    
  }

  func testFavorabilityRelationships() {
    
    let foo1a = PrioritizedString(
      label: "foo",
      priority: 1
    )
    let foo1b = PrioritizedString(
      label: "foo",
      priority: 1
    )
    let foo2a = PrioritizedString(
      label: "foo",
      priority: 2
    )
    let foo2b = PrioritizedString(
      label: "foo",
      priority: 2
    )

    let bar1a = PrioritizedString(
      label: "bar",
      priority: 1
    )
    let bar1b = PrioritizedString(
      label: "bar",
      priority: 1
    )
    let bar2a = PrioritizedString(
      label: "bar",
      priority: 2
    )
    let bar2b = PrioritizedString(
      label: "bar",
      priority: 2
    )
    
    let foos = [foo1a, foo1b, foo2a, foo2b]
    let bars = [bar1a, bar1b, bar2a, bar2b]
    
    XCTAssertTrue(
      foo2a.shouldBeFavored(over: foo1a)
    )
    XCTAssertTrue(
      foo2b.shouldBeFavored(over: foo1a)
    )
    XCTAssertTrue(
      foo2a.shouldBeFavored(over: foo1b)
    )
    XCTAssertTrue(
      foo2b.shouldBeFavored(over: foo1b)
    )

    XCTAssertFalse(
      foo2a.shouldBeFavored(over: foo2a)
    )
    XCTAssertFalse(
      foo2b.shouldBeFavored(over: foo2a)
    )
    XCTAssertFalse(
      foo2a.shouldBeFavored(over: foo2b)
    )
    XCTAssertFalse(
      foo2b.shouldBeFavored(over: foo2b)
    )

    XCTAssertFalse(
      foo1a.shouldBeFavored(over: foo2a)
    )
    XCTAssertFalse(
      foo1b.shouldBeFavored(over: foo2a)
    )
    XCTAssertFalse(
      foo1a.shouldBeFavored(over: foo2b)
    )
    XCTAssertFalse(
      foo1b.shouldBeFavored(over: foo2b)
    )

    for (foo,bar) in CartesianProduct(foos, bars).asTuples() {
      XCTAssertEqual(
        SemanticEquivalenceComparisonResult.distinct,
        foo <~> bar
      )
    }

  }

}
