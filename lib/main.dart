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

Future<bool> _checkToken(BuildContext context) async {
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'jwt_token');

  if (token == null) {
    return false; // No token found, navigate to LoginPage
  }

  final response = await http.get(
    Uri.parse('http://10.0.2.2:8000/api/verify-token'),
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
