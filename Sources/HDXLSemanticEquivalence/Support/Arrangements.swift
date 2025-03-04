@inlinable
internal func projectedAscendingArrangement<T, V>(
  _ lhs: T,
  _ rhs: T,
  _ projection: (T) -> V
) -> (T, T) where V: Comparable {
  let lhsValue = projection(lhs)
  let rhsValue = projection(rhs)
  return switch lhsValue <= rhsValue {
  case true:
    (lhs, rhs)
  case false:
    (rhs, lhs)
  }
}
