import 'package:flutter/material.dart';
import 'package:sign_speak/screens/login_screen.dart';
import 'package:sign_speak/widgets/bottom_navigation_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _checkToken(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred'));
          }
          return snapshot.data == true
              ? const MyBottomNavigationBar()
              : const LoginPage();
        },
      ),
    );
  }
}
