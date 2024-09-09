import 'dart:convert'; 
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';


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
                  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
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
                  final XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    _videoController = VideoPlayerController.file(File(pickedFile.path))
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
        final decodedResponse = Map<String, dynamic>.from(jsonDecode(responseData));

        setState(() {
          _translation = decodedResponse['Translation'].toString();
        });
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
  final uri = Uri.parse('http://10.0.2.2:8000/api/speech');
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
      await _audioPlayer.play(DeviceFileSource(audioPath));
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
      return _videoController != null && _videoController!.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          : const CircularProgressIndicator();
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
              style: const TextStyle(fontSize: 16),
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
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
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
                'Translate',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
