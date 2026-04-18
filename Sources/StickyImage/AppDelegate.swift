import AppKit
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var pendingPaths: [String] = []
    private var controllers: Set<ImageWindowController> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        MenuBuilder.install()

        for path in pendingPaths {
            openURL(URL(fileURLWithPath: path))
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { openURL(url) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK {
            for url in panel.urls { openURL(url) }
        }
    }

    @objc func pasteAsNew(_ sender: Any?) {
        let pb = NSPasteboard.general
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !urls.isEmpty {
            for url in urls { openURL(url) }
            return
        }
        if let image = NSImage(pasteboard: pb) {
            present(image: image, sourceURL: nil)
        } else {
            NSSound.beep()
        }
    }

    func openURL(_ url: URL) {
        guard let image = NSImage(contentsOf: url), image.isValid else {
            NSSound.beep()
            return
        }
        present(image: image, sourceURL: url)
    }

    func openImageFromPasteboard(_ image: NSImage) {
        present(image: image, sourceURL: nil)
    }

    private func present(image: NSImage, sourceURL: URL?) {
        let controller = ImageWindowController(image: image, sourceURL: sourceURL)
        controllers.insert(controller)
        controller.onClose = { [weak self, weak controller] in
            guard let controller else { return }
            self?.controllers.remove(controller)
        }
        controller.showWindow(nil)
    }
}
