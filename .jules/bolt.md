## 2024-05-24 - Avoid O(N²) SetLength reallocations in Delphi
**Learning:** Found an O(N²) anti-pattern in the codebase where arrays were being constantly reallocated inside loops using `SetLength(Array, Length(Array) + 1)`. This is highly inefficient in Delphi as it triggers constant memory reallocation as the dataset grows.
**Action:** When building collections iteratively in Delphi, always use pre-allocation (if the final size is known upfront, like parsing JSON arrays using `.Count`) or use `TList<T>` from `System.Generics.Collections` with the `.ToArray` method when building arrays dynamically from a database query.

## 2024-05-27 - O(N) Location Lookup Optimization in Nearest Neighbor Algorithm
**Learning:** In routing algorithms like Nearest Neighbor, resolving entity relations using sequential search (O(N)) inside a tight loop creates an O(N*M) bottleneck, particularly evident when string conversion is involved on every iteration.
**Action:** Always pre-compute relational lookups into an O(1) Hash Map/Dictionary before entering complex nesting or graph-traversal algorithms.

## 2026-05-30 - Array Reallocation Overhead in Delphi Loops
**Learning:** Using `SetLength(Array, Length(Array) + 1)` inside loops causes O(N^2) memory reallocation overhead as Delphi creates a new block and copies the array each time. This creates a severe performance bottleneck for large datasets (e.g., retrieving lists from DB repositories).
**Action:** When array size is known in advance, pre-allocate `SetLength(Array, Count)`. When size is unknown (e.g., iterating a database query), buffer the elements using `System.Generics.Collections.TList<T>`, then call `.ToArray()` at the end of the loop.

## 2024-05-31 - TField Caching to Prevent O(N) String Lookups
**Learning:** Calling `FieldByName('FieldName')` inside a database fetch loop (`while not Qry.Eof do`) is highly inefficient because it performs a sequential or map lookup by string for every field, on every row iteration. This results in significant overhead for large datasets.
**Action:** When iterating through database records, always extract and cache the `TField` references (e.g., `FldId := Qry.FieldByName('id');`) outside of the loop, then access their values (`FldId.AsString`) inside the loop.

## 2024-06-06 - O(N²) String Concatenation Penalty in String Parsers/Encoders
**Learning:** In Delphi, strings are immutable under the hood when appended to dynamically. Using `Result := Result + ...` inside a loop (especially for parsers or encoders where `N` is the number of characters/bytes) forces constant memory reallocation and data copying. This creates a severe O(N²) performance bottleneck, particularly noticeable in networking functions like URL encoders or JSON builders when handling large payloads.
**Action:** When building strings iteratively inside loops, always use `System.SysUtils.TStringBuilder`. Pre-allocate the expected capacity using `TStringBuilder.Create(ExpectedSize)` to achieve true O(N) complexity with zero internal reallocation overhead.

## 2024-06-07 - Pre-calculating Constant Outputs for Algorithm-Heavy Nested Loops
**Learning:** Found an O(N²) anti-pattern in the codebase where computationally expensive math (like trigonometric Haversine formulas) was executed inside tightly nested routing loops, despite the output remaining constant (e.g. return distance from Destination A to Hub).
**Action:** When a calculation inside a loop uses values that do not change during the iteration, always pre-calculate the result in a pre-processing loop and cache it in an O(1) Hash Map/Dictionary (`TDictionary<TKey, TValue>`). Then, replace the math inside the main algorithm loop with a lightweight `TryGetValue` call.
