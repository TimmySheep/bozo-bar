#!/bin/bash
set -euo pipefail
menu=Sources/BozoBar/MenuContent.swift
app=Sources/BozoBar/BozoBarApp.swift
setting=Sources/BozoBar/SettingsView.swift
failures=0
check() { if "$@"; then printf 'PASS: %s\n' "$*"; else printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); fi; }
system_only() {
    ! grep -Eq 'NSPanel|NSGlassEffectView|NSVisualEffectView|glassEffect\(|\.background\(|\.clipShape\(|\.mask\(|\.opacity\(|hasShadow|\.cornerRadius|BezierPath|Canvas\s*\{' "$app" "$menu"
}
check grep -q 'NSPopover()' "$app"
check grep -q 'popover.behavior = .transient' "$app"
check grep -q 'popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)' "$app"
check system_only
check grep -q 'MenuPopoverLayout(content: MenuContent(vm: vm)' "$app"
check grep -q 'popover.contentSize = fitted' "$app"
check grep -q 'geometry.size' Sources/BozoBar/MenuPopoverLayout.swift
check grep -q 'ForEach(vm.state.audioModes)' "$menu"
check grep -q 'Toggle(isOn: Binding' "$menu"
check grep -q 'toggleStyle(.button)' "$menu"
for token in 'SettingsView(vm: vm)' 'vm.selectDevice' 'vm.setAudioMode' 'vm.setCnc' 'vm.setSpatialAudio' 'vm.setStandbyTimer' 'vm.reconnect' 'vm.powerOff' 'Picker("Immersive Audio"' 'Picker("Standby Timer"' 'keyboardShortcut("q", modifiers: .command)'; do
    check grep -Fq "$token" "$menu"
done
for token in 'vm.forgetDevice' 'Toggle("Launch at Login"' 'Toggle("Show Battery in Menu Bar"'; do
    check grep -Fq "$token" "$setting"
done
check grep -q 'NSImage(systemSymbolName: "headphones"' "$app"
check grep -q 'keyEquivalent: "q"' "$app"
check grep -q 'ble.refreshAudioMode()' "$app"
check grep -q 'modeTimer?.invalidate()' "$app"
check git diff --quiet HEAD -- Sources/BozoBar/SettingsView.swift Sources/BozoBar/HeadphoneViewModel.swift Sources/BozoBar/BmapCodec.swift Sources/BozoBar/BmapProtocol.swift Sources/BozoBar/RfcommBmapManager.swift Sources/BozoBar/Models.swift
(( failures == 0 ))
