import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'live_screen.dart';
import 'live_screen_with_buttons.dart';
import 'video_production_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Figma 프레임 크기: 360x800
  static const double figmaWidth = 360;
  static const double figmaHeight = 800;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = []; // 'sender', 'text'
  bool _isLoading = false;

  // 백엔드 API URL (Android Emulator: 10.0.2.2, iOS Simulator: 127.0.0.1, Real Device: IP Address)
  // 사용자의 환경에 맞게 수정 필요
  final String _apiUrl = 'http://127.0.0.1:8000/chat';

  @override
  void initState() {
    super.initState();
    // 초기 환영 메시지
    _addMessage('ai', '안녕하세요! LG전자 가전제품 전문 상담원 ThinQ 봇입니다.\n무엇을 도와드릴까요?');
  }

  void _addMessage(String sender, String text) {
    setState(() {
      _messages.add({'sender': sender, 'text': text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _addMessage('user', text);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_message': text,
          'user_id': 'test_user', // 실제 앱에서는 고유 ID 사용 권장
        }),
      );

      if (response.statusCode == 200) {
        // UTF-8 디코딩 처리
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        final answer = data['answer'] ?? '죄송합니다. 답변을 받을 수 없습니다.';
        _addMessage('ai', answer);
      } else {
        _addMessage('ai', '오류가 발생했습니다. (Status: ${response.statusCode})');
      }
    } catch (e) {
      _addMessage('ai', '서버 연결에 실패했습니다.\n$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                        child: Column(
                  children: [
                            // 상단 헤더 바 (높이 고정)
                            Container(
                      height: 57 * scale,
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12 * scale),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 뒤로가기 버튼
                              SizedBox(
                                width: 24 * scale,
                                height: 24 * scale,
                                child: IconButton(
                                        icon: Icon(Icons.arrow_back,
                                            size: 24 * scale,
                                            color: Colors.black),
                                  onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LiveScreenWithButtons()),
                                          );
                                  },
                                  padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                ),
                              ),
                              // "ELLI" 텍스트
                              Padding(
                                      padding: EdgeInsets.only(
                                          left: 8 * scale), // 32 - 24 = 8
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
                                    const Spacer(), // 오른쪽 아이콘을 밀어냄
                              // 상단 오른쪽 아이콘들 (채팅 상단 아이콘.png)
                              Stack(
                                children: [
                                  // 아이콘 이미지
                                  Image.asset(
                                    'assets/images/채팅 상단 아이콘.png',
                                    width: 94.28571319580078 * scale,
                                    height: 22.285715103149414 * scale,
                                    fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                      return Container(
                                        width: 94.28571319580078 * scale,
                                              height:
                                                  22.285715103149414 * scale,
                                              color: Colors.grey
                                                  .withValues(alpha: 0.3),
                                      );
                                    },
                                  ),
                                  // 가장 왼쪽 아이콘 클릭 영역 (이미지의 왼쪽 1/3)
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                          width:
                                              (94.28571319580078 / 3) * scale,
                                    height: 22.285715103149414 * scale,
                                    child: GestureDetector(
                                      onTap: () {
                                        // 가장 왼쪽 아이콘 클릭 시 LiveScreen으로 이동
                                        Navigator.push(
                                          context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const LiveScreen()),
                                        );
                                      },
                                      child: Container(
                                              color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  // 가운데 아이콘 클릭 영역 (이미지의 가운데 1/3)
                                  Positioned(
                                          left: (94.28571319580078 / 3) *
                                              scale,
                                    top: 0,
                                          width:
                                              (94.28571319580078 / 3) * scale,
                                    height: 22.285715103149414 * scale,
                                    child: GestureDetector(
                                            onTap: () async {
                                              // 1. 백엔드 실행 요청 (비동기)
                                              try {
                                                final url = Uri.parse(
                                                    'http://192.168.0.202:8000/generate-video');
                                                http.post(url).then((response) {
                                                  print(
                                                      "Generation trigger response: ${response.statusCode}");
                                                }).catchError((error) {
                                                  print(
                                                      "Generation trigger error: $error");
                                                });
                                              } catch (e) {
                                                print(
                                                    "Error triggering generation: $e");
                                              }

                                              // 2. 화면 이동
                                        Navigator.push(
                                          context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const VideoProductionScreen()),
                                        );
                                      },
                                      child: Container(
                                              color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                            // 채팅 메시지 리스트 (Expanded)
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(16 * scale),
                                itemCount: _messages.length +
                                    (_isLoading ? 1 : 0), // 로딩 인디케이터 포함
                                itemBuilder: (context, index) {
                                  if (index == _messages.length) {
                                    // 로딩 표시
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                            vertical: 4 * scale),
                                        padding: EdgeInsets.all(12 * scale),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F1FB),
                                          borderRadius: BorderRadius.circular(
                                              12 * scale),
                                        ),
                                        child: SizedBox(
                                          width: 20 * scale,
                                          height: 20 * scale,
                                          child: const CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    );
                                  }

                                  final message = _messages[index];
                                  final isUser = message['sender'] == 'user';

                                  return Align(
                                    alignment: isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 4 * scale),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16 * scale,
                                        vertical: 10 * scale,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth: screenWidth * 0.7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? const Color(0xFF7145F1)
                                            : const Color(0xFFF3F1FB),
                                        borderRadius: BorderRadius.only(
                                          topLeft:
                                              Radius.circular(18 * scale),
                                          topRight:
                                              Radius.circular(18 * scale),
                                          bottomLeft: isUser
                                              ? Radius.circular(18 * scale)
                                              : Radius.zero,
                                          bottomRight: isUser
                                              ? Radius.zero
                                              : Radius.circular(18 * scale),
                                        ),
                                      ),
                                      child: Text(
                                        message['text']!,
                                        style: TextStyle(
                                          fontFamily: 'Noto Sans',
                                          fontSize: 14 * scale,
                                          color: isUser
                                              ? Colors.white
                                              : Colors.black,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // 하단 입력 바 (높이 고정)
                            Container(
                      height: 71 * scale,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.25),
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
                                        borderRadius: BorderRadius.circular(
                                            23 * scale),
                                ),
                                child: Row(
                                  children: [
                                    // 카메라 아이콘 (파란 동그라미)
                                    Padding(
                                            padding: EdgeInsets.only(
                                                left: 6.18 * scale),
                                      child: Container(
                                        width: 35.03 * scale,
                                        height: 34 * scale,
                                              decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                                color: Color(0xFF7145F1),
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 22.667 * scale,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                          SizedBox(width: 9.31 * scale),
                                    // 메시지 입력 텍스트
                                    Expanded(
                                      child: TextField(
                                              controller: _textController,
                                              onSubmitted: (_) =>
                                                  _sendMessage(),
                                        decoration: InputDecoration(
                                          hintText: '메세지 입력...',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Noto Sans',
                                            fontSize: 11 * scale,
                                            fontWeight: FontWeight.w400,
                                                  color:
                                                      const Color(0xFF9A9A9A),
                                            letterSpacing: 0.011 * scale,
                                            height: 1.5,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                                contentPadding:
                                                    EdgeInsets.zero,
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Noto Sans',
                                          fontSize: 11 * scale,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                          letterSpacing: 0.011 * scale,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    // 전송 버튼
                                    Padding(
                                            padding: EdgeInsets.only(
                                                right: 15.94 * scale),
                                            child: GestureDetector(
                                              onTap: _sendMessage,
                                      child: Icon(
                                        Icons.send,
                                        size: 16.485 * scale,
                                                color:
                                                    const Color(0xFF7145F1),
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
