import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sign_speak/screens/history_screen.dart';
import 'package:sign_speak/screens/live_translation_screen.dart';
import 'package:sign_speak/screens/login_screen.dart';
import 'package:sign_speak/screens/media_translation_screen.dart';
import 'package:sign_speak/screens/profile_screen.dart';

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
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _checkToken(context); // Check token validity before initializing pages
  }

  Future<bool> _checkToken(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    if (token == null) {
      // No token found, navigate to LoginPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return false;
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
        // Token is valid, initialize the user role and pages
        _checkUserRoleAndToken();
        return true;
      } else {
        // Token is invalid, delete token and navigate to LoginPage
        await storage.delete(key: 'jwt_token');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return false;
      }
    } else {
      // Error occurred, delete token and navigate to LoginPage
      await storage.delete(key: 'jwt_token');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return false;
    }
  }

  Future<void> _checkUserRoleAndToken() async {
    // Retrieve the JWT token and user role from secure storage
    _jwtToken = await _storage.read(key: 'jwt_token');
    _userRole = await _storage.read(key: 'role');

    if (_jwtToken == null || _userRole == null) {
      // Handle missing token/role, maybe redirect to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      print('No token or user role found');
      // Redirect to login or show error message
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
          const LiveTranslationScreen(), // You can add specific non-verbal pages
          const HistoryPage(),
          const ProfilePage(),
        ];
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: "Media",
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
