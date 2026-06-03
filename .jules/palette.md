## 2024-05-18 - Keyboard Accessibility in Delphi FMX Inputs
**Learning:** In Delphi FMX, input fields like `TComboEdit` and `TEdit` do not natively trigger 'Default' buttons on Enter key presses.
**Action:** Implement an `OnKeyDown` event handler that checks for `vkReturn` to programmatically trigger the associated button's `OnClick` event, and call `SetFocus` on the input afterward to allow for rapid, continuous typing.
## 2024-05-18 - Prevent Labels Swallowing Mouse Events in FMX
**Learning:** In Delphi FMX, `TLabel` elements default to `HitTest := True`, which can unexpectedly swallow mouse events (clicks and hovers) meant for their parent container.
**Action:** Set `HitTest := False` on child labels when constructing custom interactive components to ensure parent containers properly receive interactions.
