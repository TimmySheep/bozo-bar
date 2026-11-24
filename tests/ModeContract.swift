@main
struct ModeContract {
    static func main() {
        func check(_ condition: @autoclosure () -> Bool, _ label: String) {
            precondition(condition(), label)
            print("PASS: \(label)")
        }
        let presets: [(UInt8, String)] = [(0, "Quiet"), (1, "Aware"), (2, "Immersion"), (3, "Custom")]
        for (slot, name) in presets {
            let bytes = Array(name.utf8)
            let payload = [slot, 0, 0, 0, 0, 0] + bytes + Array(repeating: UInt8(0), count: 41 - bytes.count)
            let status = BmapPacket(.audioModes, FnId.AudioModes.modeConfig, .status, payload)
            let mode = BmapProtocol.parseModeConfig(status)
            check(mode?.name == name && mode?.modeIndex == slot, "preset \(name) retains the advertised slot and label")
            let command = mode.map { BmapProtocol.setCurrentMode($0.modeIndex).toBytes() }
            check(command == [0x1f, 0x03, 0x05, 0x02, slot, 0x00], "original switch command for \(name)")
        }
        check(BmapProtocol.queryCurrentMode().toBytes() == [0x1f, 0x03, 0x01, 0x00], "poll reads real mode without changing it")
        let current = BmapPacket(.audioModes, FnId.AudioModes.currentMode, .status, [1])
        check(BmapProtocol.parseCurrentMode(current) == 1, "hardware readback selects the advertised Aware slot")
        check(SpatialAudioMode.allCases.map(\.label) == ["Off", "Still", "Motion"], "three original immersive choices")
        for (index, mode) in SpatialAudioMode.allCases.enumerated() {
            check(BmapProtocol.setSpatialAudio(mode.rawValue).toBytes() == [0x05, 0x0f, 0x02, 0x01, UInt8(index)], "original immersive command for \(mode.label)")
        }
    }
}
