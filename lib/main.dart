import 'package:flutter/material.dart';
import 'package:sign_speak/screens/login_screen.dart';
import 'package:sign_speak/screens/sign_up_screen.dart';
import 'package:sign_speak/widgets/bottom_navigation_bar.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return  const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage()
    );
    }
}

