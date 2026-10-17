# Standalone Camera

The Sequoia fork ports the upstream Camera module without Calendar. Open Camera presents a mirrored
preview, supports changing camera and copies a captured photo as PNG. The coordinator is lazy on
AppCore: constructing the app never discovers a camera or asks for permission.

## Invariants

- CameraSession starts only from Open Camera. The OS permission prompt remains the user's choice.
- Startup and device configuration run outside the main actor through the upstream CaptureBox.
- Escape, click-away and taking a photo close the same panel and stop capture after its fade.
- Mirroring applies to both the preview connection and the captured photo.
- No meeting join flow or Calendar dependency is included.

CameraView uses Sequoia's native material instead of the upstream glass background. Other camera
logic and panel lifecycle are retained. Hardware capture requires a separate permissioned smoke test.
