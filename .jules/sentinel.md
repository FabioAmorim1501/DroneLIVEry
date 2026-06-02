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
## 2024-06-02 - [HIGH] Prevent DOM-based XSS in Map View
**Vulnerability:** User-controlled strings (`p.label`) were injected directly into an HTML string for Leaflet Map popups in `src/client/mapa.html` via template literals.
**Learning:** Client-side rendering via template literals can result in DOM-based XSS when data is populated from external sources without HTML entity escaping.
**Prevention:** Always implement an explicit HTML escaping function (`escapeHtml`) ensuring values are safely coerced to Strings and escaped before injection into DOM.
