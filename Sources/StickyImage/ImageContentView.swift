import AppKit

private final class PassthroughImageView: NSImageView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

@MainActor
final class ImageContentView: NSView {
    private weak var controller: ImageWindowController?
    private let imageView = PassthroughImageView()

    init(image: NSImage, controller: ImageWindowController) {
        self.controller = controller
        super.init(frame: .zero)

        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.animates = true
        imageView.autoresizingMask = [.width, .height]
        addSubview(imageView)

        registerForDraggedTypes([
            .fileURL,
            .png,
            .tiff,
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) unused") }

    override var frame: NSRect {
        didSet { imageView.frame = bounds }
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        imageView.frame = bounds
    }

    // MARK: - Hover tracking (drives the overlay)
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for ta in trackingAreas { removeTrackingArea(ta) }
        let ta = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(ta)
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func mouseEntered(with event: NSEvent) {
        controller?.setHoverControlsVisible(true)
    }

    override func mouseExited(with event: NSEvent) {
        controller?.setHoverControlsVisible(false)
    }

    override func mouseMoved(with event: NSEvent) {
        controller?.setHoverControlsVisible(true)
    }

    // MARK: - Scroll to opacity
    override func scrollWheel(with event: NSEvent) {
        guard let window else { return super.scrollWheel(with: event) }
        let step = event.hasPreciseScrollingDeltas ? 0.005 : 0.05
        let delta = event.scrollingDeltaY * step
        let newAlpha = max(0.1, min(1.0, window.alphaValue + delta))
        window.alphaValue = newAlpha
    }

    // MARK: - Right-click menu
    override func menu(for event: NSEvent) -> NSMenu? {
        guard let controller else { return nil }
        let menu = NSMenu()

        let copyItem = menu.addItem(
            withTitle: "Copy Image",
            action: #selector(ImageWindowController.copyImage),
            keyEquivalent: ""
        )
        copyItem.target = controller

        let saveItem = menu.addItem(
            withTitle: "Save As…",
            action: #selector(ImageWindowController.saveImageAs),
            keyEquivalent: ""
        )
        saveItem.target = controller

        if controller.hasSourceURL {
            let revealItem = menu.addItem(
                withTitle: "Reveal in Finder",
                action: #selector(ImageWindowController.revealInFinder),
                keyEquivalent: ""
            )
            revealItem.target = controller
        }

        menu.addItem(.separator())

        let pinItem = menu.addItem(
            withTitle: "Always on Top",
            action: #selector(ImageWindowController.togglePin),
            keyEquivalent: ""
        )
        pinItem.target = controller
        pinItem.state = controller.isPinned ? .on : .off

        let spacesItem = menu.addItem(
            withTitle: "All Spaces",
            action: #selector(ImageWindowController.toggleAllSpaces),
            keyEquivalent: ""
        )
        spacesItem.target = controller
        spacesItem.state = controller.isOnAllSpaces ? .on : .off

        let resetItem = menu.addItem(
            withTitle: "Reset Opacity",
            action: #selector(ImageWindowController.resetOpacity),
            keyEquivalent: ""
        )
        resetItem.target = controller

        menu.addItem(.separator())

        let closeItem = menu.addItem(
            withTitle: "Close Window",
            action: #selector(ImageWindowController.closeWindow),
            keyEquivalent: ""
        )
        closeItem.target = controller

        return menu
    }

    // MARK: - Drag & drop
    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self, NSImage.self], options: nil)
            ? .copy
            : []
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        draggingEntered(sender)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let delegate = NSApp.delegate as? AppDelegate else { return false }
        let pb = sender.draggingPasteboard

        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !urls.isEmpty {
            for url in urls { delegate.openURL(url) }
            return true
        }

        if let image = NSImage(pasteboard: pb) {
            delegate.openImageFromPasteboard(image)
            return true
        }
        return false
    }
}
