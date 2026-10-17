# Window Switcher

This fork includes upstream's window switcher without the unrelated Menu Search module.
Enable Window Switcher in General, then run Switch Windows or bind its separate forward/backward
shortcuts. Dev ships with those shortcuts unbound.

## Invariants

- AXWindowAccess is shared with window management; no duplicate window-write implementation exists.
- Every opening reads current windows; hiding drops the snapshot and live AX handles.
- Minimized windows remain searchable. Title matches outrank app-name matches; ties keep recent order.
- A repeated chord can step through windows and select when its held modifiers release.
- Switching focuses the selected window without restoring focus to the displaced app first.
- Minimize, Hide Application and Quit Application are explicit menu actions, never scan side effects.

Sequoia uses the established NSWorkspace termination notification and NSObjectProtocol token instead
of the macOS 26 typed notification API. The search adapter maps the app name to the base scorer's
secondary field. window-switch-test guards title fallback, ordering, ranking and result limits.
