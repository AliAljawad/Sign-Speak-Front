import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController =
    TextEditingController(text: "John Doe");
final TextEditingController _emailController =
    TextEditingController(text: "JohnDoe@gmail.com");
final TextEditingController _passwordController =
    TextEditingController(text: "***************");
    bool _isEditing = false;

void _toggleEdit() {
  setState(() {
    _isEditing = !_isEditing;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Column(
  children: [
    TextField(
      controller: _nameController,
      decoration: const InputDecoration(labelText: 'Name'),
    ),
    TextField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: 'Email'),
    ),
    TextField(
      controller: _passwordController,
      decoration: const InputDecoration(labelText: 'Password'),
      obscureText: true,
    ),
    ElevatedButton(
  onPressed: _toggleEdit,
  child: Text(_isEditing ? 'Save changes' : 'Edit Profile'),
)
  ],
)

    );
  }
}
