## 2024-05-27 - O(N) Location Lookup Optimization in Nearest Neighbor Algorithm
**Learning:** In routing algorithms like Nearest Neighbor, resolving entity relations using sequential search (O(N)) inside a tight loop creates an O(N*M) bottleneck, particularly evident when string conversion is involved on every iteration.
**Action:** Always pre-compute relational lookups into an O(1) Hash Map/Dictionary before entering complex nesting or graph-traversal algorithms.

## 2026-05-30 - Array Reallocation Overhead in Delphi Loops
**Learning:** Using `SetLength(Array, Length(Array) + 1)` inside loops causes O(N^2) memory reallocation overhead as Delphi creates a new block and copies the array each time. This creates a severe performance bottleneck for large datasets (e.g., retrieving lists from DB repositories).
**Action:** When array size is known in advance, pre-allocate `SetLength(Array, Count)`. When size is unknown (e.g., iterating a database query), buffer the elements using `System.Generics.Collections.TList<T>`, then call `.ToArray()` at the end of the loop.

## 2026-06-01 - Swap-and-Pop O(1) Removal and Short-Circuit Payload Checks
**Learning:** Using `TList<T>.Remove` inside loops forces an O(N) internal search and subsequent shift of all trailing elements. Also, complex calculations (like Haversine distances) become bottlenecks if performed before confirming fast-fail business rules.
**Action:** Use an indexed loop to access elements. Instead of `.Remove`, apply O(1) Swap-and-Pop (`List[Index] := List.Last; List.Delete(Last)`) when element order doesn't matter. Additionally, always perform fast arithmetic limits (like max payload checks) before heavy mathematical functions to short-circuit the loop early.
