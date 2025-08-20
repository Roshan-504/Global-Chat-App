// chatroom_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatroomController {
  static Future<String?> createChatroom({
    required String name,
    required String description,
  }) async {
    try {
      final db = FirebaseFirestore.instance;
      final userId = FirebaseAuth.instance.currentUser!.uid;

      await db.collection("chatrooms").add({
        "chatroom_name": name,
        "desc": description,
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": userId,
      });

      return null; // Return null on success
    } on FirebaseException catch (e) {
      return "Firebase Error: ${e.message}";
    } catch (e) {
      return "An unexpected error occurred: ${e.toString()}";
    }
  }
}
