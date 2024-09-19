import 'package:flutter/material.dart';
import 'package:sign_speak/screens/login_screen.dart';
import 'package:sign_speak/widgets/bottom_navigation_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  await dotenv.load(); // Make sure to await the load method
  print('BASE_URL: ${dotenv.env['BASE_URL']}');
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: MediaTranslationPage(),
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

Future<bool> _checkToken(BuildContext context) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'jwt_token');
  final baseUrl = dotenv.env['BASE_URL'];

  if (token == null) {
    return false; // No token found, navigate to LoginPage
  }

  final response = await http.get(
    Uri.parse('$baseUrl/api/verify-token'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['valid']) {
      return true; // Token is valid, navigate to MyBottomNavigationBar
    } else {
      await storage.delete(key: 'jwt_token');
      return false; // Token is invalid, navigate to LoginPage
    }
  } else {
    await storage.delete(key: 'jwt_token');
    return false; // Error occurred, navigate to LoginPage
  }
}
