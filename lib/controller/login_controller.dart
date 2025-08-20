// login_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController {
  // Method to log in a user with Firebase Auth
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate user with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null; // Return null on success
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password. Please try again.';
      } else {
        message = e.message ?? 'An unknown authentication error occurred.';
      }
      return message; // Return the user-friendly error message
    } catch (e) {
      // Handle any other errors
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }
}
