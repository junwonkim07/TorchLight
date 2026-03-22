# V2Gravity — Project Specification & Technical Report

> Version 0.1.0 | March 2026 | Flutter 3.41.5 / Xray-core v26.2.6

---

## 목차

1. 프로젝트 개요
2. 기술 스택
3. 시스템 아키텍처
4. 화면 구성 및 UI 명세
5. 핵심 모듈: XrayService
6. main.dart 코드 명세
7. xray_service.dart 전체 코드
8. 라우팅 및 설정 로직
9. 플랫폼별 구현 현황
10. 빌드 및 개발 환경
11. 향후 로드맵

---

## 1. 프로젝트 개요

V2Gravity는 Xray-core를 백엔드 엔진으로 사용하는 크로스플랫폼 VPN 클라이언트입니다. 기존 V2RayN, Hiddify 등의 도구가 비전문가에게 너무 복잡하다는 문제의식에서 출발했으며, `vless://` 링크 하나만 붙여넣으면 즉시 연결되는 UX를 핵심 목표로 합니다.

| 항목       | 내용                                                        |
| ---------- | ----------------------------------------------------------- |
| 프로젝트명 | V2Gravity                                                   |
| 목적       | 비전문가도 쉽게 쓸 수 있는 VLESS/Xray VPN 클라이언트        |
| 플랫폼     | Windows ARM64 / Android / iOS / macOS (Flutter)             |
| 코어       | Xray-core v26.2.6 (XTLS/Xray-core)                          |
| 프레임워크 | Flutter 3.41.5 / Dart 3.11.3                                |
| 언어       | Dart / Kotlin (Android) / C++ (Windows native)              |
| 개발환경   | Windows 11 ARM64, Surface Pro 11, VS Code, Build Tools 2022 |
| 현재 상태  | UI 완성 / XrayService Windows 구현 완료 / Android 설계 완료 |

### 핵심 목표

* 복잡한 설정 없이 `vless://` 링크 붙여넣기만으로 즉시 연결
* Android / iOS / Windows / macOS 동일한 UI/UX (Flutter 단일 코드베이스)
* Xray-core ARM64 네이티브 바이너리 번들링으로 최적 성능
* 글래스모피즘 다크 테마 (`#262624` 배경) 기반 세련된 디자인
* 중국 우회, DNS 우회, 앱별 제외 등 고급 라우팅 기능 지원
* 시스템 프록시 및 VPN 터널 두 가지 연결 모드 지원

---

## 2. 기술 스택

| 분류          | 기술            | 버전                | 용도                       |
| ------------- | --------------- | ------------------- | -------------------------- |
| UI 프레임워크 | Flutter         | 3.41.5              | 크로스플랫폼 UI 전체       |
| 언어          | Dart            | 3.11.3              | 앱 로직 전체               |
| VPN 엔진      | Xray-core       | v26.2.6             | VLESS 터널링 / 라우팅      |
| 폰트          | Noto Sans KR    | google_fonts ^6.2.1 | 한국어 UI 렌더링           |
| 경로          | path_provider   | ^2.1.4              | 바이너리 추출 디렉토리     |
| 아이콘        | cupertino_icons | ^1.0.8              | iOS 스타일 아이콘          |
| Android       | Kotlin          | -                   | VpnService / MethodChannel |
| Windows       | reg.exe / C++   | -                   | 시스템 프록시 / TUN 터널   |

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.8
  path_provider: ^2.1.4

flutter:
  uses-material-design: true
  assets:
    - assets/xray/xray.exe        # Xray-core Windows ARM64
    - assets/xray/geoip.dat       # IP 지역 데이터베이스
    - assets/xray/geosite.dat     # 도메인 분류 데이터베이스
```

---

## 3. 시스템 아키텍처

```
┌──────────────────────────────────────────────────────┐
│                   Flutter UI Layer                    │
│    MainScreen / AddServerScreen / SettingsScreen      │
└───────────────────────┬──────────────────────────────┘
                        │  Dart API 호출
┌───────────────────────▼──────────────────────────────┐
│              XrayService  (lib/xray_service.dart)     │
│  _extractBinary()   assets → 앱 지원 디렉토리 추출   │
│  _writeConfig()     서버 정보 → config.json 생성      │
│  start() / stop()   Process.start() / kill()         │
│  ping()             TCP Socket 응답 시간 측정         │
│  _setSystemProxy()  Windows 레지스트리 프록시 설정    │
└───────────────────────┬──────────────────────────────┘
                        │  Process.start(xray.exe, [run, -c, config.json])
