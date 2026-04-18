import AppKit

final class BorderlessImageWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // Borderless windows refuse performClose because there is no close button
    // to highlight — bypass that check and honor the delegate's veto directly.
    override func performClose(_ sender: Any?) {
        if let delegate, delegate.responds(to: #selector(NSWindowDelegate.windowShouldClose(_:))),
           delegate.windowShouldClose?(self) == false {
            NSSound.beep()
            return
        }
        close()
    }
}
