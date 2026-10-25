# Sequoia feature backports

Base: v0.9.7-sequoia, df8b50f170fb9469682609969bac913d6e7d2f91.
Source snapshot: origin/main, 06f3bc75c7 (the pinned local snapshot, not a live release claim).

| User priority | Included |
| --- | --- |
| 13 File Search | Local index/helper, live updates, scopes/ignore rules, Recent, type filters, launcher file results, preview surfaces, drag-out |
| 14 Launcher | New ranking/transliteration, Suggestions, alias matching, embedded apps, version ordering, multiple installations, targeted Quit/Restart, drag-out |
| 15 Window management | Current commands/cycling, custom sizes, saved/captured multi-display layouts, Rooms and parking recovery, shortcut presets |
| 22 Backup/import | Selectable .tinycast archives, clipboard images, snippets, notes, learning, window libraries/shortcuts; RAYCFG3 plus existing v1/v2 readers and quicklinks |
| 23 Settings | Search of shipped panes/fields, interface sizes 1/1.1/1.2, opt-in two-way settings.json for supported preferences |
| 25 System actions | Current runner, microphone mute, feedback and Finder-aware Empty Trash confirmation policy |
| 10 Window switcher | Current sweep/session/actions, minimized windows, forward/backward shortcuts, release-to-switch |
| 6 Camera | Standalone camera panel, mirroring/device switching/photo capture; no Calendar |

AI, MCP, Calendar and the updater remain absent. No wholesale merge of upstream main was performed.
Unchanged module files retain upstream logic; adapters handle the older palette, settings and scorer.
The JSON mirror deliberately binds supported preferences only, not the newer upstream AI/calendar
schema or the record editors. Window records and all their shortcuts are carried by native backup.

## Isolation and build

Development uses Debug/Tinycast Dev.app/com.tinycast.app.dev. The checks below were performed
without modifying the official primary app. On 2026-10-17 the user then authorized promotion:
`bash compat/build-dev.sh --release` builds primary version 0.9.7-sequoia.1 / com.tinycast.app.
Preserve official 0.9.7 under ~/Applications/backup and snapshot primary data before installation.
Dev's global shortcuts, Hyper Key and login item remain disabled for smoke tests.

Run bash compat/build-dev.sh --test with Xcode 26. The script exports HEAD plus local changes and new
source files, applies compat/macos15.patch only in that exported tree, embeds FileIndexHelper, builds
with a macOS 15 floor and verifies signatures and weak glass linkage. It neither installs nor launches.
Do not run compat/release.sh for this fork.

## Tests and limits

New regression coverage includes index snapshots/live changes/query races, frecency, symlinks and
embedded/versioned apps, window geometry/layouts/Rooms/parking, presets and Space gesture bytes,
window-switch ordering, archive round trips/path traversal, settings-file atomic saves/invalid edits,
clipboard blob adoption/deduplication, synthetic RAYCFG3 crypto and microphone mute through injected
CoreAudio fixtures. The real microphone is not changed by the test.

GUI validation is separate from compilation: Full Disk Access, Accessibility window moves and camera
capture require the corresponding Dev grants and manual observation. Never grant those on stable's
behalf or infer a visible pass from a running menu-bar process.

## Verification on 2026-10-17

48 harnesses passed: 47 in the full exported-tree run and the updated hotkey mapping harness on
rerun. The final Debug build succeeded; main executable, debug library and FileIndexHelper each
have a macOS 15 floor. Deep strict code-signature verification and weak-glass checks passed.
SwiftLint reported zero errors; existing/inherited warnings remain. git diff --check is clean.

