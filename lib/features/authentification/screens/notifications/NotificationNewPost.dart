import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../Accueil/post_detail_screens.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _unreadNotifications = [];
  List<QueryDocumentSnapshot> _readNotifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        print('Erreur: Utilisateur non connecté');
        return;
      }

      QuerySnapshot notificationsSnapshot = await _firestore
          .collection('notificationPosts')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _unreadNotifications = notificationsSnapshot.docs
            .where((doc) => doc['read'] == false)
            .toList();
        _readNotifications = notificationsSnapshot.docs
            .where((doc) => doc['read'] == true)
            .toList();
      });

      if (_unreadNotifications.isEmpty && _readNotifications.isEmpty) {
        print('Aucune notification trouvée pour l\'utilisateur $currentUserId');
      }
    } catch (e) {
      print('Erreur lors de la récupération des notifications: $e');
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd-MM-yyyy à HH:mm').format(dateTime);
  }

  Widget _buildNotificationTile(
      QueryDocumentSnapshot notification, bool isUnread) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        title: Text(
          '${notification['userName']} \nCatégorie: ${notification['category']}',
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.bold,
            color: isUnread ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          notification['postContent'],
          style: TextStyle(
            fontSize: 17,
            color: isUnread ? Colors.black : Colors.grey,
          ),
        ),
        trailing: Text(
          _formatTimestamp(notification['timestamp']),
          style: TextStyle(
            color: isUnread ? Colors.black : Colors.grey,
          ),
        ),
        onTap: () {
          if (isUnread) {
            _firestore
                .collection('notificationPosts')
                .doc(notification.id)
                .update({'read': true});
            _fetchNotifications(); // Update the notifications list
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                postId: notification['postId'],
                postContent: notification['postContent'],
                onUpdatePost: () {},
                category: notification['category'],
                isCommentMode: false,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _unreadNotifications.isEmpty && _readNotifications.isEmpty
          ? const Center(
              child: Text('Aucune notification'),
            )
          : ListView(
              children: [
                if (_unreadNotifications.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        'Non lus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  ..._unreadNotifications
                      .map((notification) =>
                          _buildNotificationTile(notification, true))
                      .toList(),
                  const Divider(),
                ],
                if (_readNotifications.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        'Lus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  ..._readNotifications.map((notification) =>
                      _buildNotificationTile(notification, false)),
                ],
              ],
            ),
    );
  }
}
