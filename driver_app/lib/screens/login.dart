import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();

  void _login(BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Error: $e'); // Show error in UI later
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
          TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          ElevatedButton(onPressed: () => _login(context), child: Text('Login')),
        ],
      ),
    );
  }
}