import SwiftUI

struct MenuContent: View {
    @ObservedObject var vm: HeadphoneViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showSettings {
                settingsPage
            } else if vm.needsDeviceSelection {
                devicePicker
            } else {
                devicePanel
            }
        }
    }

    // MARK: - Device Picker (first launch / no saved device)

    private var devicePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "headphones")
                    .font(.title2)
                Text("Select Your Headphones")
                    .font(.headline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if vm.discoveredDevices.isEmpty {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning for BMAP devices...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            } else {
                ForEach(vm.discoveredDevices) { device in
                    Button {
                        vm.selectDevice(device)
                    } label: {
                        HStack {
                            Image(systemName: "headphones")
                                .foregroundStyle(.secondary)
                            Text(device.name)
                            Spacer()
                            Text("\(device.rssi) dBm")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }

            Divider().padding(.vertical, 4)

            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("q", modifiers: .command)
            }
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Connected Device Panel

    private var devicePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "headphones")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.state.productName ?? "No Device")
                        .font(.headline)
                    Text(vm.state.connected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let batt = vm.state.battery.first {
                    HStack(spacing: 4) {
                        Image(systemName: batteryIcon(batt.percentage))
                        Text("\(batt.percentage)%")
                            .monospacedDigit()
                    }
                    .font(.callout)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Audio mode — one icon per preset; the highlight follows the headset read-back.
            if !vm.state.audioModes.isEmpty {
                NoiseControlGrid(
                    title: "Audio Mode",
                    items: modeItems,
                    selected: vm.state.audioModeIndex,
                    enabled: vm.state.connected
                ) { vm.setAudioMode($0) }
                .padding(.top, 8)
            }

            // Legacy noise cancellation used by non-Ultra models.
            if vm.state.audioModes.isEmpty, let cnc = vm.state.cnc {
                sectionHeader("Noise Cancellation")
                VStack(alignment: .leading, spacing: 0) {
                    if cnc.userEnableDisable {
                        noiseCancellationButton(title: "Off", value: -1, cnc: cnc)
                    }
                    ForEach(0...Int(max(cnc.totalSteps, 1)), id: \.self) { level in
                        noiseCancellationButton(
                            title: cncLabel(level, totalSteps: cnc.totalSteps),
                            value: level,
                            cnc: cnc
                        )
                    }
                }
            }

            if vm.state.spatialAudio != nil {
                NoiseControlGrid(
                    title: "Immersive Audio",
                    items: immersiveItems,
                    selected: vm.state.spatialAudio?.rawValue,
                    enabled: vm.state.connected
                ) { raw in
                    guard let mode = SpatialAudioMode(rawValue: raw) else { return }
                    vm.setSpatialAudio(mode)
                }
                .padding(.top, 8)
            }

            if let msg = vm.statusMessage {
                Divider().padding(.vertical, 4)
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }

            Divider().padding(.vertical, 6)

            HStack(spacing: 8) {
                Button("Reconnect") { vm.reconnect() }
                Button("Power Off") { vm.powerOff() }
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gear")
                }
                .accessibilityLabel("Settings")
                .help("Settings")
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Settings Page

    private var settingsPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { showSettings = false } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Back")
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            SettingsView(vm: vm)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider().padding(.vertical, 4)

            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("q", modifiers: .command)
            }
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Items

    private var modeItems: [NoiseControlItem] {
        vm.state.audioModes.map { mode in
            NoiseControlItem(id: mode.modeIndex, title: mode.name, symbol: NoiseIcon.symbol(for: mode.name))
        }
    }

    private var immersiveItems: [NoiseControlItem] {
        SpatialAudioMode.allCases.map { mode in
            NoiseControlItem(id: mode.rawValue, title: mode.label,
                             symbol: NoiseIcon.immersiveSymbols[Int(mode.rawValue)])
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }

    private func batteryIcon(_ pct: UInt8) -> String {
        switch pct {
        case 0..<13: "battery.0percent"
        case 13..<38: "battery.25percent"
        case 38..<63: "battery.50percent"
        case 63..<88: "battery.75percent"
        default: "battery.100percent"
        }
    }

    private func cncLabel(_ level: Int, totalSteps: UInt8) -> String {
        if totalSteps <= 1 {
            return level == 0 ? "Aware" : "Quiet"
        }
        if level == 0 { return "Aware" }
        if level == Int(totalSteps) { return "Quiet" }
        return "Level \(level)"
    }

    private func noiseCancellationButton(title: String, value: Int, cnc: CncState) -> some View {
        let current = cnc.enabled ? Int(cnc.currentStep) : -1
        return selectableRow(title: title, isSelected: current == value) {
            guard current != value else { return }
            if value < 0 {
                vm.setCnc(level: 0, enabled: false)
            } else {
                let level = UInt8(min(value, Int(cnc.totalSteps)))
                vm.setCnc(level: level, enabled: true)
            }
        }
    }

    private func selectableRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
