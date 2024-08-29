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

    TextField(
      controller: _emailController,
      decoration:  InputDecoration(labelText: 'Email',
       border: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    ),),
      enabled: _isEditing,
    ),
    TextField(
      controller: _passwordController,
      decoration:  InputDecoration(labelText: 'Password', border: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    ),),
      obscureText: true,
      enabled: _isEditing,
    ),
    ElevatedButton(
  onPressed: _toggleEdit,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    padding: const EdgeInsets.symmetric(vertical: 15),
    minimumSize: const Size(double.infinity, 0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text(_isEditing ? 'Save changes' : 'Edit Profile'),
)
  ],
),
    ),

    );

  }
}
