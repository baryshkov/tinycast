import AppKit
import Carbon.HIToolbox
import SwiftUI

enum Theme {
    enum Colors {
        static let textPrimary = Color.primary
    }
}

/// Only the panel's state bridge is stubbed; real AppKit responder and event routing is exercised.
@MainActor
final class PaletteState {
    var onMenuOpenChanged: ((Bool) -> Void)?
    var onNavigate: ((Int) -> Void)?
    var onResultSlot: ((Int) -> Void)?
    var isComposing = false
    var menuOpen = false
    var searchFieldFrame = CGRect.zero
    func notePointerMoved(to point: CGPoint) {}
    func disarmHoverHighlight(pointerAt point: CGPoint) {}
    func noteCommandHeld(_ held: Bool) {}
}

@MainActor
private final class PreviewContainer: NSView, KeyboardFocusRefusing {}

@main
@MainActor
struct PaletteKeyboardTests {
    static func main() {
        _ = NSApplication.shared
        let panel = PalettePanel(rootView: Text("Keyboard regression fixture"))
        let state = PaletteState()
        panel.paletteState = state
        var moves: [Int] = []
        var slots: [Int] = []
        state.onNavigate = { moves.append($0) }
        state.onResultSlot = { slots.append($0) }
        func key(_ code: Int, _ characters: String, _ flags: NSEvent.ModifierFlags = [], repeatKey: Bool = false) {
            let event = NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                windowNumber: panel.windowNumber, context: nil, characters: characters,
                charactersIgnoringModifiers: characters, isARepeat: repeatKey, keyCode: UInt16(code))!
            panel.sendEvent(event)
        }
        let editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 100, height: 50))
        panel.contentView?.addSubview(editor)
        precondition(panel.makeFirstResponder(editor), "fixture must be able to take keyboard focus")
        key(kVK_Tab, "\t")
        key(kVK_Tab, "\t", .shift)
        key(kVK_DownArrow, "\u{F701}")
        key(kVK_UpArrow, "\u{F700}")
        key(kVK_ANSI_N, "n", .control)
        key(kVK_ANSI_P, "p", .control)
        precondition(moves == [1, -1, 1, -1, 1, -1], "list keys must survive a preview text responder")
        key(kVK_ANSI_1, "1", .command)
        key(kVK_ANSI_2, "2", .command)
        key(kVK_ANSI_3, "3", .command)
        key(kVK_ANSI_1, "1", .command, repeatKey: true)
        precondition(slots == [0, 1, 2], "result slots use visible positions and do not repeat activation")
        state.menuOpen = true
        key(kVK_Tab, "\t")
        precondition(moves.last == 1 && moves.count == 7, "Tab must also reach menu navigation")
        state.menuOpen = false
        let preview = PreviewContainer(frame: .zero)
        let child = NSTextView(frame: .zero)
        preview.addSubview(child)
        panel.contentView?.addSubview(preview)
        precondition(!panel.makeFirstResponder(child), "preview descendants must not steal focus")
        precondition(panel.firstResponder === editor, "refusing preview focus must preserve the search responder")
        panel.close()
        print("PASS palette keyboard: Tab, Shift-Tab, arrows, Control-N/P, result slots, preview focus")
    }
}
