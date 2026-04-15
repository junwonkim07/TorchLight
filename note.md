[https://github.com/hiddify/hiddify-app](https://github.com/hiddify/hiddify-app) 이거 custumizing

**오후 2:52**

Hiddify 레포 구조부터 파악할게요.

**Fetched: GitHub - hiddify/hiddify-app: Multi-platform auto-proxy client, supporting Sing-box, X-ray, TUIC, Hysteria, Reality, Trojan, SSH etc. It’s an open-source, secure and ad-free.**

Fetched: GitHub - hiddify/hiddify-app: Multi-platform auto-proxy client, supporting Sing-box, X-ray, TUIC, Hysteria, Reality, Trojan, SSH etc. It’s an open-source, secure and ad-free.

이제 `lib` 폴더 구조를 봐야 어디를 손봐야 할지 알 수 있어요.

**웹 검색됨**

웹 검색됨

좋습니다. `lib/features` 구조까지 파악됐습니다. 이제 커스터마이징 전체 플랜을 정리해드릴게요.

---

## Hiddify 포크 커스터마이징 전체 플랜

### 📁 레포 구조 파악

```
hiddify-app/
├── lib/
│   ├── features/          ← 핵심 기능 (여기를 주로 수정)
│   │   ├── profile/       ← 구독링크 관리 → 🔧 가장 많이 수정
│   │   ├── connection/    ← 연결/해제 로직
│   │   ├── home/          ← 메인 화면
│   │   └── settings/      ← 설정 (split tunneling 등)
├── assets/
│   ├── translations/      ← 언어 파일 (ko.json 등)
│   └── images/            ← 아이콘, 로고 → 🔧 브랜딩 교체
├── android/ ios/ windows/ macos/ linux/  ← 플랫폼별 설정
└── pubspec.yaml           ← 앱 이름, 패키지명
```

---

### 🔧 커스터마이징 해야 할 것들 (우선순위 순)

**1단계 — 브랜딩 (1~2일)**

| 파일                         | 수정 내용                                |
| ---------------------------- | ---------------------------------------- |
| `pubspec.yaml`             | `name:`, `description:` 변경         |
| `android/app/build.gradle` | `applicationId` 변경 (com.yourapp.vpn) |
| `ios/Runner/Info.plist`    | 앱 이름, Bundle ID                       |
| `assets/images/`           | 로고, 아이콘 교체                        |
| `windows/runner/`          | 앱 이름, 아이콘                          |

**2단계 — 구독링크 고정 (2~3일)**

현재 Hiddify는 유저가 직접 구독 URL을 추가하는 구조입니다. 이걸 아래처럼 바꿔야 합니다:

```
현재: 유저가 + 버튼 눌러서 구독 URL 직접 입력
목표: 로그인 → Marzban API → 구독 URL 자동 주입 (유저는 못 봄)
```

수정 파일: `lib/features/profile/` 전체

**3단계 — Marzban 로그인 추가 (3~4일)**

새로 만들 화면:

dart

```dart
// lib/features/auth/
├── login_page.dart        ← 이메일 + 비번 입력
├── auth_notifier.dart     ← Marzban/api/token 호출
└── auth_repository.dart   ← JWT 저장, 만료 처리
```

Marzban API 흐름:

```
POST /api/token
  body: { username, password }
  → access_token 반환

GET /api/user/me  (Authorization: Bearer <token>)
  → subscription_url 반환
  → expire, data_limit 등
```

**4단계 — 외부 구독 추가 차단 (1일)**

`lib/features/profile/` 에서:

* `+` 버튼 제거
* URL 입력 폼 제거
* 내 서버 구독링크만 자동 로드되도록

**5단계 — Split Tunneling / 라우팅 모드 (2~3일)**

Hiddify에 이미 있는 기능이지만 GFW 최적화 필요:

```
스마트 모드: 중국 IP/도메인 → 직접 연결
             해외 트래픽  → Xray 터널
전체 모드: 모든 트래픽 → Xray
```

라우팅 룰 파일: `assets/rules/` (geosite, geoip 기반)

**6단계 — Kill Switch (2일)**

플랫폼별로 구현 방식이 다릅니다:

* **Android** : Always-on VPN + `lockdownEnabled = true` (OS 내장)
* **iOS** : Network Extension의 `enforceRoutes`
* **Windows** : WFP (Windows Filtering Platform) 방화벽 룰
* **macOS** : pf firewall 룰

---

### 🚀 개발 시작 순서 (추천)

```
1. GitHub에서 포크 → 로컬 클론
2. Flutter 환경 세팅 (Flutter 3.x, Dart)
3. 브랜딩 교체 → 빌드 확인
4. Marzban 로그인 화면 추가
5. 구독 자동 주입 로직
6. 외부 구독 추가 UI 제거
7. Split Tunneling UI 정리
8. Kill Switch 추가
```

---

어떤 단계부터 코드 작성 들어갈까요?

* **바로 로그인 화면 Dart 코드** 작성?
* **Marzban API 연동** 코드부터?
* **브랜딩 변경** 파일 목록 구체적으로?
