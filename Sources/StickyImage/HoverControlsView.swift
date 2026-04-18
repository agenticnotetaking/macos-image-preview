import AppKit

@MainActor
final class HoverControlsView: NSView {
    private weak var controller: ImageWindowController?
    private let blur = NSVisualEffectView()
    private let closeButton = NSButton()
    private let pinButton = NSButton()
    private let menuButton = NSButton()
    private var hideWorkItem: DispatchWorkItem?

    init(controller: ImageWindowController) {
        self.controller = controller
        super.init(frame: .zero)

        wantsLayer = true
        alphaValue = 0

        blur.material = .hudWindow
        blur.blendingMode = .withinWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 12
        blur.layer?.masksToBounds = true
        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)

        configure(closeButton, symbol: "xmark.circle.fill",
                  action: #selector(close(_:)))
        configure(pinButton, symbol: "pin.fill",
                  action: #selector(togglePin(_:)))
        configure(menuButton, symbol: "ellipsis.circle.fill",
                  action: #selector(showMenu(_:)))

        let stack = NSStackView(views: [closeButton, pinButton, menuButton])
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) unused") }

    private func configure(_ button: NSButton, symbol: String, action: Selector) {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        button.image = image
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.target = self
        button.action = action
        button.contentTintColor = .labelColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 20).isActive = true
        button.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }

    // Only the buttons intercept clicks; the blurred background passes through
    // so drag-to-move still works anywhere behind the overlay.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point) else { return nil }
        for button in [closeButton, pinButton, menuButton]
        where hit === button || hit.isDescendant(of: button) {
            return hit
        }
        return nil
    }

    func show() {
        hideWorkItem?.cancel()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            self.animator().alphaValue = 1
        }
    }

    func hide() {
        hideWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                self?.animator().alphaValue = 0
            }
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    func refreshPinState() {
        let symbol = (controller?.isPinned ?? true) ? "pin.fill" : "pin.slash"
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        pinButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
    }

    @objc private func close(_ sender: Any?) {
        controller?.closeWindow()
    }

    @objc private func togglePin(_ sender: Any?) {
        controller?.togglePin()
    }

    @objc private func showMenu(_ sender: Any?) {
        guard
            let controller,
            let event = NSApp.currentEvent,
            let contentView = controller.window?.contentView?.subviews.compactMap({ $0 as? ImageContentView }).first,
            let menu = contentView.menu(for: event)
        else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: menuButton)
    }
}
