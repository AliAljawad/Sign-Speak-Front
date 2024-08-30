import 'package:flutter/material.dart';

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
    'originalUrl': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
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
        return Container(); 
      },
    ),
  );
}
}
