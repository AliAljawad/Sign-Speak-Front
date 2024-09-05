import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sign_speak/screens/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUserLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isUserLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    if (token == null) {
      // Handle case where token is not available (e.g., redirect to login)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8000/api/getUser'), // Adjust API endpoint as needed
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
    } else {
      // Handle error (e.g., show error message)
      final snackBar = SnackBar(
          content: Text('Failed to fetch user data: ${response.reasonPhrase}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    setState(() {
      _isUserLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    if (token == null) {
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/logout'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await storage.delete(key: 'jwt_token');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      final snackBar =
          SnackBar(content: Text('Logout failed: ${response.reasonPhrase}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    if (token == null) {
      return;
    }

    // Update the profile request
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8000/api/updateUser'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text != "***************"
            ? _passwordController.text
            : null,
      }),
    );

    if (response.statusCode == 200) {
      final snackBar = SnackBar(content: Text('Profile updated successfully'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      final snackBar =
          SnackBar(content: Text('Update failed: ${response.reasonPhrase}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isUserLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        NetworkImage('https://via.placeholder.com/150'),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: _isEditing
                          ? 'Enter new password if you want to change it'
                          : '',
                      border: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    obscureText: true,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isEditing ? _updateProfile : _toggleEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_isEditing ? 'Save changes' : 'Edit Profile',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _logout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Logout',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
    );
  }
}
