import AppKit
import Foundation

final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    private var timer: Timer?
    private var lastChangeCount: Int
    private var skipNext = false

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Call before writing to the pasteboard yourself, so the monitor ignores it.
    func ignoreNext() {
        skipNext = true
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        if skipNext {
            skipNext = false
            return
        }

        if let text = pb.string(forType: .string), !text.isEmpty {
            DispatchQueue.main.async {
                ClipboardStore.shared.add(ClipboardItem(text: text, imageData: nil))
            }
        } else if let data = pb.data(forType: .tiff) {
            DispatchQueue.main.async {
                ClipboardStore.shared.add(ClipboardItem(text: nil, imageData: data))
            }
        }
    }
}
