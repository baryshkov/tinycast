# Current fork status

See [PORTS.md](PORTS.md) for the selected module ports, integration differences and verification.
Development uses the isolated Dev channel. On 2026-10-17 the user requested promoting this fork
to the primary app and preserving official 0.9.7 in `~/Applications/backup`.

`bash compat/build-dev.sh --release` builds the current primary fork version into
`build/sequoia-primary/Build/Products/Release/Tinycast.app`, using the stable bundle identifier
and existing primary data. It applies the compatibility patch and checks the macOS 15 floor,
weak glass imports and signature. It does not install or launch the result. Before installation,
stop the previous app and preserve its bundle, application support and exported preferences.
The ad-hoc signature differs from the official build, so macOS may require Accessibility again.
Earlier notes below describe the initial development isolation, before this explicit promotion.

# macOS 15 (Sequoia) channel

## This fork: incremental backports

The user excludes AI/Quick AI, MCP, Calendar/meetings and the in-app updater entirely.
The selected priority order is: File Search, launcher/search, window management, full backup and
Raycast import, Settings, system actions, window switcher, standalone camera. Port coherent upstream
modules with their tests; retain their code unchanged where possible and adapt the integration
and Sequoia-specific API calls. Do not pull excluded modules in to satisfy shared settings or wiring.

`sequoia-support` starts at the last published Sequoia release, `v0.9.7-sequoia`
(`df8b50f170fb9469682609969bac913d6e7d2f91`). The official DMG was checksum-verified, installed
and opened on macOS 15.8.1 arm64: onboarding and launcher search work. This does not validate
an app built from this branch or the backports below.

Backport individual changes from upstream; do not merge current `main` wholesale. The historical
`compat/release.sh` and `macos15-compat` skill below perform full merges and publishing, so do not
use them for this workflow. The later `v0.10.20-sequoia` tag has no published release and its tree
does not contain the compatibility patch; it is not the working baseline.

Keep source edits on this branch and the existing material fallback in `compat/macos15.patch`.
The source tree intentionally retains its upstream macOS 26 target; build an exported copy with
the patch applied and `MACOSX_DEPLOYMENT_TARGET=15.0`. Xcode 26.3 is installed at
`/Applications/Xcode.app` and runs on Sequoia 15.6+. Use it per command; changing the system-wide
developer directory is unnecessary.

For each batch, run the affected harnesses and `git apply --check compat/macos15.patch`, then
`bash compat/build-dev.sh --test` for the full suite, Debug build and binary checks. Tests run
against the patched export with Xcode's SDK explicitly selected. Run lint with the same Xcode.
The historical `compat/verify.sh` builds the Release channel and is not the local Dev entry point.

### Working app and Dev app

The official `~/Applications/Tinycast.app` stays the user's primary working version, 0.9.7.
Keep its bundle, preferences, data, permissions and running process untouched.

Run `bash compat/build-dev.sh` to build the fork in a temporary patched export with Xcode 26.3.
The output is `build/sequoia-dev/Build/Products/Debug/Tinycast Dev.app`, bundle identifier
`com.tinycast.app.dev`. It uses separate preferences, data folders, permissions and login item.
The script validates the bundle identity, macOS 15 floor and signature, and never installs or
opens the app. It includes current tracked edits and untracked app/project/test files. Pass `--test`
to run all harnesses before building. Both the launcher executable and Debug library are checked
for the macOS 15 floor and required Liquid Glass imports.

Only install Dev as `~/Applications/Tinycast Dev.app`. Do not enable login, Hyper Key or global
shortcuts for Dev while testing alongside the primary app. The local build uses ad-hoc signing;
Accessibility permissions may need to be granted again after a rebuild.

| Upstream change | Backport |
| --- | --- |
| `5ec0f9de` / #1482 | Follow directory symlinks in application scopes; preserve logical paths, depth limits and cycle handling. Embedded-app scanning and version sorting are separate changes and are not included. |
| `40087b78` / #966 | Clear unpinned clipboard history while retaining pinned text, images and their files. |
| `848c2d6d` / #1602 | Include the stored PNG's file URL when copying an image, for terminal receivers. |
| `47051801` / #1267 | Add Force Quit Application to running-app menus and bind it to Control-Option-Shift-Q. |

The directory-link regression cases fail against the original source and pass with the backport.
Two local build/test adaptations are also included: the palette body uses intermediate view
values so Swift 6.2.4 can typecheck it, and the legacy clipboard fixture explicitly enables
`trusted_schema` in its temporary SQLite connection so its FTS triggers can seed the old database.
The latter changes no application database or runtime setting.

