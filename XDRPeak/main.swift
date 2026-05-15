import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
statusItem.button?.image = NSImage(
    systemSymbolName: "sun.max",
    accessibilityDescription: "XDRPeak"
)

let menu = NSMenu(title: "XDRPeak")
menu.addItem(
    NSMenuItem(
        title: "Quit XDRPeak",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"
    )
)
statusItem.menu = menu

app.run()