┌───────────────────────▼──────────────────────────────┐
│            Xray-core 프로세스  (ARM64 네이티브)        │
│   inbound  SOCKS5 :10808  /  HTTP :10809             │
│   outbound VLESS → 원격 서버 (WS / gRPC / TCP)       │
│   routing  geoip:private → direct                    │
│            geosite:cn, geoip:cn → direct (선택)      │
└───────────────────────┬──────────────────────────────┘
                        │  암호화된 VLESS 트래픽
┌───────────────────────▼──────────────────────────────┐
│             원격 VLESS 서버                           │
│   전송: WebSocket / gRPC / TCP                       │
│   보안: TLS / Reality / None                         │
└──────────────────────────────────────────────────────┘
```

### 데이터 흐름

| 단계 | 주체            | 동작                                                        |
| ---- | --------------- | ----------------------------------------------------------- |
| 1    | 사용자          | vless:// 링크 붙여넣기 또는 직접 입력                       |
| 2    | AddServerScreen | URI 파싱 → host, port, uuid, transport, security 추출      |
| 3    | MainScreen      | 연결 버튼 탭 → _toggleConnect() → XrayService.start()     |
| 4    | XrayService     | 바이너리 추출 → config.json 생성 → xray.exe 프로세스 실행 |
| 5    | XrayService     | 500ms 대기 후 Windows 레지스트리 프록시 활성화              |
| 6    | xray-core       | SOCKS5/HTTP 로컬 수신 → VLESS로 원격 서버 전달             |
| 7    | 사용자          | 연결 해제 → stop() → 프록시 비활성화 → 프로세스 kill()   |

---

## 4. 화면 구성 및 UI 명세

### MainScreen — 메인 화면

* 헤더: 앱 로고(`v2gravity`) + 핑테스트(번개) / 새로고침 / 설정 아이콘
* 연결 버튼: 정사각형 R=20, 연결 시 `#1D9E75` 초록 / 해제 시 반투명 흰색
* 버튼 모핑: `AnimationController` 400ms easeInOut 색상/크기 전환
* 연결 타이머: `Opacity` 위젯으로 레이아웃 고정 후 fade 처리 (위치 흔들림 없음)
* 서버 목록: `ListView`, 글래스 카드, 핑 배지 (초록 <50ms / 황 <150ms / 빨 ≥150ms)
* 서버 추가 버튼: 점선 테두리 + 아이콘

### AddServerScreen — 서버 추가

* 탭 구성: 링크 붙여넣기 / QR 코드 (`AnimatedContainer` 탭 전환)
* 링크 탭: `TextField` 실시간 입력 감지 → URI 파싱 → 파싱 결과 카드 표시
* 파싱 결과: 이름, 서버, 포트, UUID(앞 8자리 + ••••), 전송/보안
* 저장 시 `Navigator.pop(context, result)`로 MainScreen에 반환
* QR 탭: `mobile_scanner` 패키지 예정 (현재 placeholder)
* 트랜지션: 아래서 위로 슬라이드 (`Offset(0, 1) → Offset.zero`)

### SettingsScreen — 설정

* **연결 섹션** : 자동연결, 자동재연결 `CupertinoSwitch`, 로컬 포트 `DropdownButton`
* **우회 설정** : 전체 우회 / 중국 제외 카드 선택 (`AnimatedContainer`)
* **앱별 제외** : `CupertinoSwitch`로 앱 단위 VPN 우회 설정 (카카오뱅크, 토스 등 기본 제외)
* **앱 섹션** : 언어, 테마 드롭다운, 백그라운드 실행 토글, 코어 버전 표시
* **데이터 섹션** : 서버 목록 초기화 (`CupertinoAlertDialog` 확인)
* 트랜지션: 오른쪽에서 슬라이드 (`Offset(1, 0) → Offset.zero`)

### 디자인 시스템

