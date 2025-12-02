import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'video_player_screen.dart';

class VideoProductionScreen extends StatefulWidget {
  const VideoProductionScreen({super.key});

  @override
  State<VideoProductionScreen> createState() => _VideoProductionScreenState();
}

class _VideoProductionScreenState extends State<VideoProductionScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 3초 후 비디오 플레이어 화면으로 이동
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VideoPlayerScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Figma 프레임 크기: 360x800
  static const double figmaWidth = 360;
  static const double figmaHeight = 800;

  @override
  Widget build(BuildContext context) {
    // 상태바 스타일 설정 (Figma: #faf9fd 배경)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFAF9FD),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFBAA6F7),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

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
              child: Container(
                color: const Color(0xFFFAF9FD),
              ),
            ),
            // 뒤로가기 버튼
            // Figma: top:40, left:12, width:24, height:24
            Positioned(
              top: 40 * scale,
              left: 12 * scale,
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: 24 * scale, color: Colors.white),
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
                    child: Icon(Icons.person, size: 40 * scale, color: Colors.grey),
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
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF7B61FF)),
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

