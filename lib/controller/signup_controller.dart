// signup_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:globalchat/screens/splash_screen.dart';

class SignupController {
  // Method to create a new user account with Firebase Auth and Firestore
  static Future<String?> createAccount({
    required String name,
    required String country,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create user with email and password
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Get the user ID
      final userId = userCredential.user!.uid;

      // 3. Store user details in Firestore
      final db = FirebaseFirestore.instance;
      await db.collection("users").doc(userId).set({
        "name": name,
        "country": country,
        "email": email,
        "id": userId,
        "createdAt": Timestamp.now(), // Add a timestamp for future features
      });

      return null; // Return null on success
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = e.message ?? 'An unknown authentication error occurred.';
      }
      return message; // Return the user-friendly error message
    } catch (e) {
      // Handle other potential errors
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }
}
