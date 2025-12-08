import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'achievement_screen.dart';
import 'chat_screen.dart';

class VideoPlayerOverlayScreen extends StatefulWidget {
  const VideoPlayerOverlayScreen({super.key});

  @override
  State<VideoPlayerOverlayScreen> createState() => _VideoPlayerOverlayScreenState();
}

class _VideoPlayerOverlayScreenState extends State<VideoPlayerOverlayScreen> {
  bool _showPopup = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 5초 후 팝업 표시
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showPopup = true;
        });
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
      backgroundColor: Colors.white,
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
                icon: Icon(Icons.arrow_back, size: 24 * scale, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
            // 비디오 placeholder 영역
            // Figma: top:80, left:0, width:360, height:672
            Positioned(
              top: 80 * scale,
              left: 0,
              right: 0,
              height: 672 * scale,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFF0),
                  border: Border.all(
                    color: const Color(0xFFAFB1B6),
                    width: 2 * scale,
                  ),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Center(
                  child: Icon(
                    Icons.videocam,
                    size: 60 * scale,
                    color: const Color(0xFFAFB1B6),
                  ),
                ),
              ),
            ),
            // 검은 오버레이 레이어
            // Figma: bg-[rgba(0,0,0,0.4)], x=0, y=24, width=362, height=776
            Positioned(
              top: 24 * scale,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            // 다시 재생 버튼
            // Figma: x=158, y=375, width=46.217, height=51
            Positioned(
              top: 375 * scale,
              left: 158 * scale,
              child: GestureDetector(
                onTap: () {
                  // 다시 재생 버튼 클릭 시 비디오 플레이어 화면으로 돌아가기
                  Navigator.pop(context);
                },
                child: Container(
                  width: 46.217 * scale,
                  height: 51 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  child: Icon(
                    Icons.replay,
                    size: 30 * scale,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // 팝업 알림 (5초 후 표시)
            // Figma: Frame 1686558309, x=30, y=221, width=302, height=357.277
            if (_showPopup)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    // 배경 클릭 시 팝업 닫기
                    setState(() {
                      _showPopup = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Stack(
                      children: [
                        // 팝업 다이얼로그
                        Positioned(
                          top: 221 * scale,
                          left: 30 * scale,
                          child: GestureDetector(
                            onTap: () {
                              // 팝업 내부 클릭 시 이벤트 전파 방지
                            },
                            child: Container(
                              width: 302 * scale,
                              height: 357.277 * scale,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.223 * scale),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4 * scale,
                                    offset: Offset(0, 4 * scale),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // 닫기 버튼 (우측 상단)
                                  // Figma: Group 633022, x=271, y=14
                                  Positioned(
                                    top: 14 * scale,
                                    right: 14 * scale,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showPopup = false;
                                        });
                                      },
                                      child: Container(
                                        width: 15.395 * scale,
                                        height: 15.395 * scale,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF6F42EE),
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 12 * scale,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 캐릭터 이미지 (GIF)
                                  // Figma: x=107, y=31, width=88, height=132
                                  Positioned(
                                    top: 31 * scale,
                                    left: 107 * scale,
                                    child: Image.asset(
                                      'assets/images/02.dance.gif',
                                      width: 88 * scale,
                                      height: 132 * scale,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 88 * scale,
                                          height: 132 * scale,
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        );
                                      },
                                    ),
                                  ),
                                  // "문제가 해결되셨나요?" 텍스트
                                  // 중앙 정렬, 글자 크기 증가, 잘리지 않도록 수정
                                  Positioned(
                                    top: 165 * scale,
                                    left: 10 * scale,
                                    right: 10 * scale,
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Noto Sans',
                                          fontSize: 18 * scale, // 16 -> 18
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          letterSpacing: -0.8 * scale,
                                        ),
                                        children: [
                                          TextSpan(text: '문제가 '),
                                          TextSpan(
                                            text: '해결',
                                            style: TextStyle(
                                              color: const Color(0xFF6F42EE),
                                            ),
                                          ),
                                          TextSpan(text: '되셨나요?'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // "추가로 문의하고 싶은게 있으시면 제게 채팅해주세요!" 텍스트
                                  // 중앙 정렬, 글자 크기 증가, 잘리지 않도록 수정
                                  Positioned(
                                    top: 200 * scale,
                                    left: 15 * scale,
                                    right: 15 * scale,
                                    child: Text(
                                      '추가로 문의하고 싶은게 있으시면\n제게 채팅해주세요!',
                                      style: TextStyle(
                                        fontFamily: 'Noto Sans',
                                        fontSize: 14 * scale, // 12 -> 14
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF6B6B6B), // achievement_screen과 동일한 진한 회색
                                        letterSpacing: -0.24 * scale,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                  // 버튼들
                                  // Figma: x=34, y=277, width=229, height=40
                                  Positioned(
                                    top: 277 * scale,
                                    left: 34 * scale,
                                    child: Row(
                                      children: [
                                        // "채팅 문의" 버튼
                                        // Figma: x=0, y=0, width=104, height=40
                                        GestureDetector(
                                          onTap: () {
                                            // 채팅 문의 버튼 클릭 시 ChatScreen으로 이동
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const ChatScreen()),
                                            );
                                          },
                                          child: Container(
                                            width: 104 * scale,
                                            height: 40 * scale,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6F42EE),
                                              borderRadius: BorderRadius.circular(40 * scale),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.13),
                                                  blurRadius: 22 * scale,
                                                  offset: Offset(3 * scale, 3 * scale),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '채팅 문의',
                                                style: TextStyle(
                                                  fontFamily: 'Noto Sans',
                                                  fontSize: 16 * scale,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white,
                                                  letterSpacing: -0.8 * scale,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 24 * scale), // 128 - 104 = 24
                                        // "종료하기" 버튼
                                        // Figma: x=128, y=0, width=101, height=40
                                        GestureDetector(
                                          onTap: () {
                                            // 맞춤 칭호 화면으로 이동
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const AchievementScreen()),
                                            );
                                          },
                                          child: Container(
                                            width: 101 * scale,
                                            height: 40 * scale,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2F0FF),
                                              borderRadius: BorderRadius.circular(40 * scale),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.13),
                                                  blurRadius: 22 * scale,
                                                  offset: Offset(3 * scale, 3 * scale),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '종료하기',
                                                style: TextStyle(
                                                  fontFamily: 'Noto Sans',
                                                  fontSize: 16 * scale,
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(0xFF6F42EE),
                                                  letterSpacing: -0.8 * scale,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

