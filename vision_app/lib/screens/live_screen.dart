import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'live_screen_with_buttons.dart';
import 'chat_screen.dart';
import 'video_production_screen.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  // Figma 프레임 크기: 360x800
  static const double figmaWidth = 360;
  // static const double figmaHeight = 800;

  // Gemini Live 관련 상태
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  
  bool _isStreaming = false;
  bool _isCameraInitialized = false;
  Timer? _videoTimer;
  // StreamSubscription? _recorderSubscription;
  
  // ⚠️ 자신의 PC IP 주소로 변경 필요
  // Android Emulator: 10.0.2.2
  // Real Device: 192.168.x.x
  final String _wsUrl = 'ws://192.168.0.10:8000/ws/chat';

  // Audio Stream Controller
  final StreamController<Uint8List> _audioStreamController = StreamController<Uint8List>();
  StreamSink<Uint8List> get _audioStreamSink => _audioStreamController.sink;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
    _handleAudioStream();
  }

  Future<void> _initializePermissions() async {
    await [Permission.camera, Permission.microphone].request();
    await _initializeCamera();
    await _initializeAudio();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _initializeAudio() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      print("✅ WebSocket Connected");

      _channel!.stream.listen((message) {
        _handleServerMessage(message);
      }, onError: (error) {
        print("❌ WebSocket Error: $error");
        _stopStreaming();
      }, onDone: () {
        print("🔌 WebSocket Closed");
        _stopStreaming();
      });
    } catch (e) {
      print("❌ Connection Failed: $e");
    }
  }

  void _handleServerMessage(dynamic message) async {
    try {
      final decoded = jsonDecode(message);
      if (decoded['type'] == 'audio') {
        final audioBytes = base64Decode(decoded['data']);
        await _playAudioChunk(audioBytes);
      } else if (decoded['type'] == 'text') {
        print("[Gemini]: ${decoded['data']}");
      }
    } catch (e) {
      print("Message Error: $e");
    }
  }

  Future<void> _playAudioChunk(Uint8List data) async {
    if (_player.isPlaying) {
      await _player.feedFromStream(data);
    } else {
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 24000,
        bufferSize: 8192,
        interleaved: false, // Mono audio
      );
      await _player.feedFromStream(data);
    }
  }

  Future<void> _startStreaming() async {
    if (!_isCameraInitialized) return;
    if (_channel == null) _connectWebSocket();

    setState(() {
      _isStreaming = true;
    });

    // 1. Start Audio Recording Stream
    await _recorder.startRecorder(
      toStream: _audioStreamSink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );

    // 2. Start Video Timer (1 FPS)
    _videoTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          final image = await _cameraController!.takePicture();
          final bytes = await image.readAsBytes();
          final b64 = base64Encode(bytes);
          
          _channel?.sink.add(jsonEncode({
            "type": "image",
            "data": b64
          }));
        } catch (e) {
          print("Camera Capture Error: $e");
        }
      }
    });
  }

  void _handleAudioStream() {
    _audioStreamController.stream.listen((data) {
      if (_isStreaming && _channel != null) {
        _channel!.sink.add(jsonEncode({
          "type": "audio",
          "data": base64Encode(data)
        }));
      }
    });
  }

  Future<void> _stopStreaming() async {
    setState(() {
      _isStreaming = false;
    });

    _videoTimer?.cancel();
    await _recorder.stopRecorder();
    await _player.stopPlayer();
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    _videoTimer?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    _cameraController?.dispose();
    _audioStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 상태바 스타일 설정
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
      backgroundColor: const Color(0xFFF3F1FB),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            // 배경 그라데이션
            Positioned(
              top: 24 * scale,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF3F1FB),
                      Color(0xFF7145F1),
                    ],
                    stops: [0.42, 1.0],
                  ),
                ),
              ),
            ),
            // 상단 상태바 영역
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24 * scale,
              child: Container(color: const Color(0xFFFAF9FD)),
            ),
            // "실시간 진단" 텍스트와 빨간 점
            Positioned(
              top: 70 * scale,
              left: 23 * scale,
              child: Row(
                children: [
                  Container(
                    width: 9 * scale,
                    height: 9 * scale,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF0004),
                    ),
                  ),
                  SizedBox(width: 10 * scale),
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
            // 오른쪽 상단 아이콘 버튼들
            Positioned(
              top: 69 * scale,
              left: 246 * scale,
              child: Stack(
                children: [
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
                  // 채팅 아이콘 클릭 영역
                  Positioned(
                    left: 0,
                    top: 0,
                    width: (97.28571319580078 / 3) * scale,
                    height: 24 * scale,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // 동영상 아이콘 클릭 영역
                  Positioned(
                    left: (97.28571319580078 / 3) * scale,
                    top: 0,
                    width: (97.28571319580078 / 3) * scale,
                    height: 24 * scale,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideoProductionScreen())),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
            // 중앙 비디오 영역 (카메라 프리뷰 연결)
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
                  borderRadius: BorderRadius.circular(6 * scale),
                  child: _isCameraInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(
                          child: Icon(
                            Icons.videocam,
                            size: 60,
                            color: Color(0xFFAFB1B6),
                          ),
                        ),
                ),
              ),
            ),
            // 왼쪽 하단 캐릭터 이미지
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
            Positioned(
              top: 509 * scale,
              left: (19 + 95 + 10) * scale,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveScreenWithButtons())),
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
            // 하단 컨트롤 버튼들
            // 첫 번째 버튼 (카메라/스트리밍 토글)
            Positioned(
              top: 687 * scale,
              left: 57 * scale,
              child: GestureDetector(
                onTap: _isStreaming ? _stopStreaming : _startStreaming,
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
            // 두 번째 버튼 (재생)
            Positioned(
              top: 687 * scale,
              left: 147 * scale,
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
                        color: const Color(0xFF29344E).withValues(alpha: 0.54),
                      );
                    },
                  ),
                ),
              ),
            ),
            // 세 번째 버튼 (닫기)
            Positioned(
              top: 687 * scale,
              left: 237 * scale,
              child: GestureDetector(
                onTap: () {
                  _stopStreaming();
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
