## 2024-05-18 - Keyboard Accessibility in Delphi FMX Inputs
**Learning:** In Delphi FMX, input fields like `TComboEdit` and `TEdit` do not natively trigger 'Default' buttons on Enter key presses.
**Action:** Implement an `OnKeyDown` event handler that checks for `vkReturn` to programmatically trigger the associated button's `OnClick` event, and call `SetFocus` on the input afterward to allow for rapid, continuous typing.
