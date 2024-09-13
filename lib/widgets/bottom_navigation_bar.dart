import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    _checkUserRoleAndToken();
  }

  Future<void> _checkUserRoleAndToken() async {
    // Retrieve the JWT token and user role from secure storage
    _jwtToken = await _storage.read(key: 'jwt_token');
    _userRole = await _storage.read(key: 'user_role');

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
          // Define non-verbal user-specific pages
          const LiveTranslationScreen(), 
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
