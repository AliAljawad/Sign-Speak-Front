import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;


class LiveTranslationScreen extends StatefulWidget {
  const LiveTranslationScreen({super.key});

  @override
  _LiveTranslationScreenState createState() => _LiveTranslationScreenState();
}

class _LiveTranslationScreenState extends State<LiveTranslationScreen> {
  CameraController? _controller;
  WebSocketChannel? _webSocketChannel;
  bool _isTranslating = false;
  String _translation = '';
  bool _isCameraInitialized = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final int _maxLines = 3;
  bool _isRecording = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final baseUrl = dotenv.env['BASE_URL'];


  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _controller = CameraController(camera, ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _connectToWebSocket() async {
    const url = 'ws://192.168.0.111:8002'; // Your server WebSocket URL
    final webSocketChannel = WebSocketChannel.connect(Uri.parse(url));
    setState(() {
      _webSocketChannel = webSocketChannel;
    });

    webSocketChannel.stream.listen(
      (event) {
        print('Received from WebSocket: $event');
        setState(() {
          _updateTranslation(event);
        });
        _sendTextToElevenLabs(event);
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  void _sendTextToElevenLabs(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/speech'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
        }),
      );
      print('Received response from Eleven Labs: ${response.body}');
      print('Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        // The response contains the audio data in MP3 format
        final Uint8List audioData = response.bodyBytes;
        print('Received audio data, length: ${audioData.length}');
        _playAudioChunk(audioData);
      } else {
        print('Failed to generate speech: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating speech: $e');
    }
  }

  void _playAudioChunk(Uint8List audioData) async {
    print('Playing audio chunk, length: ${audioData.length}');
    await _audioPlayer.play(BytesSource(audioData));
    print('Finished playing audio chunk');
  }

  void _captureAndSendFrame() async {
    if (_controller != null && _controller!.value.isInitialized) {
      while (_isTranslating) {
        final XFile image = await _controller!.takePicture();
        final Uint8List bytes = await image.readAsBytes();
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 480,
          minWidth: 640,
          quality: 90,
        );
        if (_webSocketChannel != null) {
          _webSocketChannel!.sink.add(compressedBytes);
          print('Sent compressed image data to WebSocket');
        } else {
          print('WebSocket is not initialized');
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } else {
      print('Camera is not initialized');
    }
  }

void _updateTranslation(String newText) {
  setState(() {
    _translation += ' $newText';

    // Estimate the average character width (this is approximate and can vary with different fonts)
    const double avgCharWidth = 12.0; // Rough estimate for a 24 font size

    // Calculate the available width of the text container
    final double containerWidth = MediaQuery.of(context).size.width - 40; // Subtracting padding

    // Calculate the number of characters that can fit in one line
    final int charsPerLine = (containerWidth / avgCharWidth).floor();

    // Calculate the total number of characters in the current translation
    final int totalChars = _translation.length;

    // Calculate the number of lines based on the character count
    final int lines = (totalChars / charsPerLine).ceil();

    // Reset the translation if the number of lines exceeds the max allowed
    if (lines > _maxLines) {
      _translation = newText; // Reset to the new incoming text
    }
  });
}



  void _sendVideoToApi(XFile videoFile) async {
  final jwtToken = await _storage.read(key: 'jwt_token');
  try {
    var request = http.MultipartRequest(
      'POST', Uri.parse('$baseUrl/api/translations'),);
      request.headers['Authorization'] = 'Bearer $jwtToken';
    // Add the video file
    request.files.add(await http.MultipartFile.fromPath(
      'input_data', videoFile.path,
      contentType: MediaType('video', 'mp4'),
    ));

    // Add translated text
    request.fields['translated_text'] = _translation;
    request.fields['input_type'] = 'live';
    var response = await request.send();
    if (response.statusCode == 201) {
      print('Video and translation sent successfully');
    } else {
      print('Failed to send video and translation');
    }
  } catch (e) {
    print('Error sending video: $e');
  }
}


  @override
  void dispose() {
    _webSocketChannel?.sink.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Live Translation',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 450,
              color: _isTranslating ? Colors.black : Colors.grey[300],
              child: _isCameraInitialized
                  ? CameraPreview(_controller!)
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                ' $_translation',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
  onPressed: () async {
    if (_controller != null && _controller!.value.isInitialized) {
      if (!_controller!.value.isRecordingVideo) {
        // Start recording video
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      } else {
        // Stop recording and save the file
        final XFile videoFile = await _controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
        });
        // Send the video file to the API along with the translation
        _sendVideoToApi(videoFile);
      }
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    padding: const EdgeInsets.symmetric(vertical: 15),
    minimumSize: const Size(double.infinity, 0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
  child: Text(
    _isRecording ? 'Stop Recording' : 'Record',
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
  ),
),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isTranslating = !_isTranslating;
                });
                if (_isTranslating) {
                  _connectToWebSocket();
                  _captureAndSendFrame();
                } else {
                  _webSocketChannel?.sink.close();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                _isTranslating ? 'Stop Translation' : 'Start Translation',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
