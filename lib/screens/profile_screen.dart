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
  title: const Text(
    'Profile',
    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
  ),
  centerTitle: true,
),
      body:Padding(
  padding: const EdgeInsets.all(20.0),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      const CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage('https://via.placeholder.com/150'),
      ),
      const SizedBox(height: 30),
      TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: 'Name'),
        enabled: _isEditing,
      ),
    TextField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: 'Email'),
      enabled: _isEditing,
    ),
    TextField(
      controller: _passwordController,
      decoration: const InputDecoration(labelText: 'Password'),
      obscureText: true,
      enabled: _isEditing,
    ),
    ElevatedButton(
  onPressed: _toggleEdit,
  child: Text(_isEditing ? 'Save changes' : 'Edit Profile'),
)
  ],
),
    ),

    );

  }
}
