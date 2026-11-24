# Local QC Ultra build

BozoBar keeps the upstream SwiftUI device list, immersive audio, standby timer, reconnect, power off and Settings. The status item anchors an AppKit `NSPopover`; macOS draws the only frame and its material, including Liquid Glass on supported releases. The app does not add a panel, a material layer, or a custom shadow. The popover uses the current page's natural height when switching between device and settings.

The audio rows retain every preset enumerated by the connected headset. A system button toggle highlights the active row without a checkmark. Opening the popover sends an immediate GET for the current mode, then polls every two seconds until the popover closes. No settings, login items, or headset profiles are changed by installing this build. The custom artwork is used for the App icon only; the status item still uses the system headphones symbol and the original battery preference.

Build and verify an isolated package on a Mac with the macOS 26+ SDK:

```sh
bash scripts/package-local.sh
```

The command runs the panel contract and checks BMAP commands and the native hosting layout, creates a native layered app icon and a legacy fallback, then validates the bundle and signature. It also checks the linked macOS SDK with `vtool` before packaging. The fallback build engine is intentional: the default Swift Build engine recorded the deployment target as the linked SDK, which does not establish eligibility for the system's modern appearance. Generated artwork is under `design/`, together with the original supplied image. To regenerate PNG layers (requires Python and FFmpeg):

```sh
python3 design/make-art.py 'design/极简黑色耳机图标.png' design/generated
cp design/generated/Foreground.png design/AppIcon.icon/Assets/Foreground.png
```

Manual acceptance: open the status item over a contrasting window, verify the native glass frame and both lower corners, enter Settings and return to verify both page heights, toggle Quiet/Aware on the Mac, then toggle on the headset while the panel is open and verify the background highlight moves after the readback. Confirm that clicking away, Escape and ⌘Q perform their respective actions.
