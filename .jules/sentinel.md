## 2024-05-27 - [CRITICAL] Prevent Hardcoded Secrets and Passwords from Logging in Debug Mode
**Vulnerability:** A plain-text database password was being logged to the console using `Writeln` during the database connection test (`$IFDEF DEBUG`) in `src/server/Providers/DroneDelivery.Server.Provider.Connection.pas`. This exposes sensitive credentials to any developer or automated log ingestion tool.
**Learning:** Even within debugging modes, any explicit logging or dumping of variables containing passwords, tokens, or API keys creates an immediate security risk of leaking valid secrets.
**Prevention:** Avoid writing explicit console/log outputs of sensitive string variables. Instead, use obfuscation like `[***REDACTED***]`, or do not log the property entirely. Always sanitize your debug trace statements.
## 2026-05-28 - [HIGH] Prevent JSON Injection via String Concatenation
**Vulnerability:** API endpoints (e.g., `GetDronePricing`) constructed JSON responses using raw string concatenation (e.g., `'{"distance_km": ' + LDist + '}'`). If `LDist` comes directly from a query parameter and is unsanitized, an attacker can inject arbitrary JSON keys or escape strings, leading to JSON Injection (or XSS if content-type is mishandled).
**Learning:** Constructing structured data payloads (JSON, XML) using string concatenation is a widespread anti-pattern that inherently bypasses encoding and escaping protections, exposing the API to injection attacks.
**Prevention:** Always use the language or framework's native object serialization tools (like `TJSONObject` and `TJSONArray` in Delphi) to build responses. These classes automatically handle type-casting, quoting, and escaping of strings and values.
## 2024-05-28 - [MEDIUM] Prevent Information Disclosure via Error Messages
**Vulnerability:** Internal exception messages (`E.Message`) were being exposed to the client in HTTP 500 error responses in `src/server/Controllers/DroneDelivery.Server.Controller.Locations.pas`.
**Learning:** Exposing raw exception strings can leak internal system details, database structures, or application state to attackers, which aids in reconnaissance and exploitation.
**Prevention:** Always use safe, generic error messages for client-facing 500 responses (e.g., `{"error": "Internal Server Error"}`). Only log the actual exception details internally.
## 2026-06-03 - [HIGH] Prevent DOM-based XSS in Leaflet Maps
**Vulnerability:** In `src/client/mapa.html` and `src/client/assets/mapa.html`, the `p.label` property was directly concatenated into HTML within Leaflet map popups (`<b>${p.label}</b>`). This allowed an attacker to execute arbitrary JavaScript if they could control the waypoint/hub names stored in the database.
**Learning:** Even internal mapping tools handling dynamic backend data are vulnerable to Cross-Site Scripting (XSS). Direct interpolation of user-controlled properties into HTML structures bypasses typical front-end framework protections when using raw strings (e.g., template literals or `innerHTML`).
**Prevention:** Always sanitize or escape HTML entities before interpolating dynamic data into HTML structures. Implement a custom `escapeHtml` JavaScript function (or use a robust sanitization library) to convert sensitive characters (`<, >, &, ", '`) to their corresponding HTML entities.
## 2024-06-02 - [HIGH] Prevent DOM-based XSS in Map View
**Vulnerability:** User-controlled strings (`p.label`) were injected directly into an HTML string for Leaflet Map popups in `src/client/mapa.html` via template literals.
**Learning:** Client-side rendering via template literals can result in DOM-based XSS when data is populated from external sources without HTML entity escaping.
**Prevention:** Always implement an explicit HTML escaping function (`escapeHtml`) ensuring values are safely coerced to Strings and escaped before injection into DOM.
## 2024-05-28 - [CRITICAL] Memory Corruptions via Double-Free inside try..finally blocks
**Vulnerability:** Calling `LDrone.Free;` before an `Exit` statement inside a `try..finally` block causes a double-free vulnerability, because Delphi automatically runs the `finally` block before exiting the routine.
**Learning:** In Object Pascal, `Exit` does not bypass `finally` blocks. Attempting to manually clean up memory before an early exit within a `try..finally` scope will crash the application.
**Prevention:** Never manually free an object inside a `try..finally` block that is already responsible for freeing that object. Simply call `Exit` and let the language handle the cleanup.
## 2024-05-28 - [CRITICAL] Client-Side Exposure of Server Secrets
**Vulnerability:** Adding the backend `API_SECRET_KEY` environment variable check to the FMX client app exposes the backend master secret, requiring it to be bundled or accessible in the client environment.
**Learning:** Client applications (frontend) should never manage, know, or require server-side backend secrets. They must rely on user-authenticated tokens (like JWTs) acquired via login.
**Prevention:** Never use `GetEnvironmentVariable` to retrieve backend API secrets inside frontend/client code. Authentication changes must correctly split client-session logic from backend-secret logic.

## 2024-06-07 - [CRITICAL] Memory Corruptions via Double-Free / Memory Leak in try..finally blocks
**Vulnerability:** Calling `Exit;` before an object is explicitly freed during an error flow bypasses cleanup resulting in memory leaks that can be abused for Denial of Service attacks.
**Learning:** If variables are instantiated before conditional validation logic, missing `try..finally` blocks can lead to uncollected memory. Conversely, adding manual `Free` before `Exit` within a `try..finally` will result in a double-free vulnerability.
**Prevention:** In Object Pascal, always instantiate objects directly after variable declaration and immediately use a `try..finally` to ensure memory is released appropriately without explicitly freeing on error pathways.
