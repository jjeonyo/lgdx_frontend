import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'live_screen_with_buttons.dart';
import 'chat_screen.dart';
import 'customer_service_screen.dart';
import 'elli_home_screen.dart';
import '../services/live_camera_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final LiveCameraService _cameraService = LiveCameraService();
  bool _isStreaming = false;

  // Figma 프레임 크기: 360x800
  static const double figmaWidth = 360;
  static const double figmaHeight = 800;
  
  @override
  void initState() {
    super.initState();
    // 엘리홈으로 이동 콜백 설정
    _cameraService.setOnExitRequested(() {
      if (mounted) {
        _cameraService.stopStreaming();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ElliHomeScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 상태바 스타일 설정 (Figma: #faf9fd 배경)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFAF9FD),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF4F2FD),
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
            // 오른쪽 상단 아이콘 버튼들 (피그마 디자인에 맞게 수정)
            // Figma: left-[271px], top-[68px], gap-[15px]
            Positioned(
              top: 68 * scale,
              left: 271 * scale,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 채팅 아이콘 (message-text-02)
                  // Figma: size-[24px]
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/images/라이브상단아이콘.svg',
                      width: 24 * scale,
                      height: 24 * scale,
                    ),
                  ),
                  SizedBox(width: 15 * scale), // gap-[15px]
                  // 헤드셋 아이콘 (Group)
                  // Figma: size-[22.286px]
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerServiceScreen()),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/images/라이브상단아이콘2.svg',
                      width: 22.286 * scale,
                      height: 22.286 * scale,
                    ),
                  ),
                ],
              ),
            ),
            // 중앙 비디오 영역 (카메라 프리뷰)
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8 * scale),
                  child: _cameraService.cameraController != null &&
                          _cameraService.cameraController!.value.isInitialized
                      ? SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: CameraPreview(_cameraService.cameraController!),
                        )
                      : Center(
                          child: Icon(
                            Icons.videocam,
                            size: 60 * scale,
                            color: const Color(0xFFAFB1B6),
                          ),
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
            // Figma: top:509, left:calc(25%+23px), width:223, height:80
            // 캐릭터(19px) + 캐릭터 너비(95px) + 간격 = 약 114px부터 시작
            Positioned(
              top: 509 * scale,
              left: (19 + 95 + 10) * scale, // 캐릭터 오른쪽에 배치
              child: GestureDetector(
                onTap: () {
                  // 말풍선 클릭 시 버튼이 있는 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LiveScreenWithButtons()),
                  );
                },
                child: Container(
                  width: 223 * scale,
                  height: 80 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9).withValues(alpha: 0.49),
                    borderRadius: BorderRadius.circular(15 * scale),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32 * scale,
                    vertical: 22 * scale,
                  ),
                  child: Center(
                    child: Text(
                      '제가 도와드릴게요, 엘지님!\n오류 상황을 보여주시겠어요?',
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
            ),
            // 하단 컨트롤 버튼들 (3개)
            // Figma: Frame 1686558300, x=57, y=687, width=246, height=44
            // shadow: 0px_4px_4px_0px_rgba(0,0,0,0.25)
            // 첫 번째 버튼 (Rectangle 34627593): Frame 내부 x=0, y=0, width=66, height=44
            Positioned(
              top: 687 * scale,
              left: 57 * scale,
              child: GestureDetector(
                onTap: () async {
                  if (_isStreaming) {
                    // 스트리밍 중지
                    await _cameraService.stopStreaming();
                    setState(() {
                      _isStreaming = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('라이브 스트리밍이 중지되었습니다.')),
                      );
                    }
                  } else {
                    // 스트리밍 시작
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('라이브 스트리밍을 시작합니다...')),
                      );
                    }
                    final success = await _cameraService.startStreaming(context);
                    if (success) {
                      setState(() {
                        _isStreaming = true;
                      });
                      // 카메라 초기화 후 UI 업데이트를 위해 약간의 지연 후 다시 setState
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        setState(() {}); // 카메라 프리뷰 표시를 위해 UI 업데이트
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('라이브 스트리밍이 시작되었습니다.')),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('라이브 스트리밍 시작에 실패했습니다. 권한을 확인해주세요.')),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  width: 66 * scale,
                  height: 44 * scale,
                  decoration: BoxDecoration(
                    color: _isStreaming ? Colors.red : Colors.white,
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
                      _isStreaming ? Icons.stop : Icons.videocam,
                      size: 24 * scale,
                      color: _isStreaming ? Colors.white : Colors.black,
                    ),
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
            // X 버튼: 진단 화면 종료 및 엘리홈으로 이동
            Positioned(
              top: 687 * scale,
              left: 237 * scale, // 57 + 180 = 237
              child: GestureDetector(
                onTap: () {
                  // 1. WebSocket 서비스에 종료 신호 전송
                  _cameraService.closeDiagnosisAndExit();
                  
                  // 2. 잠시 대기 후 엘리홈으로 이동 (서버 응답을 기다리지 않고 즉시 이동)
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      // 스트리밍 중지
                      _cameraService.stopStreaming();
                      // 엘리홈으로 이동
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const ElliHomeScreen()),
                        (route) => false,
                      );
                    }
                  });
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
  
  @override
  void dispose() {
    _cameraService.stopStreaming();
    super.dispose();
  }
}
