import AppKit

MainActor.assumeIsolated {
    if let flag = CommandLine.arguments.firstIndex(of: Stills.argument) {
        let dir = CommandLine.arguments.count > flag + 1 ? CommandLine.arguments[flag + 1] : "."
        exit(Stills.run(dir: dir))
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
