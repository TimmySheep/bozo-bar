import SwiftUI

struct NoiseControlItem: Identifiable {
    let id: UInt8
    let title: String
    let symbol: String
}

/// Maps the headset's advertised mode names onto SF Symbols with matching meaning.
enum NoiseIcon {
    static func symbol(for name: String) -> String {
        let n = name.lowercased()
        if n.contains("quiet") || n.contains("noise cancel") { return "person.crop.circle" }
        if n.contains("aware") || n.contains("transparen") { return "person.wave.2" }
        if n.contains("immersion") || n.contains("immersive") { return "person.and.background.dotted" }
        return "slider.horizontal.3"
    }

    static let immersiveSymbols: [String] = ["speaker.slash", "dot.radiowaves.left.and.right", "move.3d"]
}

/// Icon-over-label selector laid out like the system noise-control picker.
/// Selection always mirrors the value read back from the headset.
struct NoiseControlGrid: View {
    let title: String
    let items: [NoiseControlItem]
    let selected: UInt8?
    let enabled: Bool
    let onSelect: (UInt8) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)

            LazyVGrid(columns: columns, alignment: .center, spacing: 4) {
                ForEach(items) { item in
                    cell(item)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .padding(.horizontal, 12)
        }
    }

    private func cell(_ item: NoiseControlItem) -> some View {
        let isOn = selected == item.id
        return Button {
            guard !isOn else { return }
            onSelect(item.id)
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(isOn ? Color.accentColor : Color.clear)
                        .frame(width: 38, height: 38)
                    Image(systemName: item.symbol)
                        .font(.system(size: 17, weight: .regular))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(isOn ? Color.white : Color.secondary)
                }
                .frame(width: 38, height: 38)
                Text(item.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isOn ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .help(item.title)
    }
}
