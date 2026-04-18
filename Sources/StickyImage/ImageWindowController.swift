import AppKit
import UniformTypeIdentifiers

@MainActor
final class ImageWindowController: NSWindowController, NSWindowDelegate {
    let image: NSImage
    let sourceURL: URL?
    var onClose: (() -> Void)?

    private var aspectLocked = true
    private var shiftMonitor: Any?
    private weak var hoverControls: HoverControlsView?

    init(image: NSImage, sourceURL: URL?) {
        self.image = image
        self.sourceURL = sourceURL

        let contentRect = Self.initialFrame(for: image)
        let window = BorderlessImageWindow(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable, .closable],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.minSize = CGSize(width: 80, height: 80)
        window.aspectRatio = image.size

        super.init(window: window)
        window.delegate = self

        let container = NSView(frame: NSRect(origin: .zero, size: contentRect.size))
        container.autoresizingMask = [.width, .height]
        container.wantsLayer = true
        container.layer?.cornerRadius = 6
        container.layer?.masksToBounds = true
        window.contentView = container

        let content = ImageContentView(image: image, controller: self)
        content.frame = container.bounds
        content.autoresizingMask = [.width, .height]
        container.addSubview(content)

        let hc = HoverControlsView(controller: self)
        hc.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hc)
        NSLayoutConstraint.activate([
            hc.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            hc.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
        ])
        self.hoverControls = hc

        if let previous = NSApp.windows.first(where: {
            $0 !== window && $0.isVisible && $0 is BorderlessImageWindow
        }) {
            let origin = NSPoint(x: previous.frame.minX, y: previous.frame.maxY)
            _ = window.cascadeTopLeft(from: origin)
        } else {
            window.center()
        }

        shiftMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            MainActor.assumeIsolated {
                self?.shiftChanged(event.modifierFlags.contains(.shift))
            }
            return event
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) unused") }

    private func shiftChanged(_ shiftDown: Bool) {
        guard let window else { return }
        if shiftDown && aspectLocked {
            window.aspectRatio = .zero
            window.resizeIncrements = NSSize(width: 1, height: 1)
            aspectLocked = false
        } else if !shiftDown && !aspectLocked {
            window.aspectRatio = image.size
            aspectLocked = true
        }
    }

    func windowWillClose(_ notification: Notification) {
        if let m = shiftMonitor {
            NSEvent.removeMonitor(m)
            shiftMonitor = nil
        }
        onClose?()
    }

    // Actions invoked by content view, hover controls, and right-click menu.
    @objc func togglePin() {
        guard let window else { return }
        window.level = (window.level == .floating) ? .normal : .floating
        hoverControls?.refreshPinState()
    }

    @objc func toggleAllSpaces() {
        guard let window else { return }
        if window.collectionBehavior.contains(.canJoinAllSpaces) {
            window.collectionBehavior.remove(.canJoinAllSpaces)
        } else {
            window.collectionBehavior.insert(.canJoinAllSpaces)
        }
    }

    @objc func resetOpacity() {
        window?.alphaValue = 1.0
    }

    @objc func copyImage() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    @objc func saveImageAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = sourceURL?
            .deletingPathExtension()
            .lastPathComponent ?? "Image"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard
            let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        else {
            NSSound.beep()
            return
        }
        try? png.write(to: url)
    }

    @objc func revealInFinder() {
        guard let url = sourceURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc func closeWindow() {
        window?.close()
    }

    func setHoverControlsVisible(_ visible: Bool) {
        if visible {
            hoverControls?.show()
        } else {
            hoverControls?.hide()
        }
    }

    var hasSourceURL: Bool { sourceURL != nil }
    var isPinned: Bool { window?.level == .floating }
    var isOnAllSpaces: Bool {
        window?.collectionBehavior.contains(.canJoinAllSpaces) ?? false
    }

    private static func initialFrame(for image: NSImage) -> NSRect {
        let screen = NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let maxW = screen.width * 0.6
        let maxH = screen.height * 0.6
        var size = image.size
        if size.width == 0 || size.height == 0 {
            size = CGSize(width: 400, height: 300)
        }
        let scale = min(1, min(maxW / size.width, maxH / size.height))
        let w = max(120, size.width * scale)
        let h = max(120, size.height * scale)
        let x = screen.midX - w / 2
        let y = screen.midY - h / 2
        return NSRect(x: x, y: y, width: w, height: h)
    }
}
