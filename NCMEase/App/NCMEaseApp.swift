import AppKit

@main
struct NCMEaseApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = NCMEaseAppDelegate()
        application.delegate = delegate
        application.run()
    }
}

final class NCMEaseAppDelegate: NSObject, NSApplicationDelegate {
    private let conversionQueue = DispatchQueue(label: "cn.popipa.ncm.conversion", qos: .userInitiated)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let commandLineURLs = CommandLine.arguments.dropFirst().map(URL.init(fileURLWithPath:))
        if !commandLineURLs.isEmpty {
            handle(commandLineURLs)
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.hasReceivedFiles else { return }
            NSApp.terminate(nil)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        handle(urls)
    }

    func application(_ application: NSApplication, openFiles filenames: [String]) {
        handle(filenames.map(URL.init(fileURLWithPath:)))
    }

    private func handle(_ urls: [URL]) {
        guard !hasReceivedFiles else { return }
        hasReceivedFiles = true
        let ncmFiles = urls.filter { $0.pathExtension.lowercased() == "ncm" }

        conversionQueue.async {
            var failures: [(URL, Error)] = []
            for url in ncmFiles {
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed { url.stopAccessingSecurityScopedResource() }
                }

                do {
                    let output = try NCMConverter().convert(url)
                    NSLog("Converted %@ -> %@", url.path, output.path)
                } catch {
                    failures.append((url, error))
                    NSLog("Failed to convert %@: %@", url.path, error.localizedDescription)
                }
            }

            DispatchQueue.main.async {
                for (url, error) in failures {
                    self.presentConversionError(error, for: url)
                }
                NSApp.terminate(nil)
            }
        }
    }

    private func presentConversionError(_ error: Error, for url: URL) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "NCM 转换失败"
        alert.informativeText = "文件：\(url.lastPathComponent)\n\n\(error.localizedDescription)"
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private var hasReceivedFiles = false
}
