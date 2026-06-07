## 2024-05-24 - Avoid O(N²) SetLength reallocations in Delphi
**Learning:** Found an O(N²) anti-pattern in the codebase where arrays were being constantly reallocated inside loops using `SetLength(Array, Length(Array) + 1)`. This is highly inefficient in Delphi as it triggers constant memory reallocation as the dataset grows.
**Action:** When building collections iteratively in Delphi, always use pre-allocation (if the final size is known upfront, like parsing JSON arrays using `.Count`) or use `TList<T>` from `System.Generics.Collections` with the `.ToArray` method when building arrays dynamically from a database query.

## 2024-05-27 - O(N) Location Lookup Optimization in Nearest Neighbor Algorithm
**Learning:** In routing algorithms like Nearest Neighbor, resolving entity relations using sequential search (O(N)) inside a tight loop creates an O(N*M) bottleneck, particularly evident when string conversion is involved on every iteration.
**Action:** Always pre-compute relational lookups into an O(1) Hash Map/Dictionary before entering complex nesting or graph-traversal algorithms.

## 2026-05-30 - Array Reallocation Overhead in Delphi Loops
**Learning:** Using `SetLength(Array, Length(Array) + 1)` inside loops causes O(N^2) memory reallocation overhead as Delphi creates a new block and copies the array each time. This creates a severe performance bottleneck for large datasets (e.g., retrieving lists from DB repositories).
**Action:** When array size is known in advance, pre-allocate `SetLength(Array, Count)`. When size is unknown (e.g., iterating a database query), buffer the elements using `System.Generics.Collections.TList<T>`, then call `.ToArray()` at the end of the loop.

## 2024-06-05 - O(N²) String Concatenation Reallocation Overhead
**Learning:** Found an O(N²) anti-pattern where a string was being dynamically constructed inside a loop using repeated concatenation (`Result := Result + ...`) during URL encoding. Since Delphi strings are immutable dynamic arrays of characters, this triggers O(N²) memory reallocation and copying.
**Action:** Always avoid manual string concatenation in loops for tasks like encoding. Use native, optimized libraries (like `System.NetEncoding.TNetEncoding.URL.Encode`) or buffer with `TStringBuilder` when manual construction is strictly required.
