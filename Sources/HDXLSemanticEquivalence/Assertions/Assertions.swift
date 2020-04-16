//
//  Assertions.swift
//

import Foundation

// flip commented/uncommented to verify it passes even under `HEAVY_DEBUG`.
//#if true
#if HEAVY_DEBUG
@inline(__always)
@usableFromInline
internal func pedantic_assert(
  _ condition: @autoclosure () -> Bool,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
  assert(condition(), message(), file: file, line: line)
}

@inline(__always)
@usableFromInline
internal func pedantic_assertionFailure(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
  assertionFailure(message(), file: file, line: line)
}


@inline(__always)
@usableFromInline
internal func pedantic_precondition(
  _ condition: @autoclosure () -> Bool,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
  precondition(condition(), message(), file: file, line: line)
}

@inline(__always)
@usableFromInline
internal func pedantic_preconditionFailure(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
  preconditionFailure(message(), file: file, line: line)
}

#else

@inline(__always)
@usableFromInline
internal func pedantic_assert(
  _ condition: @autoclosure () -> Bool,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
}

@inline(__always)
@usableFromInline
internal func pedantic_assertionFailure(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
}

@inline(__always)
@usableFromInline
internal func pedantic_precondition(
  _ condition: @autoclosure () -> Bool,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
}

@inline(__always)
@usableFromInline
internal func pedantic_preconditionFailure(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line) {
}

#endif