| 항목          | 값                                        |
| ------------- | ----------------------------------------- |
| 배경색        | `#262624`(다크 브라운-블랙)             |
| 글래스 카드   | `rgba(255,255,255,0.13)`+ 0.5px 테두리  |
| 강조색 Green  | `#1D9E75`(연결됨, 선택, 버튼)           |
| 강조색 Teal   | `#5DCAA5`(낮은 핑, 상태 도트)           |
| 경고색 Amber  | `#EF9F27`(중간 핑)                      |
| 위험색 Red    | `#F09595`(높은 핑, 에러)                |
| 폰트          | Noto Sans KR (google_fonts),`w300`Light |
| Border Radius | 카드 14px, 버튼 20px, 배지 99px(pill)     |

---

## 5. 핵심 모듈: XrayService

`XrayService`는 Flutter Dart 레이어에서 Xray-core 프로세스를 완전히 제어하는 서비스 클래스입니다. Windows 환경에서는 `MethodChannel` 없이 `dart:io`의 `Process` API로 직접 프로세스를 실행합니다.

### 메서드 명세

| 메서드                    | 설명                                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------------------ |
| `_extractBinary()`      | assets에서 xray.exe, geoip.dat, geosite.dat를 앱 지원 디렉토리로 추출. 이미 존재하면 스킵.       |
| `_writeConfig()`        | 서버 정보를 받아 Xray JSON config 생성. bypassChina 옵션으로 중국 도메인/IP 직접 연결 규칙 추가. |
| `_setSystemProxy(bool)` | Windows 레지스트리 수정해 HTTP 프록시 `127.0.0.1:10809`활성화/비활성화.                        |
| `ping(host, port)`      | TCP `Socket.connect()`로 응답시간 측정. 3초 타임아웃. 실패 시 null 반환.                       |
| `start({...})`          | 바이너리 추출 → config 생성 →`Process.start()`→ 500ms 후 시스템 프록시 활성화.              |
| `stop()`                | 시스템 프록시 비활성화 → 프로세스 `kill()`→`_process = null`.                              |

### config.json 구조

```json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "socks", "port": 10808,
      "listen": "127.0.0.1", "protocol": "socks",
      "settings": { "udp": true }
    },
    {
      "tag": "http", "port": 10809,
      "listen": "127.0.0.1", "protocol": "http"
    }
  ],
  "outbounds": [
    {
      "tag": "proxy", "protocol": "vless",
      "settings": {
        "vnext": [{
          "address": "<host>", "port": 443,
          "users": [{ "id": "<uuid>", "encryption": "none", "flow": "" }]
        }]
      },
      "streamSettings": {
        "network": "ws|grpc|tcp",
        "security": "tls|none",
        "tlsSettings": { "serverName": "<sni>", "allowInsecure": false },
        "wsSettings": { "path": "/" }
      }
    },
    { "tag": "direct", "protocol": "freedom" },
    { "tag": "block",  "protocol": "blackhole" }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      { "outboundTag": "direct", "ip": ["geoip:private"] },
      { "outboundTag": "direct", "domain": ["geosite:cn"] },
      { "outboundTag": "direct", "ip": ["geoip:cn"] }
    ]
  }
}
```

---

## 6. main.dart 코드 명세

### 파일 구조

```
lib/
  main.dart            ← UI 전체 (3개 화면)
  xray_service.dart    ← Xray-core 프로세스 제어

assets/
  xray/
    xray.exe           ← Xray-core Windows ARM64 바이너리
    geoip.dat          ← IP 지역 데이터베이스
    geosite.dat        ← 도메인 분류 데이터베이스

android/
  app/src/main/
    AndroidManifest.xml
    kotlin/.../
      MainActivity.kt       ← MethodChannel 브릿지
      XrayVpnService.kt     ← Android VPN 서비스 (예정)
```

### 클래스 구조

| 클래스               | 타입            | 역할                                           |
| -------------------- | --------------- | ---------------------------------------------- |
| `V2Gravity`        | StatelessWidget | 앱 루트, MaterialApp, 다크 테마                |
| `MainScreen`       | StatefulWidget  | 메인 화면, 서버 목록, 연결 상태                |
| `_MainScreenState` | State           | connected, servers, timer, AnimationController |
| `AddServerScreen`  | StatefulWidget  | 서버 추가 (링크 파싱, QR)                      |
| `SettingsScreen`   | StatefulWidget  | 설정 화면, CupertinoSwitch, Dropdown           |

