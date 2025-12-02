import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'live_screen.dart';
import 'video_production_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  // Figma 프레임 크기: 360x800
  static const double figmaWidth = 360;
  static const double figmaHeight = 800;

  @override
  Widget build(BuildContext context) {
    // 상태바 스타일 설정 (Figma: white 배경)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
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
            // 상단 상태바 영역 (Status Bar/Android)
            // Figma: height:24, 색상: white
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24 * scale,
              child: Container(
                color: Colors.white,
              ),
            ),
            // 메인 콘텐츠 영역 (전체 메인 콘텐츠 영역) - 피그마: h-[776px], 화면 하단까지 채움
            // Figma: top:24, left:0, width:360, height:776
            Positioned(
              top: 24 * scale,
              left: 0,
              right: 0,
              bottom: 0, // 화면 하단까지 채움
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    // 상단 헤더 바
                    // Figma: height:57, border-bottom: 1px #eaeaeb
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 57 * scale,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFFEAEAEB),
                              width: 1 * scale,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 뒤로가기 버튼
                              // Figma: arrow_back_24px, x=0, y=0 (Frame 내부 기준)
                              SizedBox(
                                width: 24 * scale,
                                height: 24 * scale,
                                child: IconButton(
                                  icon: Icon(Icons.arrow_back, size: 24 * scale, color: Colors.black),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ),
                              // "ELLI" 텍스트
                              // Figma: x=32, y=3 (Frame 내부 기준), 화살표 옆에 정확하게 일자로 배치
                              Padding(
                                padding: EdgeInsets.only(left: 8 * scale), // 32 - 24 = 8
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'ELLI',
                                    style: TextStyle(
                                      fontFamily: 'Noto Sans',
                                      fontSize: 18 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 0.2 * scale,
                                      height: 20 / 18,
                                    ),
                                  ),
                                ),
                              ),
                              Spacer(), // 오른쪽 아이콘을 밀어냄
                              // 상단 오른쪽 아이콘들 (채팅 상단 아이콘.png)
                              // Figma: Frame 1686558315, x=250, y=18, width=94.28571319580078, height=22.285715103149414
                              Stack(
                                children: [
                                  // 아이콘 이미지
                                  Image.asset(
                                    'assets/images/채팅 상단 아이콘.png',
                                    width: 94.28571319580078 * scale,
                                    height: 22.285715103149414 * scale,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 94.28571319580078 * scale,
                                        height: 22.285715103149414 * scale,
                                        color: Colors.grey.withValues(alpha: 0.3),
                                      );
                                    },
                                  ),
                                  // 가장 왼쪽 아이콘 클릭 영역 (이미지의 왼쪽 1/3)
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    width: (94.28571319580078 / 3) * scale, // 이미지 너비의 1/3
                                    height: 22.285715103149414 * scale,
                                    child: GestureDetector(
                                      onTap: () {
                                        // 가장 왼쪽 아이콘 클릭 시 LiveScreen으로 이동
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const LiveScreen()),
                                        );
                                      },
                                      child: Container(
                                        color: Colors.transparent, // 투명한 클릭 영역
                                      ),
                                    ),
                                  ),
                                  // 가운데 아이콘 클릭 영역 (이미지의 가운데 1/3)
                                  Positioned(
                                    left: (94.28571319580078 / 3) * scale, // 1/3 지점부터 시작
                                    top: 0,
                                    width: (94.28571319580078 / 3) * scale, // 이미지 너비의 1/3
                                    height: 22.285715103149414 * scale,
                                    child: GestureDetector(
                                      onTap: () {
                                        // 가운데 아이콘 클릭 시 VideoProductionScreen으로 이동
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 하단 입력 바
                    // Figma: top:673, left:0, width:360, height:71
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 71 * scale,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4 * scale,
                              offset: Offset(0, -4 * scale),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 입력 필드 배경
                            // Figma: left:10, top:686, width:340, height:46
                            Positioned(
                              bottom: 13 * scale,
                              left: 10 * scale,
                              right: 10 * scale,
                              height: 46 * scale,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F2FD),
                                  borderRadius: BorderRadius.circular(23 * scale),
                                ),
                                child: Row(
                                  children: [
                                    // 카메라 아이콘 (파란 동그라미)
                                    // Figma: Ellipse 4775, x=16.18161153793335, y=692, width=35.030303955078125, height=34
                                    // 입력 필드가 left:10이므로, 입력 필드 내부 기준으로는 left: 16.18 - 10 = 6.18
                                    Padding(
                                      padding: EdgeInsets.only(left: 6.18 * scale), // 16.18 - 10 = 6.18
                                      child: Container(
                                        width: 35.03 * scale,
                                        height: 34 * scale,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF7145F1),
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 22.667 * scale,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 9.31 * scale), // 60.49 - 16.18 - 35.03 = 9.28
                                    // 메시지 입력 텍스트
                                    // Figma: left:60.49, top:700, fontSize:11
                                    Expanded(
                                      child: Text(
                                        '메세지 입력...',
                                        style: TextStyle(
                                          fontFamily: 'Noto Sans',
                                          fontSize: 11 * scale,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF9A9A9A),
                                          letterSpacing: 0.011 * scale,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    // 전송 버튼
                                    // Figma: left:318.06, top:701, width:16.485, height:16
                                    Padding(
                                      padding: EdgeInsets.only(right: 15.94 * scale), // 360 - 318.06 - 16.485 = 25.455
                                      child: Icon(
                                        Icons.send,
                                        size: 16.485 * scale,
                                        color: const Color(0xFF7145F1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

