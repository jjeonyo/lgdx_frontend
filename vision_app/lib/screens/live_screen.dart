import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image/image.dart' as img;
import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'live_screen_with_buttons.dart';
import 'chat_screen.dart';
import 'customer_service_screen.dart';
import 'elli_home_screen.dart';
import 'video_production_screen.dart';
import '../services/live_camera_service.dart';
import '../config/api_config.dart';

// -----------------------------------------------------------------------------
// Isolate Functions for Image Conversion (No Changes)
// -----------------------------------------------------------------------------
Future<String?> convertYUV420ToBase64(Map<String, dynamic> params) async {
  try {
    final int width = params['width'];
    final int height = params['height'];
    final Uint8List yPlane = params['yPlane'];
    final Uint8List uPlane = params['uPlane'];
    final Uint8List vPlane = params['vPlane'];
    final int yRowStride = params['yRowStride'];
    final int uvRowStride = params['uvRowStride'];
    final int uvPixelStride = params['uvPixelStride'];

    final img.Image image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int yIndex = y * yRowStride + x;

        final int yp = yPlane[yIndex];
        final int up = uPlane[uvIndex];
        final int vp = vPlane[uvIndex];

        int r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
        int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
            .round()
            .clamp(0, 255);
        int b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return base64Encode(img.encodeJpg(image, quality: 50));
  } catch (e) {
    debugPrint("YUV Conversion Error: $e");
    return null;
  }
}

Future<String?> convertBGRAToBase64(Map<String, dynamic> params) async {
  try {
    final int width = params['width'];
    final int height = params['height'];
    final Uint8List bgraPlane = params['bgraPlane'];

    final img.Image image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: bgraPlane.buffer,
      order: img.ChannelOrder.bgra,
    );

    return base64Encode(img.encodeJpg(image, quality: 50));
  } catch (e) {
    debugPrint("BGRA Conversion Error: $e");
    return null;
  }
}

