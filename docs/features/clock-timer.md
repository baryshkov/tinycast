# Clock timer

## Invariants

- Tinycast parses and launches a duration only. Clock owns the timer, sound and stop controls.
- Typing never starts a timer. Activating the launcher result runs the native Shortcut.
- Duration input is passed as a file to `/usr/bin/shortcuts`, without a shell.
- Hidden Commands or a hidden timer entry suppress the contextual launcher result too.

## Usage

Type `timer 10m`, `timer 90s`, `timer 1h30m`, or `timer 10` (minutes), then press Enter.
`таймер` and `ч` / `м` / `с` are also accepted. Durations must be positive and below 24 hours.
The result previews the parsed duration. Invalid input shows a usage hint instead of launching.
The generic **Start Timer in Clock** command fills `timer ` for further input.

## One-time setup

Import [Tinycast Timer.shortcut](../../compat/Tinycast%20Timer.shortcut) into Apple's Shortcuts app.
Keep its name **Tinycast Timer**. Its Clock **Start Timer** action takes **Shortcut Input** as
the duration, with the unit set to **seconds**. The exported shortcut was created with the
native Shortcuts editor on macOS Sequoia; it can also be recreated with those settings.
Accept only **Text** as input and set missing-input behavior to **Stop and Respond**.
The export contains only Start Timer; the system CLI may add its own Stop and Output action
when running it. This is normal Shortcuts behavior and does not broaden the accepted input.

The local machine already has this Shortcut installed. A missing or failing Shortcut reports an
error through Tinycast's existing notice surface. Clock uses its own default timer sound; Tinycast
does not set the sound or implement notifications, a countdown, repeat audio or a menu-bar timer.

## Verification

`clock-timer-test` compiles the shipped parser and runner, checks duration bounds and malformed
input, and uses an isolated fake executable to verify the CLI input contract and failure reporting.
It does not start a real timer. A manual check must activate the result in Dev, observe Clock's
countdown, and cancel that test timer afterward.
