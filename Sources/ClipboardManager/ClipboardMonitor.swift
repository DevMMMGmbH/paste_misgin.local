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

    // Scales image down to max 800px and encodes as JPEG to keep history small
    private static func thumbnail(from data: Data) -> Data? {
        guard let image = NSImage(data: data) else { return nil }
        let maxDim: CGFloat = 800
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(maxDim / size.width, maxDim / size.height, 1.0)
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)

        let thumb = NSImage(size: newSize)
        thumb.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy, fraction: 1.0)
        thumb.unlockFocus()

        guard let cgImage = thumb.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let bmp = NSBitmapImageRep(cgImage: cgImage)
        return bmp.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
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
        } else if Settings.shared.saveImages {
            // Read image data on main thread (pasteboard access), then process in background
            let imageTypes: [NSPasteboard.PasteboardType] = [
                .tiff,
                NSPasteboard.PasteboardType("public.png"),
                NSPasteboard.PasteboardType("public.jpeg"),
                NSPasteboard.PasteboardType("com.apple.pict"),
            ]
            for type in imageTypes {
                if let data = pb.data(forType: type) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let thumb = Self.thumbnail(from: data) {
                            DispatchQueue.main.async {
                                ClipboardStore.shared.add(ClipboardItem(text: nil, imageData: thumb))
                            }
                        }
                    }
                    break
                }
            }
        }
    }
}
