import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_speak/screens/history_screen.dart';
import 'package:sign_speak/screens/live_translation_screen.dart';
import 'package:sign_speak/screens/login_screen.dart';
import 'package:sign_speak/screens/media_translation_screen.dart';
import 'package:sign_speak/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyBottomNavigationBar extends StatefulWidget {
  const MyBottomNavigationBar({super.key});

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  int _selectedIndex = 0;
  List<Widget>? _pages;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    _userRole = await _storage.read(key: 'role');

    if (_userRole == null) {
      // Handle missing token/role, redirect to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      print('user role found');
    } else {
      _initializePages();
    }
  }

  void _initializePages() {
    setState(() {
      if (_userRole == 'regular') {
        _pages = [
          const LiveTranslationScreen(), // Home for regular user
          const MediaTranslationPage(),
          const HistoryPage(),
          const ProfilePage(),
        ];
      } else if (_userRole == 'mute') {
        _pages = [
          // Define mute user-specific pages
          const MediaTranslationPage(),
          const HistoryPage(),
          const ProfilePage(),
        ];
      }
    });
  }

  Future<bool> _checkToken(BuildContext context) async {
    final token = await _storage.read(key: 'jwt_token');
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
        return true; // Token is valid
      } else {
        await _storage.delete(key: 'jwt_token');
        return false; // Token is invalid
      }
    } else {
      await _storage.delete(key: 'jwt_token');
      return false; // Error occurred
    }
  }

  void _onItemTapped(int index) async {
    bool isValid =
        await _checkToken(context); // Check the token on every navigation

    if (isValid) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // If token is invalid, redirect to the LoginPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages == null
          ? const Center(child: CircularProgressIndicator())
          : _pages![_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: _userRole == 'regular'
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.videocam),
                  label: "Media Translation",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: "History",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.videocam),
                  label: "Media Translation",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: "History",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ],
      ),
    );
  }
}
