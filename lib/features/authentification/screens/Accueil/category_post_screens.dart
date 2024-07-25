import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CategoryPostsScreen extends StatefulWidget {
  final String category;

  CategoryPostsScreen({required this.category});

  @override
  _CategoryPostsScreenState createState() => _CategoryPostsScreenState();
}

class _CategoryPostsScreenState extends State<CategoryPostsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts - ${widget.category}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('posts')
            .where('category', isEqualTo: widget.category)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _buildPostListItem(context, posts[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostListItem(
      BuildContext context, DocumentSnapshot postSnapshot) {
    final post = postSnapshot.data() as Map<String, dynamic>;
    final authorId = post['userId'];
    final avatarUrl = post['avatarUrl'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(authorId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final nom = userData['nom'];
                final prenom = userData['prenom'];
                final initials = _getInitials(nom, prenom);

                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: avatarUrl != null
                          ? Container(
                              width: 40, // or any other size you want
                              height: 40, // or any other size you want
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(shape: BoxShape.circle),
                              child: Image(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              initials,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$nom $prenom',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              post['postContent'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Publié le ${DateFormat('dd-MM-yyyy à HH:mm').format(post['timestamp'].toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String nom, String prenom) {
    return '${nom[0].toUpperCase()}${prenom[0].toUpperCase()}';
  }
}
