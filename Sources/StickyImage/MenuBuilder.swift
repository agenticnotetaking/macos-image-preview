import AppKit

@MainActor
enum MenuBuilder {
    static func install() {
        let main = NSMenu()

        main.addItem(makeAppMenu())
        main.addItem(makeFileMenu())
        main.addItem(makeEditMenu())

        let winItem = makeWindowMenu()
        main.addItem(winItem)
        NSApp.windowsMenu = winItem.submenu

        NSApp.mainMenu = main
    }

    private static func makeAppMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu()
        menu.addItem(withTitle: "About StickyImage",
                     action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                     keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide StickyImage",
                     action: #selector(NSApplication.hide(_:)),
                     keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Hide Others",
                                    action: #selector(NSApplication.hideOtherApplications(_:)),
                                    keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(hideOthers)
        menu.addItem(withTitle: "Show All",
                     action: #selector(NSApplication.unhideAllApplications(_:)),
                     keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit StickyImage",
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        item.submenu = menu
        return item
    }

    private static func makeFileMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "File")
        menu.addItem(withTitle: "Open…",
                     action: #selector(AppDelegate.openDocument(_:)),
                     keyEquivalent: "o")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Paste as New",
                     action: #selector(AppDelegate.pasteAsNew(_:)),
                     keyEquivalent: "v")
        menu.addItem(withTitle: "New from Clipboard",
                     action: #selector(AppDelegate.pasteAsNew(_:)),
                     keyEquivalent: "n")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Close",
                     action: #selector(NSWindow.performClose(_:)),
                     keyEquivalent: "w")
        item.submenu = menu
        return item
    }

    private static func makeEditMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Edit")
        menu.addItem(withTitle: "Copy",
                     action: #selector(NSText.copy(_:)),
                     keyEquivalent: "c")
        item.submenu = menu
        return item
    }

    private static func makeWindowMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Window")
        menu.addItem(withTitle: "Minimize",
                     action: #selector(NSWindow.performMiniaturize(_:)),
                     keyEquivalent: "m")
        menu.addItem(withTitle: "Zoom",
                     action: #selector(NSWindow.performZoom(_:)),
                     keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Bring All to Front",
                     action: #selector(NSApplication.arrangeInFront(_:)),
                     keyEquivalent: "")
        item.submenu = menu
        return item
    }
}
