## 2024-05-18 - Keyboard Accessibility in Delphi FMX Inputs
**Learning:** In Delphi FMX, input fields like `TComboEdit` and `TEdit` do not natively trigger 'Default' buttons on Enter key presses.
**Action:** Implement an `OnKeyDown` event handler that checks for `vkReturn` to programmatically trigger the associated button's `OnClick` event, and call `SetFocus` on the input afterward to allow for rapid, continuous typing.
## 2024-05-18 - Prevent Labels Swallowing Mouse Events in FMX
**Learning:** In Delphi FMX, `TLabel` elements default to `HitTest := True`, which can unexpectedly swallow mouse events (clicks and hovers) meant for their parent container.
**Action:** Set `HitTest := False` on child labels when constructing custom interactive components to ensure parent containers properly receive interactions.

## 2024-05-19 - SetFocus Robustness in Delphi FMX
**Learning:** Calling `SetFocus` directly after an action in `OnKeyDown` can throw an `EInvalidOperation` exception if the control is not in a valid state to receive focus, especially during rapid interactions.
**Action:** Always wrap `SetFocus` calls with `if Assigned(Control) and Control.CanFocus then Control.SetFocus;` to ensure robustness.

## 2024-05-19 - Preventing Labels from Swallowing Mouse Events in FMX
**Learning:** In Delphi FMX, child `TLabel` components on interactive parent containers (like buttons or cards) can intercept and swallow mouse events, preventing hover effects (like cursor changes) and clicks on the parent.
**Action:** Set `HitTest := False` on `TLabel` components created for UI text to ensure mouse events correctly pass through to the interactive parent component.
## 2024-05-31 - Safe Focus Management in Modals
**Learning:** In Delphi FMX, when handling `vkReturn` inside an input field that triggers a modal action (like a calculation or confirmation), returning focus back to the input field (`SetFocus`) allows for rapid consecutive entries without breaking the keyboard flow. However, it MUST be wrapped in an `Assigned(Control) and Control.CanFocus` check to prevent crashes (`EInvalidOperation`) if the action hides or disables the modal.
**Action:** Always check `CanFocus` before explicitly calling `SetFocus` after programmatic trigger of actions.
## 2024-06-04 - Improve feedback states in Delphi async actions
**Learning:** Adding immediate loading states and post-action confirmations to UI elements vastly improves perceived performance. Furthermore, reading UI state (like `FEditWaypoint.Text`) inside an async callback introduces a race condition; state must be captured *before* making the asynchronous request.
**Action:** Always provide visual validation for map inputs and asynchronous tasks. Ensure thread safety by capturing UI values into local variables prior to the async call and by performing UI updates via `TThread.Synchronize`.

## 2024-06-05 - Disabling UI elements during async operations
**Learning:** Not disabling action buttons (like "Calcular") when an asynchronous request starts allows the user to click the button multiple times, launching simultaneous overlapping requests which can result in race conditions and poor visual feedback.
**Action:** Always disable buttons triggering async actions immediately, and re-enable them (if appropriate) inside the `TThread.Synchronize` block after the action completes to provide clear micro-UX feedback.

## 2024-06-07 - Empty States and List Lifecycle
**Learning:** Adding explicit empty states directly managed within the existing UI list lifecycle (e.g., adding an empty state `TRectangle` to the `FCards` list instead of creating a standalone hidden element) prevents ghost-element memory leaks, simplifies state management, and significantly improves UX feedback when lists load empty.
**Action:** When populating dynamic lists, always handle the empty dataset case by creating explicit empty state elements that hook directly into the list's clear/populate lifecycle.