// -----------------------------------------------------------------------------
// Main LiveScreen Widget
// -----------------------------------------------------------------------------
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

  // Gemini Live 관련 상태
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _isCameraInitialized = false;

  DateTime _lastFrameTime = DateTime.now();
  bool _isProcessingFrame = false;

  // [수정됨] 오디오 플레이어 스트림 초기화 상태 플래그
  bool _isAudioPlayerReady = false;

  // ⚠️ 자신의 PC IP 주소로 변경 필요
  // Android Emulator: 10.0.2.2, Real Device: 192.168.x.x
  final String _wsUrl = 'ws://192.168.0.47:8000/ws/chat';

  // Audio Stream Controller
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>();
  StreamSink<Uint8List> get _audioStreamSink => _audioStreamController.sink;

  String _aiResponseText = "제가 도와드릴게요, 엘지님!\n오류 상황을 보여주시겠어요?";

  // Buffer to accumulate text parts for the current response
  String _currentResponseBuffer = "";
  String? _currentResponseId;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
    _handleAudioStream();
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

  Future<void> _initializePermissions() async {
    await [Permission.camera, Permission.microphone].request();
    await _initializeCamera();
    await _initializeAudio();

    // Auto start streaming after initialization
    if (_isCameraInitialized) {
      _startStreaming();
    }
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

    if (_isCameraInitialized) {
      _startStreaming();
    }
  }

  Future<void> _initializeAudio() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      print("✅ WebSocket Connected");

      _channel!.stream.listen(
        (message) {
          if (message is List<int>) {
            // Binary Audio from Server
            _playAudioChunk(Uint8List.fromList(message));
          } else {
            _handleServerMessage(message);
          }
        },
        onError: (error) {
          print("❌ WebSocket Error: $error");
          _stopStreaming();
        },
        onDone: () {
          print("🔌 WebSocket Closed");
          _stopStreaming();
        },
      );
    } catch (e) {
      print("❌ Connection Failed: $e");
    }
  }

  void _handleServerMessage(dynamic message) async {
    try {
      final decoded = jsonDecode(message);
      final type = decoded['type'];
      final data = decoded['data'];
      final id = decoded['id'];

      if (type == 'audio_partial') {
        final audioBytes = base64Decode(data);
        await _playAudioChunk(audioBytes);
      } else if (type == 'text_partial') {
        setState(() {
          if (id != null && id != _currentResponseId) {
            _currentResponseId = id;
            _currentResponseBuffer = "";
          }
          _currentResponseBuffer += data;
          _aiResponseText = _currentResponseBuffer;
        });
      } else if (type == 'text') {
        setState(() {
          _aiResponseText = data;
        });
      } else if (type == 'turn_complete') {
        // Handle end of turn logic if needed
      }
    } catch (e) {
      print("Message Error: $e");
    }
  }

  // [수정됨] 오디오 청크 처리 함수: 중복 초기화 방지
  Future<void> _playAudioChunk(Uint8List data) async {
    if (data.isEmpty) return;

    try {
      // 1. 플레이어 스트림이 준비되지 않았다면 1회만 시작
      if (!_isAudioPlayerReady) {
        await _player.startPlayerFromStream(
          codec: Codec.pcm16,
          numChannels: 1, // Mono
          sampleRate: 24000, // 서버(OpenAI) 설정과 일치해야 함
          bufferSize: 8192,
          interleaved: false,
        );
        _isAudioPlayerReady = true;
      }

      // 2. 준비된 스트림에 데이터만 계속 주입
      await _player.feedFromStream(data);
    } catch (e) {
      print("Audio Playback Error: $e");
      // 에러 발생 시 재시도 로직이나 상태 초기화가 필요할 수 있음
    }
  }

  Future<void> _startStreaming() async {
    if (!_isCameraInitialized) return;
    if (_channel == null) _connectWebSocket();
    if (_isStreaming) return;

    setState(() {
      _isStreaming = true;
    });

    // 1. Start Audio Recording Stream
    await _recorder.startRecorder(
      toStream: _audioStreamSink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 24000,
    );

    // 2. Start Video Stream (Throttle ~10 FPS)
    await _cameraController!.startImageStream((CameraImage image) {
      if (_isProcessingFrame) return;
      if (DateTime.now().difference(_lastFrameTime).inMilliseconds < 100)
        return;

      _isProcessingFrame = true;
      _lastFrameTime = DateTime.now();
      _processCameraImage(image);
    });
  }

  void _processCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    if (image.format.group == ImageFormatGroup.yuv420) {
      final Uint8List yPlane = Uint8List.fromList(image.planes[0].bytes);
      final Uint8List uPlane = Uint8List.fromList(image.planes[1].bytes);
      final Uint8List vPlane = Uint8List.fromList(image.planes[2].bytes);
      final int yRowStride = image.planes[0].bytesPerRow;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;

      compute(convertYUV420ToBase64, {
        'width': width,
        'height': height,
        'yPlane': yPlane,
        'uPlane': uPlane,
        'vPlane': vPlane,
        'yRowStride': yRowStride,
        'uvRowStride': uvRowStride,
        'uvPixelStride': uvPixelStride,
      }).then((base64Result) {
        if (base64Result != null && _isStreaming && _channel != null) {
          _channel!.sink.add(
            jsonEncode({"type": "image_base64", "data": base64Result}),
          );
        }
        _isProcessingFrame = false;
      });
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final Uint8List bgraPlane = Uint8List.fromList(image.planes[0].bytes);
      compute(convertBGRAToBase64, {
        'width': width,
        'height': height,
        'bgraPlane': bgraPlane,
      }).then((base64Result) {
        if (base64Result != null && _isStreaming && _channel != null) {
          _channel!.sink.add(
            jsonEncode({"type": "image_base64", "data": base64Result}),
          );
        }
        _isProcessingFrame = false;
      });
    } else {
      _isProcessingFrame = false;
    }
  }

  void _handleAudioStream() {
    _audioStreamController.stream.listen((data) {
      if (_isStreaming && _channel != null) {
        _channel!.sink.add(data);
      }
    });
  }

  Future<void> _stopStreaming() async {
    setState(() {
      _isStreaming = false;
    });

    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }

    await _recorder.stopRecorder();
    await _player.stopPlayer();

    // [중요] 스트리밍 중단 시 플레이어 상태 초기화
    _isAudioPlayerReady = false;

    _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _cameraController?.dispose();
    _audioStreamController.close();
    _cameraService.stopStreaming();
    super.dispose();
  }

  static const double figmaHeight = 800;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF9FD),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF4F2FD),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
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
                    colors: [Color(0xFFF3F1FB), Color(0xFF7145F1)],
                    stops: [0.42, 1.0],
                  ),
                ),
              ),
            ),
            // 상태바 영역
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24 * scale,
              child: Container(color: const Color(0xFFFAF9FD)),
            ),
            // "실시간 진단" 텍스트
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
            // 오른쪽 상단 아이콘들
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
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/images/라이브상단아이콘.svg',
                      width: 24 * scale,
                      height: 24 * scale,
                    ),
                  ),
                  SizedBox(width: 15 * scale), // gap-[15px]
                  // 재생 리스트 아이콘 (play-list) - generate.py 실행
                  // Figma: size-[21px]
                  GestureDetector(
                    onTap: () async {
                      // 1. 백엔드 generate.py 실행 요청 (비동기)
                      try {
                        final url = Uri.parse(
                          '${ApiConfig.baseUrl}/generate-video',
                        );
                        http
                            .post(url)
                            .then((response) {
                              print(
                                "Generation trigger response: ${response.statusCode}",
                              );
                            })
                            .catchError((error) {
                              print("Generation trigger error: $error");
                            });
                      } catch (e) {
                        print("Error triggering generation: $e");
                      }

                      // 2. 화면 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VideoProductionScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 21 * scale,
                      height: 21 * scale,
                      color: Colors.transparent,
                      // 재생 리스트 아이콘 SVG (assets에 있다고 가정, 없으면 다른 아이콘으로 대체 가능)
                      child: Icon(
                        Icons.playlist_play,
                        size: 21 * scale,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 15 * scale), // gap-[15px]
                  // 헤드셋 아이콘 (Group)
                  // Figma: size-[22.286px]
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerServiceScreen(),
                        ),
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
                  child:
                      _cameraService.cameraController != null &&
                          _cameraService.cameraController!.value.isInitialized
                      ? SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: CameraPreview(
                            _cameraService.cameraController!,
                          ),
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
            // 캐릭터 이미지
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
                    child: Icon(
                      Icons.person,
                      size: 40 * scale,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            // 말풍선
            Positioned(
              top: 509 * scale,
              left: (19 + 95 + 10) * scale,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LiveScreenWithButtons(),
                  ),
                ),
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
                      _aiResponseText,
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
                    final success = await _cameraService.startStreaming(
                      context,
                    );
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
                          const SnackBar(
                            content: Text('라이브 스트리밍 시작에 실패했습니다. 권한을 확인해주세요.'),
                          ),
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
            // 세 번째 버튼 (Rectangle 291): Frame 내부 x=180, y=0, width=66, height=44
            // X 버튼: 진단 화면 종료 및 엘리홈으로 이동
            Positioned(
              top: 687 * scale,
              left: 237 * scale,
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
                        MaterialPageRoute(
                          builder: (context) => const ElliHomeScreen(),
                        ),
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
}
