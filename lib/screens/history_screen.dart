import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final baseUrl = dotenv.env['BASE_URL'];


  @override
  void initState() {
    super.initState();
    _translationHistory = fetchTranslationHistory();
  }

  // Function to fetch translation history from the API
  Future<List<Map<String, dynamic>>> fetchTranslationHistory() async {
    final token = await storage.read(key: 'jwt_token');

    // Define the API endpoint
    final url = Uri.parse('$baseUrl/api/get-translations');

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
      print(data);

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
                          _formatDate(entry['created_at']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (entry['input_type'] == 'image')
                          Center(
                            child: SizedBox(
                              width: 200, // Set the desired width
                              height: 200, // Set the desired height
                              child: Image.network(
                                '$baseUrl/storage/${entry['input_data']}',
                                fit: BoxFit
                                    .cover, // Adjust the image to fit the box
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons
                                      .error); // Error handling for missing images
                                },
                              ),
                            ),
                          )
                        else if (entry['input_type'] == 'video' || entry['input_type'] == 'live')
                          Center(
                            child: SizedBox(
                              width: 200, 
                              height: 200, 
                              child: VideoWidget(
                                videoUrl: '$baseUrl/storage/${entry['input_data']}',
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          'Translated Text: ${_formatTranslatedText(entry['translated_text'])}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        if (entry['translated_audio'] != null)
                          AudioWidget(
                              audioUrl:
                                  '$baseUrl/storage/${entry['translated_audio']}'),
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

    final quarterTurns = 45; // Define the value for quarterTurns
    
    return _controller.value.isInitialized
            ? Stack(
                children: [
                  RotatedBox(quarterTurns: quarterTurns,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio*2,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  Center(
                    child: IconButton(
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 50,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                    ),
                  ),
                ],
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
        await _audioPlayer.setSourceUrl(widget.audioUrl,
            mimeType: "audio/mpeg"); // MP3 mimetype
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
          icon: Icon(isPlaying ? Icons.volume_up : Icons.volume_up_outlined),
          onPressed: _togglePlayPause,
        ),
        Text(isPlaying ? 'Pause Audio' : 'Play Audio'),
      ],
    );
  }
}

String _formatTranslatedText(String? text) {
  if (text == null || text.isEmpty) {
    return 'No translation';
  }

  // Remove brackets and commas, then join words with a space
  return text
      .replaceAll('[', '') // Remove opening brackets
      .replaceAll(']', '') // Remove closing brackets
      .replaceAll(',', '') // Remove commas
      .trim(); // Trim any leading or trailing whitespace
}

String _formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) {
    return 'Unknown Date';
  }

  try {
    // Parse the date string to a DateTime object
    final DateTime dateTime = DateTime.parse(dateString);

    // Format the DateTime object to a readable string
    final String formattedDate =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return formattedDate;
  } catch (e) {
    // Handle parsing errors
    return 'Invalid Date';
  }
}
