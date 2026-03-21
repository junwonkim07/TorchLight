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
          "tag": "socks",
          "port": 10808,
          "listen": "127.0.0.1",
          "protocol": "socks",
          "settings": {"udp": true}
        },
        {
          "tag": "http",
          "port": 10809,
          "listen": "127.0.0.1",
          "protocol": "http",
        }
      ],
      "outbounds": [
        {
          "tag": "proxy",
          "protocol": "vless",
          "settings": {
            "vnext": [
              {
                "address": address,
                "port": port,
                "users": [
                  {"id": uuid, "encryption": "none", "flow": ""}
                ]
              }
            ]
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
        {
          "tag": "direct",
          "protocol": "freedom",
          "settings": {}
        },
        {
          "tag": "block",
          "protocol": "blackhole",
          "settings": {}
        }
      ],
      "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
          {
            "type": "field",
            "outboundTag": "direct",
            "ip": ["geoip:private"]
          },
          if (bypassChina) ...[
            {
              "type": "field",
              "outboundTag": "direct",
              "domain": ["geosite:cn"]
            },
            {
              "type": "field",
              "outboundTag": "direct",
              "ip": ["geoip:cn"]
            }
          ]
        ]
      }
    };

    await configFile.writeAsString(jsonEncode(config));
    return configFile.path;
  }

  // ─── 시스템 프록시 설정 ───
  static Future<void> _setSystemProxy(bool enable) async {
    if (!Platform.isWindows) return;
    if (enable) {
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '1', '/f'
      ]);
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:10809', '/f'
      ]);
    } else {
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '0', '/f'
      ]);
    }
  }

  // ─── 핑 테스트 ───
  static Future<int?> ping(String host, int port) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(
        host, port,
        timeout: const Duration(seconds: 3),
      );
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

      final xrayPath = await _extractBinary();
      final configPath = await _writeConfig(
        address: address,
        port: port,
        uuid: uuid,
        transport: transport,
        security: security,
        sni: sni,
        bypassChina: bypassChina,
      );

      _process = await Process.start(xrayPath, ['run', '-c', configPath]);

      // 로그 출력 (디버그용)
      _process!.stdout.transform(utf8.decoder).listen((log) {
        print('[xray] $log');
      });
      _process!.stderr.transform(utf8.decoder).listen((log) {
        print('[xray error] $log');
      });

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