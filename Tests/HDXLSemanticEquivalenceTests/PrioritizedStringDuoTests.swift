//
//  PrioritizedStringDuoTests.swift
//

import Foundation
import XCTest
import HDXLCommonUtilities
import HDXLTestingUtilities
import HDXLAlgebraicUtilities
@testable import HDXLSemanticEquivalence

class PrioritizedStringDuoTests: XCTestCase {
  
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
  
  func testBasicSemantics() {
    self.haltingOnFirstError {
      for (x,y) in CartesianProduct(self.unorganizedTestValues,self.unorganizedTestValues).asTuples() {
        XCTAssertEqual(
          x.hasEquivalentSemantics(to: y),
          ((x.label == y.label)
            &&
            (x.caption == y.caption)
          )
        )
        if x.hasEquivalentSemantics(to: y) && x.priority > y.priority {
          // ^ favorability with identical priorities isn't part of the API contract
          XCTAssertTrue(
            x.shouldBeFavored(over: y)
          )
        }
        // next comparisons are somewhat redundant but may as well check them all:
        switch x <~> y {
        case .distinct:
          XCTAssertTrue(
            x.label != y.label || x.caption != y.caption
          )
        case .identical:
          XCTAssertEqual(
            x,
            y
          )
          XCTAssertEqual(
            x.label,
            y.label
          )
          XCTAssertEqual(
            x.caption,
            y.caption
          )
          XCTAssertEqual(
            x.priority,
            y.priority
          )
        case .equivalentPreferLHS:
          XCTAssertNotEqual(
            x,
            y
          )
          XCTAssertEqual(
            x.label,
            y.label
          )
          XCTAssertEqual(
            x.caption,
            y.caption
          )
          XCTAssertGreaterThan(
            x.priority,
            y.priority
          )
        case .equivalentPreferRHS:
          XCTAssertNotEqual(
            x,
            y
          )
          XCTAssertEqual(
            x.label,
            y.label
          )
          XCTAssertEqual(
            x.caption,
            y.caption
          )
          XCTAssertLessThan(
            x.priority,
            y.priority
          )
        }
      }
    }
  }

}
