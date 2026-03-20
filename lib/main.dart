import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

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
    {'flag': '🇯🇵', 'name': '일본 도쿄', 'meta': 'VLESS · WS · TLS', 'ping': '12ms', 'pingLevel': 0},
    {'flag': '🇸🇬', 'name': '싱가포르', 'meta': 'VLESS · gRPC · TLS', 'ping': '58ms', 'pingLevel': 1},
    {'flag': '🇺🇸', 'name': '미국 LA', 'meta': 'VLESS · TCP · TLS', 'ping': '182ms', 'pingLevel': 2},
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

  void _toggleConnect() {
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
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const AddServerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() => servers.add(result));
    }
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
            _iconBtn(Icons.settings_rounded, () {}),
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      final transport = uri.queryParameters['type']?.toUpperCase() ?? 'TCP';
      final security = uri.queryParameters['security'] ?? '없음';
      final name = uri.fragment.isNotEmpty
          ? Uri.decodeComponent(uri.fragment)
          : uri.host;
      setState(() {
        _parsed = {
          'name': name,
          'host': uri.host,
          'port': uri.port.toString(),
          'uuid': uri.userInfo.isNotEmpty
              ? '${uri.userInfo.substring(0, 8)}••••••••'
              : '—',
          'transport': '$transport · $security',
        };
      });
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  void _save() {
    if (_parsed == null) return;
    Navigator.pop(context, {
      'flag': '🌐',
      'name': _parsed!['name'] ?? _parsed!['host']!,
      'meta': 'VLESS · ${_parsed!['transport']}',
      'ping': '—',
      'pingLevel': 1,
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
    return Column(
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
    );
  }
}