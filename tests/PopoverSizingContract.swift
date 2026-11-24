import AppKit
import SwiftUI

@main
struct PopoverSizingContract {
    @MainActor
    static func main() {
        // Construct hosting views only; do not display a window or start BozoBar/BLE.
        _ = NSApplication.shared
        let host = NSHostingController(rootView: wrapped(pageHeight: 260))
        host.sizingOptions = []
        let proposal = CGSize(width: 300, height: 180)
        let main = host.sizeThatFits(in: proposal)
        host.rootView = wrapped(pageHeight: 118)
        let settings = host.sizeThatFits(in: proposal)
        host.rootView = wrapped(pageHeight: 260)
        let back = host.sizeThatFits(in: proposal)
        precondition(main == CGSize(width: 300, height: 260), "main should not be squeezed by the previous page: \(main)")
        precondition(settings == CGSize(width: 300, height: 118), "settings must fit its own content: \(settings)")
        precondition(back == main, "returning restores the list size: \(back)")
        print("PASS: offscreen native hosting size follows device → settings → device: \(main) → \(settings) → \(back)")
    }

    private static func wrapped(pageHeight: CGFloat) -> some View {
        MenuPopoverLayout(content: Text("Fixture").frame(height: pageHeight), onResize: { _ in })
    }
}
