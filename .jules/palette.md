## 2024-05-18 - Keyboard Accessibility in Delphi FMX Inputs
**Learning:** In Delphi FMX, input fields like `TComboEdit` and `TEdit` do not natively trigger 'Default' buttons on Enter key presses.
**Action:** Implement an `OnKeyDown` event handler that checks for `vkReturn` to programmatically trigger the associated button's `OnClick` event, and call `SetFocus` on the input afterward to allow for rapid, continuous typing.
## 2024-05-31 - Safe Focus Management in Modals
**Learning:** In Delphi FMX, when handling `vkReturn` inside an input field that triggers a modal action (like a calculation or confirmation), returning focus back to the input field (`SetFocus`) allows for rapid consecutive entries without breaking the keyboard flow. However, it MUST be wrapped in an `Assigned(Control) and Control.CanFocus` check to prevent crashes (`EInvalidOperation`) if the action hides or disables the modal.
**Action:** Always check `CanFocus` before explicitly calling `SetFocus` after programmatic trigger of actions.