### _MainScreenState 핵심 상태

```dart
bool connected = false;               // 연결 상태
int selectedIndex = 0;                // 선택된 서버 인덱스
int elapsedSeconds = 0;               // 연결 경과 시간 (초)
Timer? _timer;                        // 1초 간격 타이머
AnimationController _morphController; // 버튼 모핑 애니메이션 (400ms)
Animation<double> _morphAnim;         // easeInOut 커브

List<Map<String, dynamic>> servers = [
  {
    'flag': '🇯🇵', 'name': '일본 도쿄',
    'meta': 'VLESS · WS · TLS',
    'ping': '12ms', 'pingLevel': 0,
    'host': 'example.com', 'port': '443',
    'uuid': 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    'transportType': 'ws', 'security': 'tls',
  },
];
```

### 연결 토글 로직

```dart
void _toggleConnect() async {
  if (!connected) {
    final server = servers[selectedIndex];
    final success = await XrayService.start(
      address: server['host'] ?? '',
      port: int.tryParse(server['port']?.toString() ?? '443') ?? 443,
      uuid: server['uuid'] ?? '',
      transport: server['transportType'] ?? 'ws',
      security: server['security'] ?? 'tls',
      sni: server['host'] ?? '',
      bypassChina: false,
    );
    if (!success) return; // 실패 시 상태 변경 안 함
  } else {
    await XrayService.stop();
  }
  setState(() => connected = !connected);
  if (connected) {
    _morphController.forward(); // 버튼 초록으로 모핑
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() => elapsedSeconds++);
    });
  } else {
    _morphController.reverse(); // 버튼 회색으로 모핑
    _timer?.cancel();
    elapsedSeconds = 0;
  }
}
```

### 화면 전환

```dart
// 서버 추가 — 아래서 위로 슬라이드
void _goToAddServer() async {
  final result = await Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, animation, __) => const AddServerScreen(),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1), end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation, curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
  if (result != null && result is Map<String, dynamic>) {
    setState(() => servers.add(result));
  }
}

// 설정 — 오른쪽에서 슬라이드
void _goToSettings() {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, animation, __) => const SettingsScreen(),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0), end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation, curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
```

---

## 7. xray_service.dart 전체 코드

```dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class XrayService {
  static Process? _process;
  static bool get isRunning => _process != null;

  // ─── 바이너리 추출 ───
  static Future<String> _extractBinary() async {
    final dir = await getApplicationSupportDirectory();
    final xrayFile = File('${dir.path}/xray.exe');
    final geoip = File('${dir.path}/geoip.dat');
    final geosite = File('${dir.path}/geosite.dat');

    if (!xrayFile.existsSync()) {
      final data = await rootBundle.load('assets/xray/xray.exe');
      await xrayFile.writeAsBytes(data.buffer.asUint8List());
    }
    if (!geoip.existsSync()) {
      final data = await rootBundle.load('assets/xray/geoip.dat');
      await geoip.writeAsBytes(data.buffer.asUint8List());
    }
    if (!geosite.existsSync()) {
      final data = await rootBundle.load('assets/xray/geosite.dat');
      await geosite.writeAsBytes(data.buffer.asUint8List());
    }
    return xrayFile.path;
  }

  // ─── config.json 생성 ───
  static Future<String> _writeConfig({
    required String address,
    required int port,
    required String uuid,
    required String transport,
    required String security,
    required String sni,
    required bool bypassChina,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final configFile = File('${dir.path}/config.json');

    final config = {
      "log": {"loglevel": "warning"},
      "inbounds": [
        {
          "tag": "socks", "port": 10808, "listen": "127.0.0.1",
          "protocol": "socks", "settings": {"udp": true}
        },
        {
          "tag": "http", "port": 10809, "listen": "127.0.0.1",
          "protocol": "http",
        }
      ],
      "outbounds": [
        {
          "tag": "proxy", "protocol": "vless",
          "settings": {
            "vnext": [{
              "address": address, "port": port,
              "users": [{"id": uuid, "encryption": "none", "flow": ""}]
            }]
          },
          "streamSettings": {
            "network": transport,
            "security": security,
            if (security == "tls")
              "tlsSettings": {"serverName": sni, "allowInsecure": false},
            if (transport == "ws")
              "wsSettings": {"path": "/"},
            if (transport == "grpc")
              "grpcSettings": {"serviceName": ""},
          }
        },
        {"tag": "direct", "protocol": "freedom", "settings": {}},
        {"tag": "block",  "protocol": "blackhole", "settings": {}}
      ],
      "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
          {"type": "field", "outboundTag": "direct", "ip": ["geoip:private"]},
          if (bypassChina) ...[
            {"type": "field", "outboundTag": "direct", "domain": ["geosite:cn"]},
            {"type": "field", "outboundTag": "direct", "ip": ["geoip:cn"]},
          ]
        ]
      }
    };

    await configFile.writeAsString(jsonEncode(config));
    return configFile.path;
  }

  // ─── 시스템 프록시 설정 (Windows 레지스트리) ───
  static Future<void> _setSystemProxy(bool enable) async {
    if (!Platform.isWindows) return;
    const key =
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings';
    if (enable) {
      await Process.run('reg', ['add', key, '/v', 'ProxyEnable',
        '/t', 'REG_DWORD', '/d', '1', '/f']);
      await Process.run('reg', ['add', key, '/v', 'ProxyServer',
        '/t', 'REG_SZ', '/d', '127.0.0.1:10809', '/f']);
    } else {
      await Process.run('reg', ['add', key, '/v', 'ProxyEnable',
        '/t', 'REG_DWORD', '/d', '0', '/f']);
    }
  }

  // ─── 핑 테스트 ───
  static Future<int?> ping(String host, int port) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 3));
      stopwatch.stop();
      socket.destroy();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  // ─── 시작 ───
  static Future<bool> start({
    required String address,
    required int port,
    required String uuid,
    required String transport,
    required String security,
    required String sni,
    bool bypassChina = false,
    bool useSystemProxy = true,
  }) async {
    try {
      if (_process != null) await stop();
      final xrayPath   = await _extractBinary();
      final configPath = await _writeConfig(
        address: address, port: port, uuid: uuid,
        transport: transport, security: security,
        sni: sni, bypassChina: bypassChina,
      );
      _process = await Process.start(xrayPath, ['run', '-c', configPath]);
      _process!.stdout.transform(utf8.decoder).listen((l) => print('[xray] $l'));
      _process!.stderr.transform(utf8.decoder).listen((l) => print('[xray err] $l'));
      if (useSystemProxy) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _setSystemProxy(true);
      }
      return true;
    } catch (e) {
      print('[XrayService] start error: $e');
      return false;
    }
  }

  // ─── 종료 ───
  static Future<void> stop() async {
    await _setSystemProxy(false);
    _process?.kill();
    _process = null;
  }
}
```

---

## 8. 라우팅 및 설정 로직

### 우회 모드

| 모드      | 동작                        | 라우팅 규칙                          |
| --------- | --------------------------- | ------------------------------------ |
| 전체 우회 | 모든 트래픽 → 프록시       | `geoip:private`만 direct           |
| 중국 제외 | 중국 도메인/IP → 직접 연결 | `geosite:cn`,`geoip:cn`→ direct |

### 로컬 포트

| 포트  | 프로토콜 | 용도                             |
| ----- | -------- | -------------------------------- |
| 10808 | SOCKS5   | 기본 로컬 프록시 (UDP 지원)      |
| 10809 | HTTP     | HTTP 프록시 (시스템 프록시 등록) |

### 앱별 제외 (Android 전용)

Android `VpnService.Builder`의 `addDisallowedApplication(packageName)`을 사용해 특정 앱을 VPN 터널에서 제외합니다. 금융 앱(카카오뱅크, 토스 등)은 VPN 환경에서 보안 정책으로 차단되는 경우가 많아 기본값으로 제외 설정됩니다.

```kotlin
// Android XrayVpnService.kt
val builder = Builder()
    .setSession("V2Gravity")
    .addAddress("10.0.0.1", 24)
    .addDnsServer("8.8.8.8")
    .addRoute("0.0.0.0", 0)
    .addDisallowedApplication("com.kakaobank.channel")
    .addDisallowedApplication("viva.republica.toss")
```

---

## 9. 플랫폼별 구현 현황