After unlocking, GUI checks confirmed launcher Suggestions, Settings navigation/search, the File
Search permission/status pane, backup categories/Raycast controls and the Larger palette size.
The size was restored to Default. New Layout initially did nothing: the editor presenter searched
for a window titled Settings after its toolbar had renamed it General. It now attaches directly to
the window owned by AppWindowController. The rebuilt Dev opens and cancels both layout and custom
size editors correctly. Rooms displays its Accessibility prerequisite without accepting a grant.
Window Management was restored to off; shortcuts, Hyper and login remain disabled.
No camera, Accessibility or Full Disk Access grant was accepted. Real camera capture, full file
indexing and moving/switching other apps' windows remain unverified. An earlier Dev process exited
during automation without a crash report; this was not reproduced after relaunch and rebuild.
The original stable Info.plist and executable still match their recorded SHA-256 hashes.

## Keyboard corrections on 2026-10-18

Primary version 0.9.7-sequoia.2 keeps the display name Tinycast. Tab/Shift-Tab navigate results;
Command-1/2/3 immediately activate visible result slots, reserving them from favorites. The panel
handles list keys before embedded preview responders and rejects focus requests from marked
Quick Look/PDF/media subtrees. Rooms layout cycling remains available under Actions → Next Layout.
The AppKit keyboard regression harness and 111,684 selection cases passed, as did the Release build,
macOS 15 binary checks, code-signature verification and lint of changed code. Installed-UI checks
confirmed Tab/Shift-Tab and Command-1.
System Settings still held an Accessibility entry named Tinycast 0.9.7 after the original app moved
to backup. That stale entry was removed and the user explicitly approved both Accessibility and Full
Disk Access, completing the macOS authentication themselves. The running primary app now reports
Accessibility Granted and searches its file index. System Settings may still label the working entry
Tinycast 0.9.7; the app's effective access was checked rather than inferred from that cached label.

Four disposable Markdown files exercised the installed Obsidian Quick Look plug-in. Tab selected
file 02, Down selected 03, Shift-Tab returned to 02; clicking the Markdown preview and pressing Tab
still selected 03. Control-N/P moved to 04 and back to 03. Every observation kept the search text
field focused. The fixtures were removed after testing. No preview-focus failure was reproduced.

## Editable note titles on 2026-10-24

Version 0.9.7-sequoia.3 adds inline title renaming on double-click. Enter and moving focus to the
editor save through the existing Notes rename operation; Escape cancels, blank names are ignored,
and switching documents cancels the title draft. The Notes persistence tests, lint, and Dev build
passed. In the isolated Dev app, double-click, Enter, Escape and click-away were verified; the
renamed Markdown file retained its complete body on disk. The disposable test note was removed
and Dev Notes enablement restored afterward.

## Native Clock timers on 2026-10-25

Version 0.9.7-sequoia.4 adds `timer 10m`, `timer 90s`, `timer 1h30m` and bare minutes.
The contextual launcher result previews the duration and starts only on activation. The native
`Tinycast Timer` Shortcut passes the duration to Clock in seconds; Clock owns all countdown,
sound and stop behavior. The Shortcut is installed locally and exported in compat for reuse.
See docs/features/clock-timer.md for setup and supported syntax.

All 50 harnesses passed in the macOS 15 exported tree. The updated runner harness passed again
after lint cleanup. Full-tree SwiftLint completed with no errors and inherited warnings only;
changed timer sources have no warnings. Debug and Release builds passed with only the existing
App Intents metadata notice, including macOS 15 binary, weak-glass and signature checks.
In Dev, entering `timer 10m` displayed the duration without starting a timer. Enter started a
Clock countdown (09:56 observed), then the test timer was cancelled. `timer 24h` displayed the
usage hint and did not launch. Dev was quit after testing; primary data was not used by Dev.

The primary app was then stopped normally and promoted to .4. Its .3 bundle is saved as
`~/Applications/backup/Tinycast before Clock integration.app`, alongside a dated snapshot of
preferences, application support, caches and settings.json. The preserved official .9.7 binary
checksum is unchanged. Installed-primary activation also started a Clock timer (09:57 observed);
that test timer was cancelled afterward.
