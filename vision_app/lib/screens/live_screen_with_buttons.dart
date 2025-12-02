import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'video_production_screen.dart';
import 'chat_screen.dart';

class LiveScreenWithButtons extends StatelessWidget {
  const LiveScreenWithButtons({super.key});

  // Figma 프레임 크기: 360x800
  static const double figmaWidth = 360;
  static const double figmaHeight = 800;

  @override
  Widget build(BuildContext context) {
    // 상태바 스타일 설정 (Figma: #faf9fe 배경)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFAF9FE),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFBBA6F7),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // 화면에 딱 맞게 스케일 계산 (Figma 360x800 기준)
    final scale = screenWidth / figmaWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FB), // Rectangle 287 배경색
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
            // Figma: height:24, 색상: #faf9fe
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24 * scale,
              child: Container(
                color: const Color(0xFFFAF9FE),
              ),
            ),
            // "실시간 진단" 텍스트와 빨간 점
            // Figma: top:70, left:23
            Positioned(
              top: 70 * scale,
              left: 23 * scale,
              child: Row(
                children: [
                  // 빨간 점 (Ellipse 4765)
                  Container(
                    width: 9 * scale,
                    height: 9 * scale,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF0004),
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  // "실시간 진단" 텍스트
                  Text(
                    '실시간 진단',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      letterSpacing: 0.016 * scale,
                      height: 21.792 / 16,
                    ),
                  ),
                ],
              ),
            ),
            // 오른쪽 상단 아이콘 버튼들 (3개 아이콘이 하나의 이미지에 포함)
            // Figma: Frame 1686558316 위치
            // 전체 프레임 기준: left: 12 + (-1) + 235 = 246, top: 68 + 0 + 1 = 69
            // 크기: width: 97.28571319580078, height: 24
            Positioned(
              top: 69 * scale,
              left: 246 * scale,
              child: Stack(
                children: [
                  // 아이콘 이미지
                  Image.asset(
                    'assets/images/라이브 아이콘.png',
                    width: 97.28571319580078 * scale,
                    height: 24 * scale,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 97.28571319580078 * scale,
                        height: 24 * scale,
                        color: Colors.grey.withValues(alpha: 0.3),
                      );
                    },
                  ),
                  // 가장 왼쪽 채팅 아이콘 클릭 영역 (이미지의 왼쪽 1/3)
                  Positioned(
                    left: 0,
                    top: 0,
                    width: (97.28571319580078 / 3) * scale, // 이미지 너비의 1/3
                    height: 24 * scale,
                    child: GestureDetector(
                      onTap: () {
                        // 채팅 아이콘 클릭 시 ChatScreen으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatScreen()),
                        );
                      },
                      child: Container(
                        color: Colors.transparent, // 투명한 클릭 영역
                      ),
                    ),
                  ),
                  // 2번째 동영상 아이콘 클릭 영역 (이미지의 가운데 1/3)
                  Positioned(
                    left: (97.28571319580078 / 3) * scale, // 1/3 지점부터 시작
                    top: 0,
                    width: (97.28571319580078 / 3) * scale, // 이미지 너비의 1/3
                    height: 24 * scale,
                    child: GestureDetector(
                      onTap: () {
                        // 동영상 아이콘 클릭 시 VideoProductionScreen으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VideoProductionScreen()),
                        );
                      },
                      child: Container(
                        color: Colors.transparent, // 투명한 클릭 영역
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 중앙 비디오 영역 (Placeholder)
            // Figma: top:112, left:0, width:360, height:554
            Positioned(
              top: 112 * scale,
              left: 0,
              right: 0,
              height: 554 * scale,
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
            // 왼쪽 하단 캐릭터 이미지
            // Figma: top:509, left:19, width:95, height:143
            Positioned(
              top: 509 * scale,
              left: 19 * scale,
              child: Image.asset(
                'assets/images/캐릭터 정지.png',
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
            // 말풍선
            // Figma: Frame 1686558305, x=113, y=509, width=223, height=80
            // padding: px-[16px] py-[22px]
            Positioned(
              top: 509 * scale,
              left: 113 * scale,
              child: Container(
                width: 223 * scale,
                height: 80 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9).withValues(alpha: 0.49),
                  borderRadius: BorderRadius.circular(15 * scale),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 22 * scale,
                ),
                child: Center(
                  child: Text(
                    '해결 과정이 담긴 AI 제작 영상을 보시겠어요?',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      letterSpacing: 0.2 * scale,
                      height: 17.706 / 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // 예/아니오 버튼들
            // Figma: Frame 1686558302, x=129, y=597, width=191, height=37
            // shadow: 0px_4px_4px_0px_rgba(0,0,0,0.25)
            Positioned(
              top: 597 * scale,
              left: 129 * scale,
              child: Container(
                width: 191 * scale,
                height: 37 * scale,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4 * scale,
                      offset: Offset(0, 4 * scale),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // "예" 버튼
                    // Figma: Frame 1686558294, x=0, y=0, width=90, height=37
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VideoProductionScreen()),
                        );
                      },
                      child: Container(
                        width: 90 * scale,
                        height: 37 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F42EE),
                          borderRadius: BorderRadius.circular(6 * scale),
                        ),
                        child: Center(
                          child: Text(
                            '예',
                            style: TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.2 * scale,
                              height: 23 / 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 11 * scale), // 101 - 90 = 11
                    // "아니오" 버튼
                    // Figma: Frame 1686558295, x=101, y=0, width=90, height=37
                    Container(
                      width: 90 * scale,
                      height: 37 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6 * scale),
                      ),
                      child: Center(
                        child: Text(
                          '아니오',
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6F42EE),
                            letterSpacing: 0.2 * scale,
                            height: 23 / 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 하단 컨트롤 버튼들 (3개)
            // Figma: Frame 1686558300, x=57, y=687, width=246, height=44
            // shadow: 0px_4px_4px_0px_rgba(0,0,0,0.25)
            // 첫 번째 버튼 (Rectangle 34627593): Frame 내부 x=0, y=0, width=66, height=44
            Positioned(
              top: 687 * scale,
              left: 57 * scale,
              child: Container(
                width: 66 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19.5 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4 * scale,
                      offset: Offset(0, 4 * scale),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.videocam,
                    size: 24 * scale,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // 두 번째 버튼 (Rectangle 290): Frame 내부 x=90, y=0, width=66, height=44
            // 재생 버튼 이미지 사용
            Positioned(
              top: 687 * scale,
              left: 147 * scale, // 57 + 90 = 147
              child: Container(
                width: 66 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19.5 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4 * scale,
                      offset: Offset(0, 4 * scale),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19.5 * scale),
                  child: Image.asset(
                    'assets/images/라이브 재생 버튼.png',
                    width: 66 * scale,
                    height: 44 * scale,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 66 * scale,
                        height: 44 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF29344E).withValues(alpha: 0.54),
                          borderRadius: BorderRadius.circular(19.5 * scale),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // 세 번째 버튼 (Rectangle 291): Frame 내부 x=180, y=0, width=66, height=44
            Positioned(
              top: 687 * scale,
              left: 237 * scale, // 57 + 180 = 237
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 66 * scale,
                  height: 44 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF41919),
                    borderRadius: BorderRadius.circular(19.5 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4 * scale,
                        offset: Offset(0, 4 * scale),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: 24 * scale,
                      color: Colors.white,
                    ),
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

