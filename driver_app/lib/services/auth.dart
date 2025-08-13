import 'package:firebase_auth/firebase_auth.dart';
     import 'package:cloud_firestore/cloud_firestore.dart';

     class AuthService {
       final FirebaseAuth _auth = FirebaseAuth.instance;
       final FirebaseFirestore _firestore = FirebaseFirestore.instance;

       // Sign up
       Future<User?> signUp(String email, String password, String name, String role) async {
         try {
           UserCredential result = await _auth.createUserWithEmailAndPassword(
             email: email,
             password: password,
           );
           User? user = result.user;
           if (user != null) {
             await user.sendEmailVerification();
             await _firestore.collection('users').doc(user.uid).set({
               'name': name,
               'email': email,
               'role': role, // 'rider' or 'driver'
               'location': null,
               'religion': '', // For later
               'gender': '', // For later
               'familyIds': [], // For neighboring
             });
             return user;
           }
           return null;
         } catch (e) {
           print('Sign-up error: $e');
           return null;
         }
       }

       // Login
       Future<User?> login(String email, String password) async {
         try {
           UserCredential result = await _auth.signInWithEmailAndPassword(
             email: email,
             password: password,
           );
           if (result.user != null && !result.user!.emailVerified) {
             throw Exception('Please verify your email');
           }
           return result.user;
         } catch (e) {
           print('Login error: $e');
           return null;
         }
       }

       // Sign out
       Future<void> signOut() async {
         await _auth.signOut();
       }
     }