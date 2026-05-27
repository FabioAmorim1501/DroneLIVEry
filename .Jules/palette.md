## 2024-05-18 - Hover Cursors for Interactivity
**Learning:** In this Delphi FMX application, several interactive elements (like custom styled TCornerButton and TRectangle used as menus) lacked visual feedback when hovered. The `crHandPoint` cursor needs to be explicitly set to provide standard desktop application UX behavior indicating interactivity.
**Action:** Always check if custom UI elements in FMX views have `Cursor := crHandPoint;` set during initialization or creation to improve discoverability.
