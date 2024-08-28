import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body:SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', 
              height: 100, 
            ),
            const SizedBox(height: 20),
            const Text('Log in'),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {},
              child: const Text('Forget password?'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Log in'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {},
              child: const Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
      );
  }
}