
func cartesianProduct<T>(
  _ lhses: some Collection<T>,
  _ rhses: some Collection<T>
) -> some Sendable & Collection<(T,T)> where T: Sendable {
  var result: [(T,T)] = []
  result.reserveCapacity(lhses.count * rhses.count)
  for lhs in lhses {
    for rhs in rhses {
      result.append((lhs, rhs))
    }
  }
  
  return result
}

func uniquePairs<T>(
  from items: some Collection<T>
) -> some Sendable & Collection<(T,T)> where T: Sendable {
  var result: [(T,T)] = []
  result.reserveCapacity(items.count * items.count / 2)
  for (ri,r) in items.enumerated() {
    for (li,l) in items.enumerated() where li < ri {
      result.append((l, r))
    }
  }
  
  return result
}
