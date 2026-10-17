# File Search on the Sequoia fork

File Search uses the upstream local index, not Spotlight. It is disabled by default and requires
Full Disk Access for the Dev bundle independently of stable Tinycast. Enabling it never grants
access automatically. Scope and ignore rules control the crawl; defaults come from upstream.

## Invariants

- The crawl runs in the embedded FileIndexHelper process. Its memory is released on exit.
- Index snapshots are memory-mapped; building a replacement does not block existing searches.
- FSEvents keeps the index current. Unrecoverable event gaps cause a rebuild.
- FileSearchSession has one worker and publishes only the newest request, including its type filter.
- Empty queries show Recent. Closing a screen cancels publication, not another app's work.
- Storage uses AppPaths and the bundle ID, so Dev never shares stable's index or configuration.
- No Spotlight query remains in the feature.

## Integration

AppCore owns FileIndexer and FileSearchSession. The coordinator applies feature switches and policy,
and forwards index changes to the session. File Search has All Types, Folders, Documents, Images,
Audio, Videos and Archives filters. The older palette's header accessory hosts the picker.

Enable Show Files in Launcher to include up to FileSearchQuery.launcherLimit file results in root
search. Files follow the application results, and their keyboard selection and actions use the same
flat order as the list. File rows support drag-out. In Search Files, a click selects for preview,
double-click or Return opens; Command-Return reveals in Finder. Copy Path is in Actions.

Preview implementations are upstream's QuickLook, PDF, text and media surfaces. The stage unmounts
when the palette hides, which releases decoders and pauses playback.

## Verification

file-search-test, file-index-test and file-search-session-test compile the shipped implementation.
The helper's minimum OS is checked with the main executable during compat/build-dev.sh.
An actual full-disk crawl needs the Dev-specific Full Disk Access grant and is a separate smoke test.
