#!/bin/bash
cat << 'INNER_EOF' > .jules/bolt.md
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
INNER_EOF

# Fix DroneDelivery.Client.Service.Maps.pas
sed -i -e '/<<<<<<< HEAD/,/=======/c\
                  // ⚡ Bolt: Performance Fix - Changed O(N^2) dynamic SetLength inside loop to O(N) pre-allocation.\
                  // Reduces redundant memory reallocations, improving JSON parsing speed for large address sets.\
                  SetLength(LSuggestions, LJsonArr.Count);\
                  for I := 0 to LJsonArr.Count - 1 do\
                  begin\
                    LInner := LJsonArr.Items[I] as TJSONObject;\
                    LSuggestions[I] := LInner.GetValue<string>('\''address'\'');\
                  end;' src/client/Services/DroneDelivery.Client.Service.Maps.pas
sed -i -e '/>>>>>>> main/d' src/client/Services/DroneDelivery.Client.Service.Maps.pas

# Fix DroneDelivery.Server.Repository.Drone.pas
sed -i -e '/<<<<<<< HEAD/,/=======/c\
  // ⚡ Bolt: Performance Fix - Replaced O(N^2) inline SetLength with TList<T> buffering.\
  // Converting to array at the end changes memory operations from quadratic to amortized O(N),\
  // drastically improving query mapping time for large datasets.\
  LList := TList<TDroneEntity>.Create;\
  try\
    Qry := TFDQuery.Create(nil);\
    try\
      Qry.Connection := FConn;\
      Qry.SQL.Text := '\''SELECT * FROM drones'\'';\
      Qry.Open;\
      while not Qry.Eof do\
      begin\
        LDrone := TDroneEntity.Create;\
        LDrone.Id := Qry.FieldByName('\''id'\'').AsString;\
        LDrone.Nome := Qry.FieldByName('\''name'\'').AsString;\
        LDrone.PayloadMaximo := Qry.FieldByName('\''max_payload_kg'\'').AsFloat;\
        LDrone.AutonomiaKm := Qry.FieldByName('\''max_range_km'\'').AsFloat;\
        LDrone.BatteryWh := Qry.FieldByName('\''battery_wh'\'').AsFloat;\
        LDrone.VelocidadeKmH := Qry.FieldByName('\''speed_kmh'\'').AsFloat;\
        LDrone.ImageUrl := Qry.FieldByName('\''image_url'\'').AsString;\
        LDrone.Status := Qry.FieldByName('\''status'\'').AsString;\
        LList.Add(LDrone);\
        Qry.Next;\
      end;\
    finally\
      Qry.Free;\
    end;\
    Result := LList.ToArray;\
  finally\
    LList.Free;\
  end;' src/server/Repositories/DroneDelivery.Server.Repository.Drone.pas
sed -i -e '/<<<<<<< HEAD/,/>>>>>>> main/d' src/server/Repositories/DroneDelivery.Server.Repository.Drone.pas

# Fix DroneDelivery.Server.Repository.Location.pas
sed -i -e '/<<<<<<< HEAD/,/=======/c\
  // ⚡ Bolt: Performance Fix - Replaced O(N^2) inline SetLength with TList<T> buffering.\
  // Converting to array at the end changes memory operations from quadratic to amortized O(N),\
  // drastically improving query mapping time for large datasets.\
  LList := TList<TLocalEntity>.Create;\
  try\
    Qry := TFDQuery.Create(nil);\
    try\
      Qry.Connection := FConn;\
      Qry.SQL.Text := '\''SELECT * FROM locations'\'';\
      Qry.Open;\
      while not Qry.Eof do\
      begin\
        LLocal := TLocalEntity.Create;\
        LLocal.Id := Qry.FieldByName('\''id'\'').AsString;\
        LLocal.Nome := Qry.FieldByName('\''name'\'').AsString;\
        LLocal.Latitude := Qry.FieldByName('\''latitude'\'').AsFloat;\
        LLocal.Longitude := Qry.FieldByName('\''longitude'\'').AsFloat;\
        if Qry.FieldByName('\''loc_type'\'').AsString = '\''base'\'' then LLocal.Tipo := ltBase else LLocal.Tipo := ltCliente;\
\
        LList.Add(LLocal);\
        Qry.Next;\
      end;\
    finally\
      Qry.Free;\
    end;\
    Result := LList.ToArray;\
  finally\
    LList.Free;\
  end;' src/server/Repositories/DroneDelivery.Server.Repository.Location.pas
sed -i -e '/<<<<<<< HEAD/,/>>>>>>> main/d' src/server/Repositories/DroneDelivery.Server.Repository.Location.pas
