import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:globalchat/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomName;
  final String chatRoomId;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomName,
    required this.chatRoomId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) {
      return; // Do not send empty messages
    }
    final String messageText = messageController.text.trim();
    messageController.clear();

    final messageData = {
      "text": messageText,
      "sender_name": Provider.of<UserProvider>(context, listen: false).userName,
      "sender_id": FirebaseAuth.instance.currentUser!.uid,
      "timestamp": FieldValue.serverTimestamp(),
      "chatroom_id": widget.chatRoomId,
    };

    try {
      await db.collection("messages").add(messageData);
      // Auto-scroll to the bottom when a new message is sent
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Animate to the top of the reversed list (which is the last item)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chatRoomName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF008080),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection("messages")
                  .where("chatroom_id", isEqualTo: widget.chatRoomId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF008080)),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading messages."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final bool isMe =
                        messageData['sender_id'] ==
                        FirebaseAuth.instance.currentUser!.uid;

                    return MessageBubble(
                      text: messageData['text'] ?? '',
                      sender: messageData['sender_name'] ?? 'Unknown',
                      isMe: isMe,
                      timestamp: messageData['timestamp'],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF008080),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// A custom widget for the message bubbles
class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  final dynamic timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    required this.sender,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    // Determine timestamp string
    String timeString = '';
    if (timestamp != null) {
      final dateTime = (timestamp as Timestamp).toDate();
      timeString = DateFormat('h:mm a').format(dateTime);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            isMe ? "You" : sender,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.black54 : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Material(
            elevation: 5.0,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15.0),
              topRight: const Radius.circular(15.0),
              bottomLeft: isMe
                  ? const Radius.circular(15.0)
                  : const Radius.circular(0),
              bottomRight: isMe
                  ? const Radius.circular(0)
                  : const Radius.circular(15.0),
            ),
            color: isMe ? const Color(0xFF008080) : Colors.grey.shade200,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 15.0,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          if (timeString.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                timeString,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ),
        ],
      ),
    );
  }
}
