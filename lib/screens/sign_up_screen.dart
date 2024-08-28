import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sign up'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
  Image.asset(
    'assets/images/logo.png',
    height: 150,
  ),
  const SizedBox(height: 20),
  const Text(
    'Create Account',
    style: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
   const SizedBox(height: 20),
  const TextField(
    decoration: InputDecoration(
      labelText: 'Email',
      prefixIcon: Icon(Icons.email),
      border: OutlineInputBorder(),
    ),
  ),
],

        ),
      ),
    );
  }
}
