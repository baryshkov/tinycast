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
confirmed Tab/Shift-Tab and Command-1; file-preview verification requires the primary app's disk grant.
System Settings still held an Accessibility entry named Tinycast 0.9.7 after the original app moved
to backup. That stale entry was removed; adding the current bundle requires explicit user approval.
