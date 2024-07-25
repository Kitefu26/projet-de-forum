import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../fonctions/firebase_service.dart';

class PostsScreen extends StatefulWidget {
  @override
  _PostsScreenState createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<DocumentSnapshot> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts(); // Charger les posts au démarrage
  }

  Future<void> _loadPosts() async {
    try {
      QuerySnapshot snapshot = await _firebaseService.getAllPosts();
      print('Posts récupérés : ${snapshot.docs.length}'); // Pour déboguer
      setState(() {
        _posts = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des posts: $e")),
      );
      print('Erreur lors du chargement des posts : $e'); // Pour déboguer
    }
  }

  Future<void> _confirmDeletePost(String postId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // Empêche de fermer la boîte de dialogue en dehors de celle-ci
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce post ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(false), // Ferme la boîte de dialogue sans supprimer
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                  true), // Ferme la boîte de dialogue et confirme la suppression
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deletePost(postId);
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await _firebaseService.deletePost(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post supprimé avec succès.')),
      );
      _loadPosts(); // Recharger les posts après la suppression
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression du post : $e')),
      );
      print('Erreur lors de la suppression du post : $e'); // Pour déboguer
    }
  }

  Future<Map<String, String>> _getAuthorInfo(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String prenom = data['prenom'] ?? 'Inconnu';
        String nom = data['nom'] ?? 'Inconnu';
        return {'prenom': prenom, 'nom': nom};
      } else {
        return {'prenom': 'Inconnu', 'nom': 'Inconnu'};
      }
    } catch (e) {
      print("Erreur lors de la récupération des informations de l'auteur: $e");
      return {'prenom': 'Inconnu', 'nom': 'Inconnu'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tous les posts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _posts.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final postData = post.data() as Map<String, dynamic>;
                  String postId = post.id;
                  String userId = postData['userId'] ?? '';

                  return FutureBuilder<Map<String, String>>(
                    future: _getAuthorInfo(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Card(
                          elevation: 5.0,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return Card(
                          elevation: 5.0,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                                'Erreur lors de la récupération des informations de l\'auteur'),
                          ),
                        );
                      }

                      final authorInfo = snapshot.data!;
                      String prenom = authorInfo['prenom'] ?? 'Inconnu';
                      String nom = authorInfo['nom'] ?? 'Inconnu';
                      String postContent =
                          postData['postContent'] ?? 'Aucun contenu';

                      return Card(
                        elevation: 5.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$prenom $nom',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                postContent,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDeletePost(postId),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
