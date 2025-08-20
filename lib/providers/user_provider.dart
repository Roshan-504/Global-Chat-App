import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String userName = '';
  String userCountry = '';
  String userEmail = '';
  bool isLoading = false;
  String? errorMessage;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // A method to reset the user data
  void resetUserData() {
    userName = '';
    userCountry = '';
    userEmail = '';
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  // A more robust way to get user details from Firestore
  Future<void> getUserDetails() async {
    // Check for a logged-in user
    final user = _auth.currentUser;
    if (user == null) {
      resetUserData();
      return;
    }

    // Set loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Fetch user data from Firestore using async/await
      final docSnapshot = await _db.collection("users").doc(user.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        userName = data?['name'] ?? '';
        userCountry = data?['country'] ?? '';
        userEmail = data?['email'] ?? '';
        errorMessage = null; // Clear any previous errors
      } else {
        errorMessage = "User data not found.";
      }
    } on FirebaseException catch (e) {
      errorMessage = "Failed to fetch user data: ${e.message}";
    } catch (e) {
      errorMessage = "An unexpected error occurred.";
    } finally {
      isLoading = false; // Always stop the loading state
      notifyListeners();
    }
  }
}
