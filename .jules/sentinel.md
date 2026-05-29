## 2024-05-27 - [CRITICAL] Prevent Hardcoded Secrets and Passwords from Logging in Debug Mode
**Vulnerability:** A plain-text database password was being logged to the console using `Writeln` during the database connection test (`$IFDEF DEBUG`) in `src/server/Providers/DroneDelivery.Server.Provider.Connection.pas`. This exposes sensitive credentials to any developer or automated log ingestion tool.
**Learning:** Even within debugging modes, any explicit logging or dumping of variables containing passwords, tokens, or API keys creates an immediate security risk of leaking valid secrets.
**Prevention:** Avoid writing explicit console/log outputs of sensitive string variables. Instead, use obfuscation like `[***REDACTED***]`, or do not log the property entirely. Always sanitize your debug trace statements.
## 2026-05-28 - [HIGH] Prevent JSON Injection via String Concatenation
**Vulnerability:** API endpoints (e.g., `GetDronePricing`) constructed JSON responses using raw string concatenation (e.g., `'{"distance_km": ' + LDist + '}'`). If `LDist` comes directly from a query parameter and is unsanitized, an attacker can inject arbitrary JSON keys or escape strings, leading to JSON Injection (or XSS if content-type is mishandled).
**Learning:** Constructing structured data payloads (JSON, XML) using string concatenation is a widespread anti-pattern that inherently bypasses encoding and escaping protections, exposing the API to injection attacks.
**Prevention:** Always use the language or framework's native object serialization tools (like `TJSONObject` and `TJSONArray` in Delphi) to build responses. These classes automatically handle type-casting, quoting, and escaping of strings and values.
## 2024-05-28 - [MEDIUM] Prevent Information Disclosure in Error Handling
**Vulnerability:** The API endpoint `PutHangar` was exposing the internal exception message (`E.Message`) directly to the client in the 500 Internal Server Error response. This can leak sensitive internal implementation details.
**Learning:** Catching an internal error and writing it directly to a user-facing response can give attackers insight into the application's underlying code or configuration.
**Prevention:** Catch errors and log the explicit error server-side, but respond to the client with a generic error message (e.g., 'Internal Server Error').
