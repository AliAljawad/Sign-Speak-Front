import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _translationHistory;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _translationHistory = fetchTranslationHistory();
  }

  // Function to fetch translation history from the API
  Future<List<Map<String, dynamic>>> fetchTranslationHistory() async {
    final token = await storage.read(key: 'jwt_token');

    // Define the API endpoint
    final url = Uri.parse('http://10.0.2.2:8000/api/get-translations');

    // Send GET request with the JWT token in the Authorization header
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Parse the response body as a list of translations
      List<dynamic> data = jsonDecode(response.body);
      print( data);

      // Return the list of translation maps
      return List<Map<String, dynamic>>.from(data);
    } else {
      // If the server returns an error, throw an exception
      throw Exception('Failed to load translation history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _translationHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No translation history found.'));
          } else {
            final translationHistory = snapshot.data!;
            return ListView.builder(
              itemCount: translationHistory.length,
              itemBuilder: (context, index) {
                final entry = translationHistory[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry['created_at'] ?? 'Unknown Date'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (entry['input_type'] == 'image')
                          Image.network(
                            'http://10.0.2.2:8000/storage/${entry['input_data']}',
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons
                                  .error); // Error handling for missing images
                            },
                          )
                        else if (entry['input_type'] == 'video')
                          VideoWidget(
                              videoUrl:
                                  'http://10.0.2.2:8000/storage/${entry['input_data']}'),
                        const SizedBox(height: 10),
                        Text(
                          'Translated Text: ${entry['translated_text'] ?? 'No translation'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        if (entry['translated_audio'] != null)
                          AudioWidget(
                              audioUrl:
                                  'http://10.0.2.2:8000/storage/${entry['translated_audio']}'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
class VideoWidget extends StatefulWidget {
  final String videoUrl;

  const VideoWidget({required this.videoUrl, super.key});

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // Use the new VideoPlayerController.networkUrl
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.play();
          });
        }
      }).catchError((error) {
        print('Error initializing video: $error');
        setState(() {
          _isError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(child: Text('Failed to load video.'));
    }

    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: VideoPlayer(_controller),
            ),
          )
        : const Center(child: CircularProgressIndicator());
        
  }
}

class AudioWidget extends StatefulWidget {
  final String audioUrl;

  const AudioWidget({required this.audioUrl, super.key});

  @override
  _AudioWidgetState createState() => _AudioWidgetState();
}

class _AudioWidgetState extends State<AudioWidget> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

void _togglePlayPause() async {
  try {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setSourceUrl(widget.audioUrl, mimeType: "audio/mpeg"); // MP3 mimetype
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  } catch (e) {
    print('Error playing audio: $e');
    setState(() {
      _isError = true;
    });
  }
}


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Text('Failed to play audio.');
    }

    return Row(
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlayPause,
        ),
        Text(isPlaying ? 'Pause Audio' : 'Play Audio'),
      ],
    );
  }
}
