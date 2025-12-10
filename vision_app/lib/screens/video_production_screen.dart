import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'video_player_screen.dart';

class VideoProductionScreen extends StatefulWidget {
  const VideoProductionScreen({super.key});

  @override
  State<VideoProductionScreen> createState() => _VideoProductionScreenState();
}

class _VideoProductionScreenState extends State<VideoProductionScreen> {
  Timer? _pollingTimer;
  // 백엔드 상태 확인 URL
  String get _checkStatusUrl => '${ApiConfig.baseUrl}/check-video-status';

  // 로딩 화면 최소 유지 시간을 위한 변수
  late DateTime _startTime;
  static const Duration _minLoadingTime = Duration(seconds: 4);
  static const int _minFileSizeBytes = 50 * 1024; // 최소 50KB 이상일 때만 재생 시도
  String? _lastAcceptedVideoName; // 이미 재생한(또는 허용한) 영상 파일명

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now(); // 시작 시간 기록
    _startPolling();
  }

  void _startPolling() {
    // 3초마다 상태 확인
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkVideoStatus();
    });
  }

  Future<void> _navigateWithDelay(Widget nextScreen) async {
    _pollingTimer?.cancel();

    // 최소 로딩 시간 보장
    final elapsedTime = DateTime.now().difference(_startTime);
    if (elapsedTime < _minLoadingTime) {
      await Future.delayed(_minLoadingTime - elapsedTime);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  String? _extractFileName(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
      // 단순 문자열 분리 fallback
      final parts = rawUrl.split('/');
      return parts.isNotEmpty ? parts.last : null;
    } catch (_) {
      final parts = rawUrl.split('/');
      return parts.isNotEmpty ? parts.last : null;
    }
  }

  bool _isFreshVideo(String fileName) {
    // 파일명 패턴: result_solution_YYYYMMDD_HHMMSS.mp4
    final match = RegExp(
      r'result_solution_(\d{8})_(\d{6})\.mp4',
    ).firstMatch(fileName);
    if (match == null) return true; // 패턴 모르면 일단 허용

    final dateStr = match.group(1)!; // YYYYMMDD
    final timeStr = match.group(2)!; // HHMMSS
    try {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      final hour = int.parse(timeStr.substring(0, 2));
      final minute = int.parse(timeStr.substring(2, 4));
      final second = int.parse(timeStr.substring(4, 6));
      final createdAt = DateTime(year, month, day, hour, minute, second);

      // 영상 생성 시작 시점 이후에 생성된 것만 허용
      return !createdAt.isBefore(_startTime);
    } catch (_) {
      return true;
    }
  }

  Future<bool> _isReachable(String url) async {
    try {
      final head = await http.head(Uri.parse(url));
      final ok = head.statusCode == 200;
      final lenStr = head.headers['content-length'];
      if (lenStr != null) {
        final len = int.tryParse(lenStr);
        if (len != null && len < _minFileSizeBytes) {
          print("⚠️ [Polling] Content too small ($len bytes) for $url");
          return false;
        }
      }
      if (!ok) {
        print("⚠️ [Polling] HEAD check failed (${head.statusCode}) for $url");
      }
      return ok;
    } catch (e) {
      print("⚠️ [Polling] HEAD check error for $url: $e");
      return false;
    }
  }

  Future<void> _checkVideoStatus() async {
    try {
      final response = await http.get(Uri.parse(_checkStatusUrl));
      print("📡 [Polling] Status Check: ${response.statusCode}"); // 상태 코드 로그 추가

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📡 [Polling] Response Body: $data"); // 응답 데이터 로그 추가
        final status = data['status']; // 'processing', 'completed', 'failed'
        final rawUrl = data['video_url'];
        final createdAtStr = data['video_created_at'];

        if (status == 'completed' &&
            rawUrl != null &&
            rawUrl.toString().isNotEmpty) {
          print("✅ [Polling] Video generation completed!");
          String videoUrl = rawUrl; // 생성된 비디오 URL
          print("✅ [Polling] Raw Video URL: $videoUrl");

          final fileName = _extractFileName(videoUrl);
          if (fileName == null) {
            print("⚠️ [Polling] 파일명을 파싱하지 못했습니다. 계속 대기.");
            return;
          }

          // 같은 파일이면 재생하지 않고 대기
          if (_lastAcceptedVideoName == fileName) {
            print("⏳ [Polling] 동일 파일 감지 (${fileName}), 새 파일을 대기합니다.");
            return;
          }

          // 생성 시작 이후 파일인지 확인 (예전 파일이면 스킵)
          if (!_isFreshVideo(fileName)) {
            print("⏳ [Polling] 이전 생성 파일(${fileName})로 판단되어 대기합니다.");
            return;
          }

          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null && createdAt.isBefore(_startTime)) {
              print("⏳ [Polling] 생성 시각이 현재 세션 이전입니다. 대기합니다. ($createdAtStr)");
              return;
            }
          }

          // 상대 경로인 경우 base URL 추가
          if (!videoUrl.startsWith('http')) {
            // URL이 /로 시작하지 않으면 추가
            if (!videoUrl.startsWith('/')) {
              videoUrl = '/$videoUrl';
            }
            videoUrl = '${ApiConfig.baseUrl}$videoUrl';
          }
          print("✅ [Polling] Final Video URL: $videoUrl");

          // 실제로 접근 가능한지 HEAD로 확인
          final reachable = await _isReachable(videoUrl);
          if (!reachable) {
            print("⏳ [Polling] 파일이 아직 서빙되지 않았습니다. 재시도.");
            return;
          }

          _lastAcceptedVideoName = fileName;
          await _navigateWithDelay(VideoPlayerScreen(videoUrl: videoUrl));
        } else {
          // 실패나 진행 중인 경우에도 계속 대기
          print("⏳ [Polling] Waiting for video file... (status: $status)");
        }
      } else {
        // 상태 코드가 200이 아닌 경우
        print("Status check failed: ${response.statusCode}");

        // 서버에서 명시적인 에러 메시지가 오는 경우 실패 처리
        // 예: Quota Exceeded, Rate Limit, 429 등
        if (response.statusCode == 429 ||
            response.body.contains('RESOURCE_EXHAUSTED') ||
            response.body.contains('quota')) {
          print(
            "Critical error detected: ${response.body} (will keep polling)",
          );
        } else {
          // 500 Internal Server Error 등 기타 서버 오류 발생 시에도 실패 처리하지 않고 로그만 출력
          // (긴 작업 중 일시적 타임아웃 등은 무시하고 계속 폴링)
          print("Server status code: ${response.statusCode}");

          // 하지만 명시적인 Quota 에러는 실패 처리
          if (response.statusCode == 429 ||
              response.body.contains('RESOURCE_EXHAUSTED') ||
              response.body.contains('quota')) {
            print(
              "Critical error detected: ${response.body} (will keep polling)",
            );
          }
        }
      }
    } catch (e) {
      // 네트워크 오류 등 - 로그만 출력하고 계속 재시도
      print("Error checking status: $e");
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Figma 프레임 크기: 360x800
  static const double figmaWidth = 360;

  @override
  Widget build(BuildContext context) {
    // 상태바 스타일 설정 (Figma: #faf9fd 배경)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF9FD),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFBAA6F7),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // 화면에 딱 맞게 스케일 계산 (Figma 360x800 기준)
    final scale = screenWidth / figmaWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FB),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            // Rectangle 287 배경 그라데이션 (전체 메인 콘텐츠 영역) - 피그마: h-[776px], 화면 하단까지 채움
            // Figma: Rectangle 287, x=0, y=24, width=360, height=776
            // 그라데이션: F3F1FB 42%, 7145F1 100%
            Positioned(
              top: 24 * scale,
              left: 0,
              right: 0,
              bottom: 0, // 화면 하단까지 채움
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF3F1FB), // F3F1FB
                      Color(0xFF7145F1), // 7145F1
                    ],
                    stops: [0.42, 1.0], // F3F1FB 42%, 7145F1 100%
                  ),
                ),
              ),
            ),
            // 상단 상태바 영역 (Status Bar/Android)
            // Figma: height:24, 색상: #faf9fd
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24 * scale,
              child: Container(color: const Color(0xFFFAF9FD)),
            ),
            // 뒤로가기 버튼
            // Figma: top:40, left:12, width:24, height:24
            Positioned(
              top: 40 * scale,
              left: 12 * scale,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: 24 * scale,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
            // 캐릭터 이미지 (GIF)
            // Figma: x=138, y=178, width=95, height=143 (조금 아래로 이동)
            Positioned(
              top: 208 * scale, // 178 + 30
              left: 138 * scale,
              child: Image.asset(
                'assets/images/02.dance with smile.gif',
                width: 95 * scale,
                height: 143 * scale,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 95 * scale,
                    height: 143 * scale,
                    color: Colors.grey.withValues(alpha: 0.3),
                    child: Icon(
                      Icons.person,
                      size: 40 * scale,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            // 텍스트
            // Figma: x=65, y=352, width=241, height=83
            Positioned(
              top: 352 * scale,
              left: 65 * scale,
              child: SizedBox(
                width: 241 * scale,
                height: 83 * scale,
                child: Text(
                  '엘지님의 상황에 딱 맞는\n맞춤 해결 영상을 제작하고 있어요!',
                  style: TextStyle(
                    fontFamily: 'Noto Sans',
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.2 * scale,
                    height: 83 / (16 * 2), // 2줄 기준
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 로딩 스피너
            // Figma: x=158, y=435, width=48, height=48 (조금 더 아래로 이동)
            Positioned(
              top: 470 * scale, // 435 + 35
              left: 158 * scale,
              child: SizedBox(
                width: 48 * scale,
                height: 48 * scale,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF7B61FF),
                  ),
                  strokeWidth: 4 * scale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
