<p align="center">
  <img src="logo.png" width="256" alt="BozoBar">
</p>

<h1 align="center">BozoBar</h1>

<p align="center">
  macOS menu bar app for controlling Bose QuietComfort and QuietComfort Ultra headphones.
</p>

---

BozoBar lives in your menu bar and talks directly to Bose QuietComfort Ultra
and QuietComfort headphones using the BMAP protocol. No companion app required.

## This fork

**BozoBar is not my project.** It is a fork of [`NerdySouth/bozo-bar`](https://github.com/NerdySouth/bozo-bar),
written by [NerdySouth](https://github.com/NerdySouth) and released under the MIT license. The original
copyright notice is kept unchanged in [LICENSE](LICENSE), the upstream commit history is preserved here
so every change can be traced back to it, and the upstream repository is still configured as the
`upstream` remote.

The protocol knowledge behind the fixes comes from community work published elsewhere:

- [`airvzxf/bose-connect-app-linux`](https://github.com/airvzxf/bose-connect-app-linux) — BMAP packet
  documentation and captures taken on QuietComfort Ultra firmware 1.6.7, which is the same firmware this
  build was tested against.
- [`aaronsb/bosectl`](https://github.com/aaronsb/bosectl) — function-block layout and the observation that
  `SETGET` and `START` are not behind the cloud authentication that `SET` requires.

What this fork changes (full detail in [CHANGELOG.md](CHANGELOG.md)):

- Audio modes are enumerated per slot, because QuietComfort Ultra (Gen 1) answers the `0x1F/0x01`
  "get all modes" query with error `0x05`; without this the mode list stays empty.
- Noise control and immersive audio render as icon grids using SF Symbols, and the highlighted option
  follows the mode the headset reports back rather than a local guess.
- The panel is a system `NSPopover` (macOS draws the frame and material), and the standby timer moved
  into Settings.

**Download:** see [Releases](../../releases). Requires macOS 13 or later. Builds are signed with a
Developer ID certificate; if Gatekeeper still objects, right-click the app and choose *Open*.

**Not affiliated with Bose.** This app talks to the headphones over BMAP, a community
reverse-engineered protocol, not a supported API. Firmware updates can change or break it. Most
settings are written without authentication, so any already-paired device within radio range can change
them too. Keep the official Bose app installed for firmware updates.

---

## 本分支说明

**BozoBar 不是我的原创项目。** 它是 [`NerdySouth/bozo-bar`](https://github.com/NerdySouth/bozo-bar) 的
分支，原作者是 [NerdySouth](https://github.com/NerdySouth)，以 MIT 许可证发布。原始的版权声明在
[LICENSE](LICENSE) 中完整保留，上游的提交历史也一并保留在本仓库里，每一处改动都能追回到它的出处；
上游仓库仍然配置为 `upstream` remote。

这些修复背后的协议知识来自社区已公开的工作：

- [`airvzxf/bose-connect-app-linux`](https://github.com/airvzxf/bose-connect-app-linux)：BMAP 报文文档，
  以及在 QuietComfort Ultra **固件 1.6.7** 上抓取的原始数据包——本分支正是在同版本固件上测试的。
- [`aaronsb/bosectl`](https://github.com/aaronsb/bosectl)：功能块（function block）的划分，以及
  「`SET` 需要云端认证，而 `SETGET` / `START` 不需要」这一关键发现。

本分支改动的内容（细节见 [CHANGELOG.md](CHANGELOG.md)）：

- **按槽位逐个枚举音频模式**：一代 QuietComfort Ultra 对 `0x1F/0x01`（读取全部模式）返回错误 `0x05`，
  不做这一步，模式列表会一直是空的。
- 降噪与沉浸式音频改为**图标网格**（使用 SF Symbols），高亮跟随耳机回报的真实模式，而不是本地猜测。
- 面板改用系统 `NSPopover`（外框与材质由 macOS 绘制），待机定时移入设置页。

**下载**：见 [Releases](../../releases)。需要 macOS 13 或更高版本。构建使用 Developer ID 证书签名；
如果 Gatekeeper 仍然拦截，请在 Finder 中右键点击 App 并选择「打开」。

**与 Bose 官方无关。** 本应用通过 BMAP 与耳机通信，这是社区逆向出来的协议，不是官方支持的接口。
固件更新可能改变甚至破坏它的行为。多数设置写入不需要认证，因此射频范围内任何已配对的设备都能修改
这些设置。请保留官方 Bose App，用于接收固件更新。

---

## Features

| Feature | Description |
|---------|-------------|
| Battery | Live battery percentage and remaining play time |
| Audio Modes | Switch between Quiet, Aware, and custom modes |
| Standby Timer | Set auto-off timeout (5 min to 2 hours, or never) |
| Power Off | Power down headphones from the menu bar |
| Reconnect | Re-scan and reconnect if the connection drops |

## Requirements

- macOS 13.0+
- Bose QuietComfort Ultra Headphones, paired via system Bluetooth settings
- Bose QuietComfort Headphones, paired via system Bluetooth settings
- Bluetooth permission granted to BozoBar

## Install

### Mac App Store

*Coming soon.*

### Build from source

```
swift build
```

Open in Xcode for signing and archiving:

```
open Package.swift
```

## How it works

BozoBar uses the Bose Message Access Protocol (BMAP), a proprietary protocol
reverse-engineered from the Bose Music Android app. It selects the working
transport for each paired device: BLE/GATT for QuietComfort Ultra, and classic
Bluetooth RFCOMM for QuietComfort models that expose BMAP controls there.

The app auto-discovers paired Bose devices on launch, connects, and
queries battery, audio mode, noise cancellation, and standby timer state.

### Architecture

```
BozoBarApp          SwiftUI @main, MenuBarExtra
  └─ HeadphoneViewModel   Published state, forwards to BleManager
           └─ BleManager      CoreBluetooth central + transport selection
                ├─ RfcommBmapManager  Classic Bluetooth BMAP transport
                ├─ BmapCodec       Packet codec, BLE segmentation/reassembly
                └─ BmapProtocol    Query builders and response parsers
```

## Supported devices

- Bose QuietComfort Ultra Headphones
- Bose QuietComfort Headphones

Other Bose headphones that use the BMAP protocol over BLE may also work
but have not been tested.

## Related

[bozo](https://github.com/NerdySouth/bozo) — Rust implementation of the
same protocol, with a background daemon (`bozod`) and terminal UI (`bozo`).
Available on [crates.io](https://crates.io/crates/bozo-proto).

## License

[MIT](LICENSE)
