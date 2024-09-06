import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LiveTranslationScreen extends StatefulWidget {
  const LiveTranslationScreen({super.key});

  @override
  _LiveTranslationScreenState createState() => _LiveTranslationScreenState();
}

class _LiveTranslationScreenState extends State<LiveTranslationScreen> {
  CameraController? _controller; // Make it nullable
  WebSocketChannel? _webSocketChannel;
  bool _isTranslating = false;
  String _translation = '';
  bool _isCameraInitialized = false;
  String _selectedVoice = 'Voice 1';
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
      _isCameraInitialized = true; // Set the flag to true
    });
  }

  void _connectToWebSocket() async {
    const url = 'ws://192.168.0.111:8002';
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
          _webSocketChannel!.sink
              .add(compressedBytes); // Send the compressed bytes to the server
        } else {
          print('WebSocket is not initialized');
        }
        await Future.delayed(
            const Duration(milliseconds: 100)); // adjust the delay as needed
      }
    } else {
      print('Camera is not initialized');
    }
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 450,
            color: _isTranslating
                ? Colors.black
                : Colors.grey[300], // Change color based on translation state
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
    fontSize: 24,  // Increase font size
    fontWeight: FontWeight.bold, // Set font weight to bold
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
                _captureAndSendFrame();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Set background color to blue
              padding: const EdgeInsets.symmetric(
                  vertical: 15), // Add vertical padding
              minimumSize:
                  const Size(double.infinity, 0), // Make button take full width
            ),
            child: Text(
              _isTranslating ? 'Stop Translation' : 'Start Translation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Translation: $_translation',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
