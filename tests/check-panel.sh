#!/bin/bash
set -euo pipefail
menu=Sources/BozoBar/MenuContent.swift
app=Sources/BozoBar/BozoBarApp.swift
grid=Sources/BozoBar/NoiseControlGrid.swift
setting=Sources/BozoBar/SettingsView.swift
failures=0
check() { if "$@"; then printf 'PASS: %s\n' "$*"; else printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); fi; }
system_only() {
    ! grep -Eq 'NSPanel|NSGlassEffectView|NSVisualEffectView|glassEffect\(|\.clipShape\(|hasShadow|BezierPath' "$app" "$menu"
}
check grep -q 'NSPopover()' "$app"
check grep -q 'popover.behavior = .transient' "$app"
check system_only
check grep -q 'MenuPopoverLayout(content: MenuContent(vm: vm)' "$app"
check grep -q 'ble.refreshAudioMode()' "$app"
check grep -q 'modeTimer?.invalidate()' "$app"
check grep -q 'NSImage(systemSymbolName: "headphones"' "$app"
check grep -q 'keyEquivalent: "q"' "$app"

# noise control is an icon grid for both sections
check grep -q 'NoiseControlGrid(' "$menu"
check [ "$(grep -c 'NoiseControlGrid(' "$menu")" -eq 2 ]
check grep -q 'Image(systemName: item.symbol)' "$grid"
check grep -q 'Color.accentColor' "$grid"
check grep -q 'accessibilityAddTraits(isOn ? .isSelected : \[\])' "$grid"
check grep -q 'person.crop.circle' "$grid"
check grep -q 'person.wave.2' "$grid"
check grep -q 'symbolRenderingMode(.monochrome)' "$grid"

# standby timer belongs to Settings now
check grep -q 'Picker("Standby Timer"' "$setting"
not_in_menu() { ! grep -q 'Picker("Standby Timer"' "$menu"; }
check not_in_menu
check grep -q 'vm.setStandbyTimer' "$setting"

# actions use system button styling
check grep -q '.buttonStyle(.bordered)' "$menu"
check [ "$(grep -c '.buttonStyle(.bordered)' "$menu")" -ge 2 ]

# retained capabilities
for token in 'SettingsView(vm: vm)' 'vm.selectDevice' 'vm.setAudioMode' 'vm.setSpatialAudio' 'vm.reconnect' 'vm.powerOff' 'keyboardShortcut("q", modifiers: .command)' 'vm.forgetDevice' 'ForEach(vm.discoveredDevices)'; do
    check grep -Fq "$token" "$menu" "$setting"
done
check git diff --quiet HEAD -- Sources/BozoBar/HeadphoneViewModel.swift Sources/BozoBar/BmapCodec.swift Sources/BozoBar/BmapProtocol.swift Sources/BozoBar/RfcommBmapManager.swift Sources/BozoBar/Models.swift Sources/BozoBar/BleManager.swift
(( failures == 0 ))
