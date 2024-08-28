import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class HomePage extends StatefulWidget {
  final CameraDescription camera;

  const HomePage({super.key, required this.camera});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  void _toggleTranslating() {
    setState(() {
      if (_isTranslating) {
        _controller.dispose();
      } else {
        _controller = CameraController(
          widget.camera,
          ResolutionPreset.high,
        );
        _initializeControllerFuture = _controller.initialize();
      }
      _isTranslating = !_isTranslating;
    });
  }

  Widget _buildCameraPreview() {
    return _isTranslating
        ? FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          )
        : const Center(child: Icon(Icons.camera_alt, color: Colors.grey, size: 50));
  }

  Widget _buildVoiceDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Choose voice',
        border: OutlineInputBorder(),
      ),
      items: <String>['Voice 1', 'Voice 2', 'Voice 3']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? value) {
        // Handle voice selection
      },
    );
  }

  Widget _buildTranslateButton() {
    return ElevatedButton(
      onPressed: _toggleTranslating,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: Text(
        _isTranslating ? 'Stop Translating' : 'Start Translating',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Camera Translation',
          style: TextStyle(
            fontSize: 30,
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
              height: 300,
              color: _isTranslating ? Colors.black : Colors.grey[300],
              child: _buildCameraPreview(),
            ),
            const SizedBox(height: 20),
            const Text(
              'This is live translation of the camera feed',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildVoiceDropdown(),
            const SizedBox(height: 20),
            _buildTranslateButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
