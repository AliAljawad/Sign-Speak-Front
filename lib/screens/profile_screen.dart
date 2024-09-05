import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:sign_speak/screens/login_screen.dart';
import 'package:http_parser/http_parser.dart';

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
  bool _isUserLoading = true;
  File? _profileImage;
  String _profileImageUrl = '';

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/getUser'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _profileImageUrl = data['profile_image'] ?? ''; // Remote image URL

      setState(() {
        // If there's a remote URL, we do not set _profileImage as FileImage is not applicable
      });
    } else {
      final snackBar = SnackBar(
        content: Text('Failed to fetch user data: ${response.reasonPhrase}'),
      );
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
      final snackBar = SnackBar(
        content: Text('Logout failed: ${response.reasonPhrase}'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    if (token == null) {
      return;
    }

    final putResponse = await http.put(
      Uri.parse('http://10.0.2.2:8000/api/updateUser'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': _nameController.text,
        'email': _emailController.text,
        if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
      }),
    );

    if (putResponse.statusCode == 200) {
      print('Profile updated successfully');
    } else {
      print('Failed to update profile: ${putResponse.reasonPhrase}');
    }

    // Upload the profile image with POST request (only if image is selected)
    if (_profileImage != null) {
      final postRequest = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/api/upload-image'),
      );

      postRequest.headers['Authorization'] = 'Bearer $token';

      try {
        final imageFile = await http.MultipartFile.fromPath(
          'profile_image',
          _profileImage!.path,
          contentType: MediaType('image', 'jpeg'),
          filename: 'profile_image.jpg',
        );
        postRequest.files.add(imageFile);

        final imageResponse = await postRequest.send();

        if (imageResponse.statusCode == 200) {
          print('Profile image uploaded successfully');
        } else {
          print('Failed to upload profile image: ${imageResponse.statusCode}');
        }
      } catch (e) {
        print('Error uploading profile image: $e');
      }
    }

    setState(() {
      _isEditing = false;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
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
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: CircleAvatar(
  radius: 50,
  backgroundImage: _profileImage != null
      ? FileImage(_profileImage!)
      : _profileImageUrl.isNotEmpty
          ? NetworkImage('http://10.0.2.2:8000/storage/$_profileImageUrl')
          : const AssetImage('assets/default_image.jpg') as ImageProvider,
  child: _profileImage == null && _profileImageUrl.isEmpty
      ? const Icon(Icons.camera_alt, size: 50, color: Colors.white)
      : null,
),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
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
                        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
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
                      hintText: _isEditing ? 'Enter new password if you want to change it' : '',
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
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
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
    );
  }
}