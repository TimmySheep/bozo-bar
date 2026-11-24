import SwiftUI

/// The popover follows the ideal height of the active page instead of reserving the largest height.
struct MenuPopoverLayout<Content: View>: View {
    let content: Content
    let onResize: (CGSize) -> Void

    var body: some View {
        content
            .frame(width: 300)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGSize.self) { geometry in
                geometry.size
            } action: { size in
                onResize(size)
            }
    }
}
