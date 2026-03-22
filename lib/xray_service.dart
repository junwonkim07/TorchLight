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

    // streamSettings 동적 생성
    final streamSettings = <String, dynamic>{
      "network": transport.toLowerCase(),
      "security": security.toLowerCase() == "없음" ? "none" : security.toLowerCase(),
    };

    // TLS 설정
    if (security.toLowerCase() != "없음" && security.toLowerCase() != "none") {
      streamSettings["tlsSettings"] = {
        "serverName": sni,
        "allowInsecure": false,
        "disableSystemRoot": false,
      };
    }

    // WebSocket 설정
    if (transport.toLowerCase() == "ws") {
      streamSettings["wsSettings"] = {
        "path": "/",
        "headers": {}
      };
    }

    // gRPC 설정
    if (transport.toLowerCase() == "grpc") {
      streamSettings["grpcSettings"] = {
        "serviceName": "",
        "multiMode": false
      };
    }

    // 라우팅 규칙 동적 생성
    final routingRules = <Map<String, dynamic>>[
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": ["geoip:private"]
      }
    ];

    if (bypassChina) {
      routingRules.addAll([
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
      ]);
    }

    final config = {
      "log": {
        "loglevel": "warning",
        "access": ""
      },
      "inbounds": [
        {
          "tag": "socks",
          "port": 10808,
          "listen": "127.0.0.1",
          "protocol": "socks",
          "settings": {
            "udp": true,
            "auth": "noauth"
          },
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls"]
          }
        },
        {
          "tag": "http",
          "port": 10809,
          "listen": "127.0.0.1",
          "protocol": "http",
          "settings": {},
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls"]
          }
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
                  {
                    "id": uuid,
                    "encryption": "none",
                    "flow": ""
                  }
                ]
              }
            ]
          },
          "streamSettings": streamSettings,
          "mux": {
            "enabled": false
          }
        },
        {
          "tag": "direct",
          "protocol": "freedom",
          "settings": {
            "domainStrategy": "UseIPv4"
          }
        },
        {
          "tag": "block",
          "protocol": "blackhole",
          "settings": {
            "response": {
              "type": "http"
            }
          }
        }
      ],
      "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": routingRules
      }
    };

    await configFile.writeAsString(jsonEncode(config));
    print('[XrayService] config.json created: ${configFile.path}');
    return configFile.path;
  }

  // ─── 시스템 프록시 설정 ───
  static Future<void> _setSystemProxy(bool enable) async {
    if (!Platform.isWindows) return;
    
    try {
      if (enable) {
        print('[XrayService] 프록시 활성화: 127.0.0.1:10809');
        
        // ProxyEnable 활성화
        final result1 = await Process.run('reg', [
          'add',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
          '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '1', '/f'
        ]);
        
        if (result1.exitCode != 0) {
          print('[XrayService] 경고: ProxyEnable 레지스트리 설정 실패');
          print('[XrayService] 오류: ${result1.stderr}');
        }
        
        // ProxyServer 설정
        final result2 = await Process.run('reg', [
          'add',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
          '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:10809', '/f'
        ]);
        
        if (result2.exitCode != 0) {
          print('[XrayService] 경고: ProxyServer 레지스트리 설정 실패');
          print('[XrayService] 오류: ${result2.stderr}');
        }

        // IE 프록시 캐시 새로고침
        await Process.run('ipconfig', ['/flushdns']);
      } else {
        print('[XrayService] 프록시 비활성화');
        
        final result = await Process.run('reg', [
          'add',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
          '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '0', '/f'
        ]);
        
        if (result.exitCode != 0) {
          print('[XrayService] 경고: 프록시 비활성화 실패');
          print('[XrayService] 오류: ${result.stderr}');
        }

        // 캐시 새로고침
        await Process.run('ipconfig', ['/flushdns']);
      }
    } catch (e) {
      print('[XrayService] 시스템 프록시 설정 오류: $e');
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

      print('[XrayService] 초기화 시작...');
      
      final xrayPath = await _extractBinary();
      print('[XrayService] xray.exe 경로: $xrayPath');
      
      if (!File(xrayPath).existsSync()) {
        print('[XrayService] 오류: xray.exe 파일을 찾을 수 없음');
        return false;
      }

      final configPath = await _writeConfig(
        address: address,
        port: port,
        uuid: uuid,
        transport: transport,
        security: security,
        sni: sni,
        bypassChina: bypassChina,
      );

      if (!File(configPath).existsSync()) {
        print('[XrayService] 오류: config.json 파일이 생성되지 않음');
        return false;
      }

      print('[XrayService] xray.exe 시작 중... (config: $configPath)');
      print('[XrayService] 명령어: "$xrayPath" run -c "$configPath"');
      
      _process = await Process.start(xrayPath, ['run', '-c', configPath]);

      if (_process == null) {
        print('[XrayService] 오류: 프로세스 생성 실패');
        return false;
      }

      print('[XrayService] 프로세스 시작됨 (PID: ${_process!.pid})');

      // ✅ 로그 수집 (Process.start() 직후에 등록해야 함)
      final stdoutLines = <String>[];
      final stderrLines = <String>[];
      
      _process!.stdout.transform(utf8.decoder).listen((log) {
        stdoutLines.add(log);
        if (log.isNotEmpty) print('[xray stdout] $log');
      });

      _process!.stderr.transform(utf8.decoder).listen((log) {
        stderrLines.add(log);
        if (log.isNotEmpty) print('[xray stderr] $log');
      });

      // 프로세스 종료 모니터링 (백그라운드 비동기 처리)
      _process!.exitCode.then((code) {
        print('[XrayService] 프로세스 종료 (exit code: $code)');
        if (code != 0) {
          print('[XrayService] xray 실행 오류 발생');
          print('[XrayService] stdout: $stdoutLines');
          print('[XrayService] stderr: $stderrLines');
        }
        _process = null;
      });

      // 프로세스가 200ms 내에 죽는지 확인
      await Future.delayed(const Duration(milliseconds: 200));
      
      // exitCode가 완료되었는지 확인 (프로세스가 아직 살아있는지)
      if (_process!.exitCode.isCompleted) {
        final code = await _process!.exitCode;
        print('[XrayService] 오류: xray 프로세스가 즉시 종료됨 (exit code: $code)');
        print('[XrayService] stderr: ${stderrLines.join('\n')}');
        _process = null;
        return false;
      }

      if (useSystemProxy) {
        // xray 시작 대기
        await Future.delayed(const Duration(milliseconds: 1000));
        print('[XrayService] 시스템 프록시 설정 중...');
        await _setSystemProxy(true);
        print('[XrayService] 시스템 프록시 설정 완료');
      }

      print('[XrayService] ✅ 연결 성공!');
      return true;
    } catch (e) {
      print('[XrayService] ❌ 시작 오류: $e');
      print('[XrayService] 스택: ${StackTrace.current}');
      _process = null;
      return false;
    }
  }

  // ─── 종료 ───
  static Future<void> stop() async {
    await _setSystemProxy(false);
    _process?.kill();
    _process = null;
  }

  // ─── 진단 (테스트용) ───
  /// xray 바이너리가 제대로 설정되었는지 확인
  static Future<Map<String, dynamic>> diagnose() async {
    final result = <String, dynamic>{};
    
    try {
      // 1. 바이너리 경로 확인
      final xrayPath = await _extractBinary();
      result['xrayPath'] = xrayPath;
      result['xrayExists'] = File(xrayPath).existsSync();
      
      print('[Diagnose] xray.exe 경로: $xrayPath');
      print('[Diagnose] xray.exe 존재: ${result['xrayExists']}');
      
      if (!result['xrayExists']) {
        result['error'] = 'xray.exe 파일이 없습니다';
        return result;
      }

      // 2. xray 버전 확인 (xray -version)
      print('[Diagnose] xray 버전 확인 중...');
      final versionResult = await Process.run(xrayPath, ['-version'], runInShell: false);
      result['xrayVersion'] = versionResult.stdout.toString().trimLeft().split('\n')[0];
      print('[Diagnose] xray 버전: ${result['xrayVersion']}');

      // 3. 설정 파일 생성 테스트
      print('[Diagnose] 임시 config.json 생성 중...');
      final tempConfig = await _writeConfig(
        address: 'example.com',
        port: 443,
        uuid: 'test-uuid-1234-5678-90ab-cdefghijklmn',
        transport: 'tcp',
        security: 'tls',
        sni: 'example.com',
        bypassChina: false,
      );
      result['configPath'] = tempConfig;
      result['configExists'] = File(tempConfig).existsSync();
      print('[Diagnose] config.json: $tempConfig (존재: ${result['configExists']})');

      // 4. config.json 포맷 검증
      if (File(tempConfig).existsSync()) {
        final configContent = File(tempConfig).readAsStringSync();
        try {
          final decoded = jsonDecode(configContent);
          result['configValid'] = true;
          result['configSize'] = configContent.length;
          print('[Diagnose] config.json 포맷: 유효 (${configContent.length} bytes)');
        } catch (e) {
          result['configValid'] = false;
          result['configError'] = e.toString();
          print('[Diagnose] config.json 포맷: ❌ 오류 - $e');
        }
      }

      // 5. xray 드라이런 테스트 (-test)
      print('[Diagnose] xray test 모드 실행 중...');
      final testResult = await Process.run(
        xrayPath,
        ['-test', '-c', tempConfig],
        timeout: const Duration(seconds: 5),
      );
      result['testExitCode'] = testResult.exitCode;
      result['testStdout'] = testResult.stdout.toString();
      result['testStderr'] = testResult.stderr.toString();
      
      print('[Diagnose] xray test 결과: exit code ${testResult.exitCode}');
      if (testResult.exitCode == 0) {
        result['configTestValid'] = true;
        print('[Diagnose] ✅ config.json이 xray에서 유효합니다');
      } else {
        result['configTestValid'] = false;
        print('[Diagnose] ❌ config.json이 xray에서 거부되었습니다');
        print('[Diagnose] stderr: ${testResult.stderr}');
      }

      result['status'] = 'ok';
    } catch (e) {
      result['error'] = e.toString();
      print('[Diagnose] ❌ 진단 오류: $e');
    }

    return result;
  }
}