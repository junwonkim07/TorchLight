import 'dart:async';
import 'dart:io';
import 'xray_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

void main() {
  runApp(const V2Gravity());
}

class V2Gravity extends StatelessWidget {
  const V2Gravity({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'V2Gravity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ).copyWith(
          bodyMedium: GoogleFonts.notoSansKr(
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
          bodySmall: GoogleFonts.notoSansKr(
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

const kBg = Color(0xFF262624);
const kGlass = Color(0x22FFFFFF);
const kGlassBorder = Color(0x30FFFFFF);
const kGreen = Color(0xFF1D9E75);

// ─────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  bool connected = false;
  int selectedIndex = 0;
  int elapsedSeconds = 0;
  Timer? _timer;
  late AnimationController _morphController;
  late Animation<double> _morphAnim;

  List<Map<String, dynamic>> servers = [
    ];

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _morphAnim = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOut,
    );
  }

  Color get pingColor {
    final level = servers[selectedIndex]['pingLevel'];
    if (level == 0) return const Color(0xFF5DCAA5);
    if (level == 1) return const Color(0xFFEF9F27);
    return const Color(0xFFF09595);
  }

  String get elapsedFormatted {
    final h = (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

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
    if (!success) return;
  } else {
    await XrayService.stop();
  }

  setState(() => connected = !connected);
  if (connected) {
    _morphController.forward();
    elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => elapsedSeconds++);
    });
  } else {
    _morphController.reverse();
    _timer?.cancel();
    elapsedSeconds = 0;
  }
}

  void _goToAddServer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddServerScreen(),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() => servers.add(result));
    }
  }

  void _goToSettings() {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, animation, _) => const SettingsScreen(),
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

  @override
  void dispose() {
    _timer?.cancel();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(
                height: screenHeight * 0.45,
                child: _buildConnectSection(),
              ),
              const Text(
                '서버 선택',
                style: TextStyle(fontSize: 12, color: Color(0x66FFFFFF)),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildServerList()),
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'v2gravity',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        Row(
          children: [
            _iconBtn(Icons.electrical_services_rounded, () {}),
            const SizedBox(width: 16),
            _iconBtn(Icons.refresh_rounded, () {}),
            const SizedBox(width: 16),
            _iconBtn(Icons.settings_rounded, _goToSettings),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 24, color: Colors.white),
    );
  }

  Widget _buildConnectSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: connected ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                elapsedFormatted,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleConnect,
            child: AnimatedBuilder(
              animation: _morphAnim,
              builder: (context, child) {
                final size = Tween<double>(begin: 88, end: 96).evaluate(_morphAnim);
                final color = ColorTween(
                  begin: const Color(0x44FFFFFF),
                  end: kGreen.withOpacity(0.85),
                ).evaluate(_morphAnim)!;
                final borderColor = ColorTween(
                  begin: const Color(0x22FFFFFF),
                  end: kGreen.withOpacity(0.4),
                ).evaluate(_morphAnim)!;

                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 0.5),
                  ),
                  child: Icon(
                    _morphAnim.value < 0.5
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: connected
                      ? const Color(0xFF5DCAA5)
                      : const Color(0x44FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                connected ? '연결됨' : '연결 안 됨',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: const Color(0x88FFFFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerList() {
    return ListView.separated(
      itemCount: servers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = servers[i];
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => setState(() => selectedIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? kGreen.withOpacity(0.12) : kGlass,
              border: Border.all(
                color: isSelected ? kGreen.withOpacity(0.45) : kGlassBorder,
                width: isSelected ? 1 : 0.5,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(s['flag'], style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'],
                          style: GoogleFonts.notoSansKr(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 2),
                      Text(s['meta'],
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: const Color(0x55FFFFFF),
                          )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pingColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: pingColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    s['ping'],
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: isSelected ? pingColor : const Color(0x55FFFFFF),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? kGreen : const Color(0x33FFFFFF),
                      width: 1.5,
                    ),
                    color: isSelected ? kGreen.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: kGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _goToAddServer,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        decoration: BoxDecoration(
          color: kGlass,
          border: Border.all(color: kGlassBorder, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// ADD SERVER SCREEN
// ─────────────────────────────────────────

class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0; // 0 = 링크, 1 = QR
  final _linkController = TextEditingController();
  Map<String, String>? _parsed;
  bool _hasError = false;

  void _parseLink(String val) {
    setState(() {
      _hasError = false;
      _parsed = null;
    });
    if (val.isEmpty) return;
    try {
      final uri = Uri.parse(val);
      if (!['vless', 'vmess', 'trojan'].contains(uri.scheme)) {
        setState(() => _hasError = true);
        return;
      }
      // type: tcp, ws, grpc 등 (기본값: tcp)
      final transportRaw = uri.queryParameters['type'] ?? 'tcp';
      final transport = transportRaw.toLowerCase();
      
      // security: tls, reality, none 등 (기본값: none)
      final security = uri.queryParameters['security'] ?? 'none';
      
      // sni: TLS 서버명 (없으면 호스트명 사용)
      final sni = uri.queryParameters['sni'] ?? uri.host;
      
      // 이름 추출
      final name = uri.fragment.isNotEmpty
          ? Uri.decodeComponent(uri.fragment)
          : uri.host;
      
      // UUID/ID 추출
      final fullUuid = uri.userInfo;
      
      setState(() {
        _parsed = {
          'name': name,
          'host': uri.host,
          'port': uri.port.toString(),
          'uuid': fullUuid,
          'fullUuid': fullUuid,  // 실제 UUID
          'transport': transport,
          'security': security,
          'sni': sni,
          'protocol': uri.scheme,
          'displayMetaInfo': '${uri.scheme.toUpperCase()} · ${transport.toUpperCase()} · ${security.toUpperCase()}',
        };
      });
    } catch (e) {
      print('[AddServer] 파싱 오류: $e');
      setState(() => _hasError = true);
    }
  }

  void _save() {
    if (_parsed == null) return;
    Navigator.pop(context, {
      'flag': '🌐',
      'name': _parsed!['name'] ?? _parsed!['host']!,
      'meta': _parsed!['displayMetaInfo'] ?? 'VLESS',
      'ping': '—',
      'pingLevel': 1,
      // 실제 연결에 필요한 정보
      'host': _parsed!['host']!,
      'port': int.tryParse(_parsed!['port'] ?? '443') ?? 443,
      'uuid': _parsed!['fullUuid']!,
      'transportType': _parsed!['transport']!,
      'security': _parsed!['security']!,
      'sni': _parsed!['sni']!,
      'protocol': _parsed!['protocol']!,
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildTabs(),
              const SizedBox(height: 20),
              Expanded(
                child: _tabIndex == 0
                    ? _buildLinkPanel()
                    : _buildQrPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '서버 추가',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGlassBorder, width: 0.5),
      ),
      child: Row(
        children: [
          _tab('링크 붙여넣기', 0),
          _tab('QR 코드', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? const Color(0x33FFFFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: kGlassBorder, width: 0.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w300,
                color: isActive ? Colors.white : const Color(0x66FFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 입력창
        Container(
          decoration: BoxDecoration(
            color: kGlass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasError
                  ? const Color(0xFFF09595).withOpacity(0.5)
                  : kGlassBorder,
              width: 0.5,
            ),
          ),
          child: TextField(
            controller: _linkController,
            onChanged: _parseLink,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'vless:// 링크를 붙여넣으세요',
              hintStyle: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: const Color(0x44FFFFFF),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: _linkController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _linkController.clear();
                        _parseLink('');
                      },
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Color(0x44FFFFFF),
                        size: 18,
                      ),
                    )
                  : null,
            ),
          ),
        ),

        if (_hasError) ...[
          const SizedBox(height: 8),
          Text(
            '올바른 링크 형식이 아니에요 (vless://, vmess://, trojan://)',
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: const Color(0xFFF09595),
            ),
          ),
        ],

        // 파싱 결과
        if (_parsed != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kGlassBorder, width: 0.5),
            ),
            child: Column(
              children: [
                _parsedRow('이름', _parsed!['name']!),
                _parsedRow('서버', _parsed!['host']!),
                _parsedRow('포트', _parsed!['port']!),
                _parsedRow('UUID', _parsed!['uuid']!),
                _parsedRow('전송 / 보안', _parsed!['transport']!, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 저장 버튼
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: kGreen.withOpacity(0.4), width: 0.5),
              ),
              child: Center(
                child: Text(
                  '저장하고 연결',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],

        const Spacer(),
      ],
    );
  }

  Widget _parsedRow(String key, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              key,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: const Color(0x66FFFFFF),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 8),
          Container(height: 0.5, color: kGlassBorder),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildQrPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: kGlass,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGlassBorder, width: 0.5),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 72,
              color: Color(0x44FFFFFF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '서버 QR 코드를 스캔하면\n자동으로 추가돼요',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: const Color(0x88FFFFFF),
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              decoration: BoxDecoration(
                color: kGlass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGlassBorder, width: 0.5),
              ),
              child: Text(
                '카메라 열기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SETTINGS SCREEN
// ─────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool autoConnect = true;
  bool autoReconnect = true;
  bool dnsProxy = false;
  bool background = true;
  int routeMode = 0;
  String port = '10808';
  String language = '한국어';
  String theme = '시스템 따라가기';

  final Map<String, bool> appExclusions = {
    '카카오뱅크': true,
    '토스': true,
    '쿠팡': false,
    '카카오톡': false,
  };

  final Map<String, String> appPackages = {
    '카카오뱅크': 'com.kakaobank.channel',
    '토스': 'viva.republica.toss',
    '쿠팡': 'com.coupang.mobile',
    '카카오톡': 'com.kakao.talk',
  };

  final Map<String, IconData> appIcons = {
    '카카오뱅크': Icons.account_balance_rounded,
    '토스': Icons.credit_card_rounded,
    '쿠팡': Icons.shopping_bag_rounded,
    '카카오톡': Icons.chat_bubble_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _buildHeader(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),
                  _sectionLabel('연결'),
                  _glassCard([
                    _toggleRow('앱 시작 시 자동 연결', '앱 켜지면 마지막 서버에 바로 연결',
                        autoConnect, (v) => setState(() => autoConnect = v)),
                    _divider(),
                    _toggleRow('연결 끊기면 자동 재연결', '네트워크 변경 시 자동으로 재시도',
                        autoReconnect, (v) => setState(() => autoReconnect = v)),
                    _divider(),
                    _selectRow('로컬 포트', ['10808', '1080', '7890'], port,
                        (v) => setState(() => port = v!)),
                  ]),
                  const SizedBox(height: 20),
                  _sectionLabel('우회 설정'),
                  _glassCard([
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Expanded(child: _routeCard(0, '🌍', '전체 우회', '모든 트래픽을 서버로 전송')),
                        const SizedBox(width: 8),
                        Expanded(child: _routeCard(1, '🇨🇳', '중국 제외', '중국 사이트는 직접 연결')),
                      ]),
                    ),
                    _divider(),
                    _toggleRow('DNS 우회', 'DNS 쿼리도 프록시로 전송',
                        dnsProxy, (v) => setState(() => dnsProxy = v)),
                  ]),
                  const SizedBox(height: 20),
                  // ─── 앱별 제외 (Android 전용) ───
                  if (Platform.isAndroid) ...[
                    _sectionLabel('앱별 제외 (이 앱들은 VPN 안 거침)'),
                    _glassCard([
                      ...appExclusions.keys.map((app) => Column(children: [
                        _appRow(app),
                        if (app != appExclusions.keys.last) _divider(),
                      ])),
                      _divider(),
                      GestureDetector(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text('+ 앱 추가',
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 14, fontWeight: FontWeight.w300, color: kGreen)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                  _sectionLabel('앱'),
                  _glassCard([
                    _selectRow('언어', ['한국어', 'English', '中文'], language,
                        (v) => setState(() => language = v!)),
                    _divider(),
                    _selectRow('테마', ['시스템 따라가기', '라이트', '다크'], theme,
                        (v) => setState(() => theme = v!)),
                    _divider(),
                    _toggleRow('백그라운드 실행', '창 닫아도 트레이에서 계속 실행',
                        background, (v) => setState(() => background = v)),
                    _divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('코어 버전',
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white)),
                          Text('Xray 1.8.4',
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 13, fontWeight: FontWeight.w300, color: const Color(0x66FFFFFF))),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _sectionLabel('데이터'),
                  _glassCard([
                    GestureDetector(
                      onTap: _showResetDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('서버 목록 전체 초기화',
                                style: GoogleFonts.notoSansKr(
                                    fontSize: 14, fontWeight: FontWeight.w300,
                                    color: const Color(0xFFF09595))),
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0x44FFFFFF), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 12),
      const Text('설정',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
              color: Colors.white, letterSpacing: 0.5)),
    ]);
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(label,
          style: GoogleFonts.notoSansKr(
              fontSize: 12, fontWeight: FontWeight.w300, color: const Color(0x66FFFFFF))),
    );
  }

  Widget _glassCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGlassBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _divider() => Container(height: 0.5, color: kGlassBorder);

  Widget _toggleRow(String title, String desc, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.notoSansKr(
                    fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white)),
            const SizedBox(height: 3),
            Text(desc,
                style: GoogleFonts.notoSansKr(
                    fontSize: 12, fontWeight: FontWeight.w300, color: const Color(0x55FFFFFF))),
          ]),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: kGreen),
      ]),
    );
  }

  Widget _selectRow(String title, List<String> options, String value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.notoSansKr(
                  fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kGlassBorder, width: 0.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                onChanged: onChanged,
                dropdownColor: const Color(0xFF333331),
                style: GoogleFonts.notoSansKr(
                    fontSize: 13, fontWeight: FontWeight.w300, color: Colors.white),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0x66FFFFFF), size: 18),
                isDense: true,
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(int index, String emoji, String title, String desc) {
    final isSelected = routeMode == index;
    return GestureDetector(
      onTap: () => setState(() => routeMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? kGreen.withOpacity(0.15) : const Color(0x11FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kGreen.withOpacity(0.5) : const Color(0x22FFFFFF),
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(title,
              style: GoogleFonts.notoSansKr(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: isSelected ? const Color(0xFF5DCAA5) : Colors.white)),
          const SizedBox(height: 2),
          Text(desc,
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, fontWeight: FontWeight.w300,
                  color: isSelected
                      ? const Color(0xFF5DCAA5).withOpacity(0.7)
                      : const Color(0x55FFFFFF))),
        ]),
      ),
    );
  }

  Widget _appRow(String app) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(appIcons[app], size: 18, color: const Color(0x88FFFFFF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app,
                style: GoogleFonts.notoSansKr(
                    fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white)),
            Text(appPackages[app]!,
                style: GoogleFonts.notoSansKr(
                    fontSize: 11, fontWeight: FontWeight.w300, color: const Color(0x44FFFFFF))),
          ]),
        ),
        CupertinoSwitch(
          value: appExclusions[app]!,
          onChanged: (v) => setState(() => appExclusions[app] = v),
          activeTrackColor: kGreen,
        ),
      ]),
    );
  }

  void _showResetDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('서버 목록 초기화'),
        content: const Text('모든 서버가 삭제돼요. 계속할까요?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('초기화'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}