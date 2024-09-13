import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class MediaTranslationPage extends StatefulWidget {
  const MediaTranslationPage({super.key});

  @override
  _MediaTranslationPageState createState() => _MediaTranslationPageState();
}

class _MediaTranslationPageState extends State<MediaTranslationPage> {
  XFile? _mediaFile;
  VideoPlayerController? _videoController;
  String _translation = '';
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio player instance
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Pick Image'),
                onTap: () async {
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  setState(() {
                    _mediaFile = pickedFile;
                    _videoController = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Pick Video'),
                onTap: () async {
                  final XFile? pickedFile =
                      await picker.pickVideo(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    _videoController =
                        VideoPlayerController.file(File(pickedFile.path))
                          ..initialize().then((_) {
                            setState(() {});
                            _videoController!.play();
                          });
                    setState(() {
                      _mediaFile = pickedFile;
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _translateMedia() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No media file selected')),
      );
      return;
    }

    final uri = Uri.parse(_mediaFile!.path.endsWith('.mp4')
        ? 'http://10.0.2.2:8001/predict_video' // API for video
        : 'http://10.0.2.2:8001/predict_image'); // API for image

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', _mediaFile!.path));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedResponse =
            Map<String, dynamic>.from(jsonDecode(responseData));

        setState(() {
          _translation = decodedResponse['Translation'].toString();
        });

        // Send the translation to the Laravel API to get audio
        _sendTranslationForSpeech(_translation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get a response from the server')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _sendTranslationForSpeech(String text) async {
    final uri = Uri.parse('http://10.0.2.2:8000/api/speech'); // Laravel speech generation API

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        // Play the audio returned by the API
        final audioBytes = response.bodyBytes;
        final audioPath = await _saveAudioFile(audioBytes);
        await _audioPlayer.play(DeviceFileSource(audioPath)); // Updated method to play local file

        // Save the translation and media file information to the Laravel API
        _saveTranslation(text, audioPath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate speech')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while generating speech: $e')),
      );
    }
  }

  Future<void> _saveTranslation(String text, String audioPath) async {
    final jwtToken = await _storage.read(key: 'jwt_token');
    final uri = Uri.parse('http://10.0.2.2:8000/api/translations'); // Laravel store translation API

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $jwtToken'
      ..fields['input_type'] = _mediaFile!.path.endsWith('.mp4') ? 'video' : 'image'
      ..fields['translated_text'] = text
      ..files.add(await http.MultipartFile.fromPath('translated_audio', audioPath))
      ..files.add(await http.MultipartFile.fromPath('input_data', _mediaFile!.path));

    try {
      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final decodedResponse = jsonDecode(responseData);
        print(response.statusCode);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decodedResponse['message'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save translation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while saving translation: $e')),
      );
    }
  }

  Future<String> _saveAudioFile(List<int> audioBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/audio_file.mp3';
    final file = File(filePath);
    await file.writeAsBytes(audioBytes);
    return filePath;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

Widget _buildMediaPreview() {
  if (_mediaFile == null) {
    return const Text(
      'No media selected',
      style: TextStyle(fontSize: 16, color: Colors.black54),
    );
  }

  if (_mediaFile!.path.endsWith('.mp4')) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      // Check if video needs rotation
      double videoAspectRatio = _videoController!.value.aspectRatio;
      int? rotationDegrees = _videoController!.value.rotationCorrection;

      // Use Transform to apply any needed rotation
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: videoAspectRatio, // Ensure correct aspect ratio
            child: Transform.rotate(
              angle: rotationDegrees != null
                  ? rotationDegrees * (pi / 180) // Convert degrees to radians
                  : 0,
              child: VideoPlayer(_videoController!),
            ),
          ),
          Center(
            child: IconButton(
              icon: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
            ),
          ),
        ],
      );
    } else {
      return const CircularProgressIndicator();
    }
  } else {
    try {
      return Image.file(
        File(_mediaFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } catch (e) {
      return const Text(
        'Error loading image',
        style: TextStyle(fontSize: 16, color: Colors.red),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate your media',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: _buildMediaPreview(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _translation.isNotEmpty
                  ? _translation
                  : 'This is the translation of the picture or video you have uploaded',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickMedia,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upload Image or Video',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _translateMedia,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Translate Media',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
