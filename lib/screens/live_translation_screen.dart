import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  int _lineCount = 0;
  final int _maxLines = 3;
  final int _lineHeight = 24; // Approximate line height, adjust as needed

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
        Uri.parse('http://10.0.2.2:8000/api/speech'),
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
        await Future.delayed(const Duration(seconds: 1));
      }
    } else {
      print('Camera is not initialized');
    }
  }

  void _updateTranslation(String newText) {
    setState(() {
      _translation += ' $newText';
      _lineCount = '\n$_translation'.split('\n').length;

      if (_lineCount > _maxLines) {
        // Reset the translation text if it exceeds the max lines
        _translation = newText;
        _lineCount = 1; // Start with the new text as the first line
      }
    });
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
                'Translation: $_translation',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.visible,
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
