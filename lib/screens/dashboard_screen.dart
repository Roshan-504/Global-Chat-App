// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globalchat/providers/user_provider.dart';
import 'package:globalchat/screens/chatroom_screen.dart';
import 'package:globalchat/screens/profile_screen.dart';
import 'package:globalchat/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:globalchat/screens/create_chatroom_screen.dart'; // Import the new screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var user = FirebaseAuth.instance.currentUser;
  final db = FirebaseFirestore.instance;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> chatRoomsList = [];
  List<String> chatRoomsIds = [];
  bool isLoading = true;
  String? errorMessage;

  void getChatRooms() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final querySnapshot = await db.collection("chatrooms").get();
      chatRoomsList = querySnapshot.docs.map((doc) => doc.data()).toList();
      chatRoomsIds = querySnapshot.docs.map((doc) => doc.id.toString()).toList();
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = "Failed to fetch chat rooms: $error";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${errorMessage ?? 'An error occurred'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    getChatRooms();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text(
          "Global Chat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF008080),
        elevation: 4,
        leading: Builder(
          builder: (context) {
            final userName = userProvider.userName;
            final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : '';
            return IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  userInitial,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                userProvider.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(userProvider.userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userProvider.userName.isNotEmpty ? userProvider.userName[0].toUpperCase() : '',
                  style: const TextStyle(
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF008080),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black54),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black54),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SplashScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008080)))
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : ListView.builder(
                  itemCount: chatRoomsList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final chatRoomName = chatRoomsList[index]['chatroom_name'] ?? "Chat Room";
                    final chatRoomDesc = chatRoomsList[index]['desc'] ?? "";
                    final chatRoomId = chatRoomsIds[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return ChatRoomScreen(
                                  chatRoomName: chatRoomName,
                                  chatRoomId: chatRoomId,
                                );
                              },
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF008080),
                          child: Text(
                            chatRoomName.isNotEmpty ? chatRoomName.substring(0, 1).toUpperCase() : '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          chatRoomName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          chatRoomDesc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateChatroomScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF008080),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}