## 2024-05-18 - Keyboard Accessibility in Delphi FMX Inputs
**Learning:** In Delphi FMX, input fields like `TComboEdit` and `TEdit` do not natively trigger 'Default' buttons on Enter key presses.
**Action:** Implement an `OnKeyDown` event handler that checks for `vkReturn` to programmatically trigger the associated button's `OnClick` event, and call `SetFocus` on the input afterward to allow for rapid, continuous typing.

## 2024-05-19 - SetFocus Robustness in Delphi FMX
**Learning:** Calling `SetFocus` directly after an action in `OnKeyDown` can throw an `EInvalidOperation` exception if the control is not in a valid state to receive focus, especially during rapid interactions.
**Action:** Always wrap `SetFocus` calls with `if Assigned(Control) and Control.CanFocus then Control.SetFocus;` to ensure robustness.

## 2024-05-19 - Preventing Labels from Swallowing Mouse Events in FMX
**Learning:** In Delphi FMX, child `TLabel` components on interactive parent containers (like buttons or cards) can intercept and swallow mouse events, preventing hover effects (like cursor changes) and clicks on the parent.
**Action:** Set `HitTest := False` on `TLabel` components created for UI text to ensure mouse events correctly pass through to the interactive parent component.
