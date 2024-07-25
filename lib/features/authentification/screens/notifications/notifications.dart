import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: Column(
          children: [
            // TabBar displayed below the AppBar with enhanced styling
            Container(
              color: Colors.blueGrey[50],
              child: const TabBar(
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blueAccent,
                tabs: [
                  Tab(text: 'Posts Reportés'),
                  Tab(text: 'Commentaires Reportés'),
                ],
              ),
            ),
            Expanded(
              child: const TabBarView(
                children: [
                  NotificationList(type: 'reportPosts'),
                  NotificationList(type: 'reports'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationList extends StatelessWidget {
  final String type;

  const NotificationList({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(type)
          .orderBy('reportedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Aucune notification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
          );
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Erreur: ${snapshot.error}',
                  style: TextStyle(color: Colors.red)));
        }

        List<NotificationItem> notifications = snapshot.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return NotificationItem(
            id: doc.id,
            type: type,
            postId: data['postId'] ?? 'Aucun',
            commentId: data['commentId'] ?? 'Aucun',
            authorName: data['authorName'] ?? 'Aucun',
            authorSurname: data['authorSurname'] ?? 'Aucun',
            content: data['postContent'] ?? 'Aucun',
            userId: data['reportedBy'] ?? 'Inconnu',
            userName: data['reporterName'] ?? 'Inconnu',
            userSurname: data['reporterSurname'] ?? 'Inconnu',
            timestamp: (data['reportedAt']?.toDate() ?? DateTime.now()),
            read: data['read'] ?? false,
          );
        }).toList();

        // Sort notifications by timestamp in descending order
        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            String title;
            if (notification.type == 'reportPosts') {
              title =
                  '${notification.userName} ${notification.userSurname} a signalé un sujet';
            } else {
              title =
                  '${notification.userName} ${notification.userSurname} a signalé le commentaire de ${notification.authorName} ${notification.authorSurname}';
            }

            return Card(
              elevation: 4.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Contenu: ${notification.content}',
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  notification.read
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: notification.read ? Colors.green : Colors.grey,
                ),
                onTap: () {
                  // Mark notification as read
                  FirebaseFirestore.instance
                      .collection(notification.type)
                      .doc(notification.id)
                      .update({'read': true});

                  // Display more details if needed
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationDetailScreen(
                        notification: notification,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class NotificationItem {
  final String id;
  final String type;
  final String postId;
  final String commentId;
  final String authorName;
  final String authorSurname;
  final String content;
  final String userId;
  final String userName;
  final String userSurname;
  final DateTime timestamp;
  final bool read;

  NotificationItem({
    required this.id,
    required this.type,
    required this.postId,
    required this.commentId,
    required this.userId,
    required this.userName,
    required this.userSurname,
    required this.timestamp,
    required this.read,
    required this.authorName,
    required this.authorSurname,
    required this.content,
  });
}

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  NotificationDetailScreen({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Détails'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signalé par: ${notification.userName} ${notification.userSurname}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Est signalé: ${notification.authorName} ${notification.authorSurname}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      color: Colors.yellow[200], // Couleur de surlignage
                      child: const Text(
                        'Contenu:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      notification.content, // Utiliser le contenu du post
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Signalé le: ${notification.timestamp}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePost(notification.postId, context);
              },
              child: const Text('Supprimer le Post'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePost(String postId, BuildContext context) async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();

      if (postSnapshot.exists) {
        await postRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post supprimé avec succès')),
        );
        Navigator.pop(context); // Revenir à l'écran précédent
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Le post n\'existe pas ou a déjà été supprimé')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression du post: $e')),
      );
    }
  }
}