Validation on macOS 15.8.1 with Xcode 26.3 (Swift 6.2.4, SDK 26.2):

- All 37 harnesses pass, including 28 scope checks, 71 clipboard checks, a private-pasteboard
  image test and a real force-quit test against a disposable app that refuses normal termination.
- The signed arm64 Debug app builds with a macOS 15.0 floor and weak Liquid Glass imports.
- SwiftLint 0.65.1 reports no errors; pre-existing warnings remain. For an explicit toolchain,
  set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` and
  `DYLD_FRAMEWORK_PATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib`.
- Compatibility patch application, model import boundaries and `git diff --check` pass.
- The installed Dev app passed onboarding, search, arrow navigation, the actions menu,
  inline calculation, Clipboard mode and Settings. Accessibility-dependent pasting and external
  extensions were not manually exercised. Login, Hyper Key and global shortcuts remain disabled.
- The second batch's Force Quit row is visible for a running app and absent for a stopped app;
  Clipboard settings explicitly say pinned entries are kept. No user app was force-quit. The
  terminal image change is verified at the pasteboard-format boundary, not through Accessibility
  keystroke delivery to a terminal.
- Dev was stopped after the smoke check. The original 0.9.7 remains running, with its executable
  and Info.plist checksums unchanged.

## Historical upstream workflow

The rest of this document describes the original patch-based release channel, for reference.

Tinycast's `main` targets macOS 26 and uses Liquid Glass. This branch (`compat/macos15`) ships the
same app to macOS 15 **without changing a single file on `main`**.

## Why a patch and not a lower deployment target

`glassEffect(_:in:)` is `@available(macOS 26)`. Lowering `MACOSX_DEPLOYMENT_TARGET` is only a build
setting, but the compiler then hard-errors at every call site, and no build flag suppresses that —
the deployment target *is* the availability contract. So some source must be gated. It's a handful of
call sites, and they live here as `macos15.patch` instead of on `main`.

Verified: with those sites gated, the whole app compiles at `-target arm64-apple-macos15.0`,
builds `Release`, and produces `minos 15.0` / `LSMinimumSystemVersion 15.0` against SDK 26.5. The
six SwiftUI glass symbols become **weak** imports, so dyld binds them to null on Sequoia and the
`#available` guard means they're never called.

## What's gated

Both in one `ViewModifier` (`FrostedSurface`) in `Tinycast/DesignSystem/Theme.swift`:

| Helper | macOS 26 | macOS 15 |
|---|---|---|
| `frosted(in:)` — floating pill + menu circle | `glassEffect(.regular.interactive().tint(glassFrost))` | `.ultraThinMaterial` + frost overlay + 0.5pt hairline + soft shadow |
| `frostedMenu(in:)` — popover panels (`PopoverMenu`, `ShortcutRecorderPopover`, `ExtensionActionsPanel`, `NoteSwitcherView`) | `glassEffect(.regular)` | same fallback |

`docs/ui.md` confines glass to floating controls, so that is the entire visual surface affected. The
main palette surface is `NSVisualEffectView` vibrancy — macOS 10.10 API, unchanged on Sequoia, it
just renders as classic blur.

## Universal, unlike the mainline build

macOS 15 is the last release that runs on Intel, so this channel — and only this channel — ships
`arm64 x86_64`. A thin arm64 DMG installs on an Intel Mac and then fails to launch with *"the
application cannot be opened because it has an incorrect executable format"*, which is what shipped
up to `v0.9.4-sequoia`. Both `verify.sh` and the workflow pass `ARCHS="arm64 x86_64"` explicitly
rather than trusting `ARCHS_STANDARD`, and assert the 15.0 floor and weak glass linkage **per
slice** — `vtool -show-build-version` without `-arch` reports every slice at once, so the old
single-value check could not have caught this.

## Build with Xcode 26, not Xcode 16

The artifact is built against the **new** SDK with only the deployment target lowered. An abandoned
earlier attempt built on `macos-15` with Xcode 16.2 instead and needed ~30 files of unrelated
concurrency churn (`@MainActor` annotations, `@preconcurrency import Darwin`,
`#if compiler(>=6.2)` fences). None of that is necessary. Don't redo it.

## Everyday use

```sh
./compat/release.sh           # ship it (see below) — the normal entry point
./compat/verify.sh --quick    # ~35s: patch applies + typechecks at 15 AND 26
./compat/verify.sh            # + Release build, 15.0 floor assert, weak-linkage assert
```

