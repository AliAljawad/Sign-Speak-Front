import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LiveTranslationScreen extends StatefulWidget {
  @override
  _LiveTranslationScreenState createState() => _LiveTranslationScreenState();
}

class _LiveTranslationScreenState extends State<LiveTranslationScreen> {
  CameraController? _controller; // Make it nullable
  WebSocketChannel? _webSocketChannel;
  bool _isTranslating = false;
  String _translation = '';
  bool _isCameraInitialized = false; // Add a flag to track camera initialization

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
      _isCameraInitialized = true; // Set the flag to true
    });
  }

  void _connectToWebSocket() async {
    const url = 'ws://10.0.2.2:8002';
    final webSocketChannel = WebSocketChannel.connect(Uri.parse(url));
    setState(() {
      _webSocketChannel = webSocketChannel;
    });
    webSocketChannel.stream.listen((event) {
      setState(() {
        _translation = event;
      });
    });
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
        _webSocketChannel!.sink.add(compressedBytes); // Send the compressed bytes to the server
      } else {
        print('WebSocket channel is null');
      }
      await Future.delayed(const Duration(milliseconds: 100)); // adjust the delay as needed
    }
  } else {
    print('Camera is not initialized');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Translation'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 450,
            color: _isTranslating ? Colors.black : Colors.grey[300],
            child: _isCameraInitialized
                ? CameraPreview(_controller!)
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          const SizedBox(height: 20),
          const Text(
            'This is live translation of the camera feed',
            style: TextStyle(fontSize: 16),
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
              }
            },
            child: Text(_isTranslating ? 'Stop Translation' : 'Start Translation'),
          ),
          const SizedBox(height: 20),
          Text(
            'Translation: $_translation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}