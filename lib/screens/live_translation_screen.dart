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
  WebSocketChannel? _elevenLabsChannel;
  bool _isTranslating = false;
  String _translation = '';
  bool _isCameraInitialized = false;
  String _selectedVoice = 'Voice 1';
  final AudioPlayer _audioPlayer = AudioPlayer();

  Widget _buildVoiceDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Choose voice',
        border: OutlineInputBorder(),
      ),
      value: _selectedVoice,
      items: <String>['Voice 1', 'Voice 2', 'Voice 3']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedVoice = value!;
        });
      },
    );
  }

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
        _translation = event;
      });
      if (_elevenLabsChannel != null) {
        _sendTextToElevenLabs(event);
      }
    },
    onError: (error) {
      print('WebSocket error: $error');
    },
    onDone: () {
      print('WebSocket connection closed');
    },
  );
}
void _sendTextToElevenLabs(String text) {
  if (_elevenLabsChannel != null) {
    // Add voice_id in the message
    final inputMessage = {
      "text": text, // The text you want converted to speech
      "voice_settings": {
        "stability": 0.5,
        "similarity_boost": 0.8,
      },
      "generation_config": {
        "chunk_length_schedule": [120, 160, 250, 290]
      },
      "xi_api_key": ''  
    };

    try {
      _elevenLabsChannel!.sink.add(jsonEncode(inputMessage));
      print('Sent to Eleven Labs WebSocket: ${jsonEncode(inputMessage)}');
    } catch (e) {
      print('Error sending to Eleven Labs WebSocket: $e');
    }
  } else {
    print('Eleven Labs WebSocket is not initialized');
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
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else {
      print('Camera is not initialized');
    }
  }

  @override
  void dispose() {
    _webSocketChannel?.sink.close();
    _elevenLabsChannel?.sink.close();
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
            Text(
              'Translation: $_translation',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildVoiceDropdown(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isTranslating = !_isTranslating;
                });
                if (_isTranslating) {
                  _connectToWebSocket();
                  _connectToElevenLabsWebSocket();
                  _captureAndSendFrame();
                } else {
                  _webSocketChannel?.sink.close();
                  _elevenLabsChannel?.sink.close();
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
