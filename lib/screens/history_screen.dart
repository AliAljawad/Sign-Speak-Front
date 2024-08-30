import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> translationHistory = [
      {
        'date': '2023-10-01',
        'originalType': 'image',
        'originalUrl': 'https://via.placeholder.com/150',
        'translatedText': 'Hola, ¿cómo estás?',
      },
      {
        'date': '2023-10-02',
        'originalType': 'video',
        'originalUrl':
            'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        'translatedText': '¡Buenos días!',
      },
      {
        'date': '2023-10-03',
        'originalType': 'image',
        'originalUrl': 'https://via.placeholder.com/150',
        'translatedText': '¡Gracias!',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation History'),
      ),
      body: ListView.builder(
        itemCount: translationHistory.length,
        itemBuilder: (context, index) {
          final entry = translationHistory[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['date']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (entry['originalType'] == 'image')
                    Image.network(entry['originalUrl'])
                  else
                    const SizedBox(height: 150),
                  
                  const SizedBox(height: 10),
                  Text(
                    'Translated: ${entry['translatedText']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
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

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
