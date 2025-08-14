import 'package:flutter/material.dart';
import 'package:rider_app/services/auth.dart';


     class SignupScreen extends StatelessWidget {
       final AuthService _auth = AuthService();
       final _emailController = TextEditingController();
       final _passwordController = TextEditingController();
       final _nameController = TextEditingController();

       void _signup(BuildContext context) async {
         try {
           final user = await _auth.signUp(
             _emailController.text,
             _passwordController.text,
             _nameController.text,
             ModalRoute.of(context)!.settings.name!.contains('driver') ? 'driver' : 'rider',
           );
           if (user != null) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verify your email')));
             Navigator.pushReplacementNamed(context, '/login');
           } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed')));
           }
         } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
         }
       }

       @override
       Widget build(BuildContext context) {
         return Scaffold(
           appBar: AppBar(title: Text('Sign Up')),
           body: Padding(
             padding: EdgeInsets.all(16.0),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 TextField(
                   controller: _nameController,
                   decoration: InputDecoration(labelText: 'Name'),
                 ),
                 TextField(
                   controller: _emailController,
                   decoration: InputDecoration(labelText: 'Email'),
                 ),
                 TextField(
                   controller: _passwordController,
                   decoration: InputDecoration(labelText: 'Password'),
                   obscureText: true,
                 ),
                 SizedBox(height: 20),
                 ElevatedButton(
                   onPressed: () => _signup(context),
                   child: Text('Sign Up'),
                 ),
                 TextButton(
                   onPressed: () => Navigator.pushNamed(context, '/login'),
                   child: Text('Already have an account? Log in'),
                 ),
               ],
             ),
           ),
         );
       }
     }