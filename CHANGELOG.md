# Changelog

All notable changes to this local build. Upstream commits are preserved in history; entries below cover only local work.

## 1.0.6 — build 8

### Fixed
- Clicking anywhere outside the panel now dismisses it. A status-bar popover only honours
  `.transient` once the app is active and the popover window is key, so the panel activates the
  app and makes itself key when it opens.
- The keyboard focus ring no longer draws a blue frame around a noise-control cell
  (`focusEffectDisabled`); selection is still shown by the blue disc.

## 1.0.5 — build 7

### Changed
- Unselected noise-control options now show a grey disc of exactly the same size as the selected blue one, so nothing shifts when the selection moves.
- Selecting an option blooms the blue disc out of its centre with a spring curve; the grey disc fades out and the glyph switches to white.

## 1.0.4 — build 6

### Added
- Noise control is now an icon-over-label grid: `person.crop.circle` (Quiet), `person.wave.2` (Aware), `person.and.background.dotted` (Immersion). The highlighted cell mirrors the mode read back from the headset.
- Immersive audio uses the same grid: `speaker.slash` (Off), `dot.radiowaves.left.and.right` (Still), `move.3d` (Motion).

### Changed
- Standby Timer moved out of the panel into Settings.
- Reconnect / Power Off / Quit now use bordered system buttons instead of bare text.
- Panel sections keep system typography and the single system popover; no custom chrome is drawn.

## 1.0.3 — build 5

### Fixed
- Audio mode list stayed empty on QuietComfort Ultra (Gen 1, firmware 1.6.7): the headset answers the `0x1F/0x01` "get all modes" query with error `0x05`. Modes are now enumerated per slot (`0x1F/0x06`, slots 0–9) when that query yields nothing.
- Selection no longer follows a local guess: tapping a row sends the switch command and the highlight waits for the headset's read-back. Opening the popover reads the current mode immediately and keeps polling every two seconds while it is open.
- Package linked against the deployment target as its SDK (13.0), which prevented the modern system appearance. The build now verifies `minos` and `sdk` with `vtool` before packaging.

### Changed
- The status item hosts the system `NSPopover`; macOS draws the only frame and material. No custom panel, glass layer, corner radius, or window shadow is added by the app.
- Device and Settings pages keep their upstream layout and controls. The popover follows the natural height of the active page instead of reserving the taller one.
- Selected row uses a system button toggle (`.buttonStyle(.button)`) instead of a hand-drawn checkmark.

### Added
- `scripts/package-local.sh` builds an isolated bundle with the layered app icon, legacy `.icns` fallback and signature checks.
- `tests/` contract checks for mode enumeration, switch commands, immersive audio commands and offscreen page sizing.

## 1.0.2 — build 3

### Fixed
- Immersive Audio (Off / Still / Motion) returned to the panel.
- Status item restored to the system headphones symbol with the original battery preference; the supplied artwork is used for the app icon only.

## 1.0.1 — build 2

### Added
- Initial local build: menu bar panel, Quiet / Aware switching, custom app icon.
