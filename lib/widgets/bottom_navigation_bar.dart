import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sign_speak/screens/history_screen.dart';
import 'package:sign_speak/screens/home_screen.dart';
import 'package:sign_speak/screens/profile_screen.dart';
import 'package:sign_speak/services/camera_sevice.dart';

class MyBottomNavigationBar extends StatefulWidget {
  const MyBottomNavigationBar({super.key});

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  int _selectedIndex = 0;
  List<Widget>? _pages;
  CameraDescription? _camera;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraService = CameraService();
    _camera = await cameraService.initializeCamera();
    setState(() {
      _pages = [
        HomePage(camera: _camera!),
        const HistoryPage(),
        const ProfilePage(),
      ];
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
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
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