| 플랫폼  | 연결 방식     | 상태         | 비고               |
| ------- | ------------- | ------------ | ------------------ |
| Windows | 시스템 프록시 | ✅ 구현 완료 | 레지스트리 reg.exe |
| Windows | TUN 터널      | 🔄 예정      | wintun.dll 필요    |
| Android | VPN 터널      | 🔄 설계 완료 | VpnService API     |
| iOS     | VPN 터널      | ❌ 미구현    | NetworkExtension   |
| macOS   | 시스템 프록시 | ❌ 미구현    | networksetup 명령  |

### Windows 구현 세부

* Xray-core ARM64 바이너리 번들링 완료
* `XrayService.start/stop` Dart `Process` API로 구현 완료
* 시스템 프록시 레지스트리 설정 구현 완료
* Visual Studio Build Tools 2022 + C++ 워크로드 필요
* TUN 터널 모드: wintun.dll 연동 예정

### Android 구현 설계

```kotlin
// XrayVpnService.kt 구조
class XrayVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var xrayProcess: Process? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startVpn(intent.getStringExtra("config") ?: "")
            ACTION_STOP  -> stopVpn()
        }
        return START_NOT_STICKY
    }

    private fun startVpn(configJson: String) {
        // 1. config.json 저장
        // 2. xray 바이너리 추출 및 실행 권한 부여
        // 3. ProcessBuilder로 xray 실행
        // 4. VpnService.Builder로 TUN 인터페이스 생성
    }
}
```

---

## 10. 빌드 및 개발 환경

### 요구사항

| 항목          | 요구사항                                               |
| ------------- | ------------------------------------------------------ |
| OS            | Windows 11 ARM64 (Surface Pro 11, Snapdragon X)        |
| Flutter       | stable 3.41.5 (PATH:`C:\flutter\bin`)                |
| Dart          | 3.11.3                                                 |
| Visual Studio | Build Tools 2022 + Desktop development with C++        |
| Android SDK   | Android Studio ARM 버전 (모바일 빌드 시)               |
| VS Code       | ARM64 버전 + Flutter 확장                              |
| Xray-core     | v26.2.6 Windows ARM64 (`Xray-windows-arm64-v8a.zip`) |

### 빌드 명령어

```powershell
# 환경 점검
flutter doctor

# 의존성 설치
flutter pub get

# Windows 앱 실행 (개발)
flutter run -d windows

# Windows 릴리즈 빌드
flutter build windows --release

# Android APK (ARM64 전용)
flutter build apk --target-platform android-arm64 --split-per-abi

# 웹 (UI 개발용, Xray 기능 없음)
flutter run -d chrome
```

### 프로젝트 디렉토리 구조

```
V2Gravity/
├── lib/
│   ├── main.dart              # UI 전체
│   └── xray_service.dart      # Xray 프로세스 제어
├── assets/
│   └── xray/
│       ├── xray.exe           # ARM64 바이너리
│       ├── geoip.dat
│       └── geosite.dat
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/.../
│           ├── MainActivity.kt
│           └── XrayVpnService.kt
├── windows/                   # Flutter Windows 네이티브
├── pubspec.yaml
└── README.md
```

---

## 11. 향후 로드맵

### 단기 (1~2주)

* Visual Studio Build Tools 설치 → `flutter run -d windows` 성공
* 실제 vless:// 서버 연결 테스트
* 핑 테스트 버튼 실제 동작 연결 (`XrayService.ping()`)
* 구성 업데이트: 구독 URL HTTP 갱신 기능 (`http` 패키지)
* 서버 목록 로컬 영구 저장 (`shared_preferences`)

### 중기 (1~2달)

* Android VpnService 완성 및 실기기 테스트
* QR 스캔 (`mobile_scanner`) 연동
* Windows TUN 터널 모드 (wintun.dll)
* 앱별 제외 Android 실제 구현
* 연결 로그 화면 구현
* 자동 연결 / 재연결 로직

### 장기 (3달+)

* iOS / macOS NetworkExtension 구현
* Reality, VLESS+XTLS 프로토콜 완전 지원
* 구독 관리 (다중 구독 URL)
* 실시간 속도 표시 (다운로드/업로드 MB/s)
* 다국어 지원 (English, 中文)
* 앱 서명 및 배포 (Google Play, Microsoft Store)

---

*본 문서는 V2Gravity 프로젝트의 현재 상태(2026년 3월)를 기준으로 작성되었습니다.*
