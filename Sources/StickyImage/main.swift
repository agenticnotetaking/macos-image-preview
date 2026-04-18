import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()

delegate.pendingPaths = CommandLine.arguments
    .dropFirst()
    .filter { !$0.hasPrefix("-") }
    .map { $0 }

app.delegate = delegate
app.run()
