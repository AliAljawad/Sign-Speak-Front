import 'package:flutter/material.dart';

class MediaTranslationPage extends StatefulWidget {
  const MediaTranslationPage({super.key});

  @override
  _MediaTranslationPageState createState() => _MediaTranslationPageState();
}

class _MediaTranslationPageState extends State<MediaTranslationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate your media'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text('Media Preview'),
        ),
      ),
    );
  }
}
