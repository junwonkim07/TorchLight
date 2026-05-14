<div align="center">

<img src="assets/icon/torch-light_light.png" width="120" alt="TorchLight Icon"/>

# TorchLight

**The internet was built for everyone.**
<p><b>Reclaim it.</b><p>

[한국어](README_kr.md)/[中文](README_cn.md)

[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-brightgreen?style=flat-square)](https://github.com/junwonkim07/TorchLight)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/github/license/junwonkim07/TorchLight?style=flat-square)](LICENSE.md)
[![Release](https://img.shields.io/github/v/release/junwonkim07/TorchLight?style=flat-square)](https://github.com/junwonkim07/TorchLight/releases)

</div>

---

## What is TorchLight?

TorchLight is a free, open-source VPN client built for people living under internet censorship.

Built on [Sing-box](https://github.com/SagerNet/sing-box) with support for the latest protocols, TorchLight is designed to work in the world's most restrictive environments

---

## Features

- **Multi-protocol support** — VLESS, REALITY, VMess, Trojan, Hysteria2, Shadowsocks, WireGuard and more
- **Auto protocol switching** — intelligently selects the best protocol for your network
- **Marzban compatible** — works seamlessly with your existing Marzban panel
- **Subscription link support** — import from any proxy management panel
- **Dark & light mode** — clean, minimal UI that stays out of your way
- **Free to use** — no ads, no tracking, no compromises
- **Open source** — auditable, transparent, community-driven

---

## Supported Platforms

| Platform | Status |
|----------|--------|
| Android | ✅ Supported |
| iOS | ✅ Supported |
| Windows | 🔜 Coming soon |
| macOS | 🔜 Coming soon |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x
- [Android Studio](https://developer.android.com/studio) with Flutter & Dart plugins
- [Go](https://go.dev/dl/) (for building Sing-box core)
- Android NDK (via Android Studio SDK Manager)

### Installation

```bash
# Clone the repository
git clone https://github.com/junwonkim07/TorchLight
cd TorchLight

# Initialize submodules (includes Sing-box core)
git submodule update --init --recursive

# Install Flutter dependencies
flutter pub get

# Run on connected device
flutter run
```

### Build APK

```bash
flutter build apk --release
```

---

## Configuration

TorchLight works with any subscription link.

1. Open TorchLight
2. Tap **Add Profile**
3. Paste your subscription URL or scan a QR code
4. Tap **Connect**

---

## Protocol Support

| Protocol | Description |
|----------|-------------|
| VLESS + REALITY | Best stealth, recommended for China & Russia |
| Hysteria2 | High speed on unstable networks (QUIC/UDP) |
| Trojan | HTTPS camouflage, CDN-friendly |
| Shadowsocks 2022 | Lightweight, wide compatibility |
| VMess | Legacy support |
| WireGuard | Fast tunneling |

---

## Contributing

Contributions are welcome. If you'd like to help, areas we need most:

- Flutter / Dart development
- iOS (Swift)
- Android (Kotlin)
- Translations

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

---

## License

TorchLight is licensed under the [MIT License](LICENSE.md).
