import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'live_screen.dart';
import 'chat_screen.dart';

class ElliHomeScreen extends StatelessWidget {
  const ElliHomeScreen({super.key});

  // Figma 프레임 크기: 360x800
  static const double figmaWidth = 360;
  static const double figmaHeight = 800;

  @override
  Widget build(BuildContext context) {
    // 상태바 스타일 설정 (Figma: #faf9fd 배경)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFAF9FD),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFBBA7F7),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // 화면에 딱 맞게 스케일 계산 (Figma 360x800 기준)
    final scale = screenWidth / figmaWidth;

    return Scaffold(
      backgroundColor: Colors.white, // Figma: bg-white
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
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
            // 배경 그라데이션 (메인 콘텐츠 영역) - 피그마: h-[776px], 화면 하단까지 채움
            // Figma: top:24부터 시작, height:776px
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
                      Color(0xFFF3F1FB), // #f3f1fb
                      Color(0xFF7145F1), // #7145f1
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
            // 상단 바 (Frame 1686558293)
            // Figma: top:39, left:12
            Positioned(
              top: 39 * scale,
              left: 12 * scale,
              child: Row(
                children: [
                  // 뒤로가기 아이콘 (24x24) - 전 화면으로 돌아가기
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 24 * scale, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context); // 전 화면으로 돌아가기
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 8 * scale),
                  // ELLI 텍스트
                  Text(
                    'ELLI',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.2 * scale,
                      height: 16 / 18,
                    ),
                  ),
                ],
              ),
            ),
            // 프로필 이미지 (Mask group)
            // Figma: top:142, 중앙 정렬, width:120, height:120
            Positioned(
              top: 142 * scale,
              left: (screenWidth - 120 * scale) / 2,
              child: _buildProfileImage(scale),
            ),
            // 인사말 텍스트
            // Figma: top:299, 중앙 정렬
            Positioned(
              top: 299 * scale,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '엘지님. 좋은 아침이에요.',
                  style: TextStyle(
                    fontFamily: 'Noto Sans',
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.2 * scale,
                    height: 16 / 16,
                  ),
                ),
              ),
            ),
            // 설명 텍스트
            // Figma: top:345, 중앙 정렬
            Positioned(
              top: 345 * scale,
              left: 0,
              right: 0,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                  child: Text(
                    '생성형 AI를 활용한 가전 전문 어시스턴트 엘리예요.\n함께 문제를 바로 해결헤요!',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      letterSpacing: 0.2 * scale,
                      height: 19.068 / 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // 하단 버튼들 (Frame 1686558312)
            // Figma: bottom:76 (800 - 601 - 123 = 76), 중앙 정렬
            Positioned(
              bottom: 76 * scale,
              left: (screenWidth - 328 * scale) / 2,
              child: Material(
                color: Colors.transparent,
                child: _buildActionButtons(context, scale),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(double scale) {
    final size = 120 * scale;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD9D9D9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/캐릭터 프사.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD9D9D9),
              ),
              child: Icon(
                Icons.person,
                size: 60 * scale,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, double scale) {
    final buttonWidth = 328 * scale;
    final buttonHeight = 54 * scale;
    final borderRadius = 16 * scale;
    final fontSize = 16 * scale;
    
    return SizedBox(
      width: buttonWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 라이브 문제 해결 버튼
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LiveScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F42EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                elevation: 0,
              ),
              child: Text(
                '라이브 문제 해결',
                style: TextStyle(
                  fontFamily: 'Noto Sans',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.2 * scale,
                  height: 16 / 16,
                ),
              ),
            ),
          ),
          SizedBox(height: 15 * scale),
          // 채팅 문의 버튼
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: const Color(0xFF6F40EE), width: 1 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                elevation: 0,
              ),
              child: Text(
                '채팅 문의',
                style: TextStyle(
                  fontFamily: 'Noto Sans',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6F40EE),
                  letterSpacing: 0.2 * scale,
                  height: 16 / 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