`verify.sh` never touches your working tree — it exports tracked files to a temp dir and patches the
copy, so it's safe to run with uncommitted changes on any branch.

When `main` moves, resync:

```sh
git checkout compat/macos15 && git merge main
./compat/verify.sh
```

If the patch has rotted or `main` gained a new macOS 26-only API, run the **`macos15-compat` skill**
(`.claude/skills/macos15-compat/`) — it regenerates the patch and re-verifies.

## Cutting a release

One command, from this branch:

```sh
./compat/release.sh              # sync with main, verify, tag, push — the whole thing
./compat/release.sh --dry-run    # everything except publishing
```

The version defaults to the newest **stable** mainline tag, so `v0.7.5` ships as `v0.7.5-sequoia` —
the Sequoia build tracks whatever shipped on macOS 26. Override with `--version 0.8.0`, replace an
existing tag with `--retag`.

If it exits non-zero (patch rotted, or `main` gained a macOS 26-only API), run the **`macos15-compat`
skill** — it repairs and then releases. That's the intended path: run the skill, do no git yourself.

Releases are **tag-triggered** rather than a button, because `workflow_dispatch` only fires for
workflows present on the default branch and this one deliberately isn't there. `release.sh` creates
and pushes the tag for you.

The workflow verifies compatibility *before* publishing anything, then builds, asserts the 15.0
floor on the shipping binary, packages a DMG, publishes a GitHub Release, and bumps the tap cask.

Identity notes:

- **Bundle ID and display name match the mainline channel** (`com.tinycast.app` / `Tinycast`), so a
  Sequoia user who later upgrades to macOS 26 keeps prefs, caches, login item and Accessibility
  grant — all keyed by `Bundle.main.bundleIdentifier`.
- Releases are **always** marked prerelease, including stable-Sequoia:
  `website/src/lib/use-version.ts` reads `/releases/latest`, which GitHub defines as the latest
  *non-prerelease*, so a full release here would hijack the version shown on the site.

## Tap setup (done — `Casks/tinycast-sequoia.rb` exists)

There is **no in-app updater** — Homebrew is the only update path, so the cask guards are the entire
safety mechanism routing each machine to the right build.

`depends_on macos:` semantics, verified against Homebrew 6.0 rather than the docs (which are stale
on this point):

| Form | Means |
|---|---|
| `depends_on macos: :sequoia` | `>= macOS 15` — a bare symbol is a **minimum**, not an exact match |
| `depends_on macos: [:sequoia]` | also `>= macOS 15`; the array gives no exact match |
| `depends_on macos: "<= :sequoia"` | `<= macOS 15`, but the string form is **deprecated** and warns on every install |

So there is no non-deprecated way to express a maximum, and the guards work asymmetrically:

```ruby
# Casks/tinycast.rb + tinycast@beta.rb
depends_on macos: :tahoe                                        # >= 26
conflicts_with cask: "abue-ammar/tinycast/tinycast-sequoia"

# Casks/tinycast-sequoia.rb
depends_on macos: :sequoia                                      # >= 15, the binary's real floor
conflicts_with cask: "abue-ammar/tinycast/tinycast"
```

`tinycast` requiring `>= :tahoe` is what stops a Sequoia machine getting the macOS 26 build — the
direction that actually matters. The reverse is not blocked: a macOS 26+ user who explicitly asks for
`tinycast-sequoia` gets it, and it runs, just with the fallback material instead of glass.
`conflicts_with` stops both being installed at once, since they share `Tinycast.app` and
`com.tinycast.app`.

Keep the existing `postflight` that runs `xattr -dr com.apple.quarantine`. The cask-bump step
hard-errors if `Casks/<cask>.rb` doesn't already exist. Repeat for `tinycast@beta-sequoia` if you
ever want a Sequoia beta channel — it does not exist yet, so a `-beta.N-sequoia` tag would fail at
the cask step.

## Historical release checklist

The original upstream checklist below predates this fork. Dev has been built and launched on this
Sequoia machine in earlier batches; each new module still needs its own runtime smoke test. Before publishing, on a Sequoia machine confirm: the fallback material reads as a
floating control rather than a flat box; the Accessibility prompt and paste-to-`previousApp` focus
restoration work; the Hyper Key `hidutil` caps remap works; emoji grid and clipboard image
thumbnails render. The `onScrollGeometryChange`-driven edge dissolve and thin scrollbar are the
highest-risk items — those APIs are macOS 15.0 exactly, with no headroom.
