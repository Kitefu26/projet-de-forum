import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forumapp0/features/authentification/screens/Accueil/post_detail_screens.dart';
import 'package:forumapp0/features/authentification/screens/Accueil/post_screens.dart';
import 'package:forumapp0/features/authentification/screens/Accueil/profil_sreens.dart';
import 'package:intl/intl.dart';

import '../../fonctions/firebase_service.dart';
import '../../fonctions/post_model.dart';
import '../Bienvenue/welcome_sreen.dart';
import '../image_screen.dart';
import '../notifications/NotificationNewPost.dart';
import 'category_post_screens.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  User? _currentUser;
  String _prenom = '';
  String _nom = '';
  String _niveau = '';
  String? _imageUrl;
  String? _role;

  final List<String> categories = [
    'Programmation',
    'Mathématique',
    'Physique',
    'Chimie',
    'Reseaux',
    'Santé',
    'Environnement',
    'Droit',
    'Comptabilité',
    'Autres'
  ];

  final List<IconData> categoryIcons = [
    Icons.computer,
    Icons.calculate,
    Icons.grid_goldenratio_outlined,
    Icons.bubble_chart,
    Icons.cable,
    Icons.local_hospital,
    Icons.eco,
    Icons.gavel,
    Icons.account_balance,
    Icons.category
  ];

  String _selectedCategory = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, int> _lessonCounts = {};
  final Map<String, Stream<int>> _lessonCountStreams = {};

  @override
  void initState() {
    super.initState();
    _currentUser = _firebaseService.getCurrentUser();
    if (_currentUser != null) {
      _loadUserInfo();
      _loadUserRole();
    }
    _loadLessonCountStreams();
  }

  void _loadLessonCountStreams() {
    for (String category in categories) {
      _lessonCountStreams[category] =
          _firebaseService.getPostCountForCategory(category);

      _lessonCountStreams[category]!.listen((count) {
        setState(() {
          _lessonCounts[category] = count;
        });
      });
    }
  }

  void _loadUserInfo() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _prenom = userDoc['prenom'];
          _nom = userDoc['nom'];
          _niveau = userDoc['niveau'];
          _imageUrl = userDoc['avatarUrl']; // Remplacez photoUrl par avatarUrl
        });
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  String _getInitials() {
    if (_prenom.isNotEmpty && _nom.isNotEmpty) {
      return _prenom[0].toUpperCase() + _nom[0].toUpperCase();
    }
    return 'NN';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedCategory = categories[index];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CategoryPostsScreen(category: _selectedCategory),
        ),
      );
    });
  }

  Future<void> _signOut() async {
    await _firebaseService.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _addNewTopic() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WritePostScreen(
          postCategory: '',
          postTitle: '',
          initialLikes: [],
          initialContent: '',
          postId: '',
          onUpdate: () {},
          postNiveau: '',
        ),
      ),
    );
  }

  void _commentOnPost(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: postId,
          onUpdatePost: () {
            setState(() {});
          },
          postContent: '',
          category: '',
          isCommentMode: null,
        ),
      ),
    );
  }

  void _deletePost(String postId) async {
    try {
      await _firebaseService.deletePost(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post supprimé avec succès !')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la suppression du post : $error')),
      );
    }
  }

  void _editPost(String postId, String newContent, {String? imageUrl}) async {
    try {
      await _firebaseService.editPost(postId, newContent, imageUrl: imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post modifié avec succès !')),
      );
      setState(() {});
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la modification du post : $error')),
      );
    }
  }

  void _showEditDialog(String postId, String currentContent) {
    TextEditingController _contentController = TextEditingController();
    _contentController.text = currentContent;

    String? imageUrl; // Variable pour stocker l'URL de l'image sélectionnée

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Modifier le post...',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                imageUrl = await _firebaseService.pickAndUploadImage(postId);
                setState(() {
                  // Mettre à jour l'avatar ici si imageUrl est non null
                });
              },
              child: const Text('Sélectionner une image'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Enregistrer'),
            onPressed: () {
              String newContent = _contentController.text.trim();
              if (newContent.isNotEmpty) {
                _editPost(postId, newContent, imageUrl: imageUrl);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce post ?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Supprimer'),
            onPressed: () {
              _deletePost(postId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _reportPost(String postId) async {
    try {
      // Get the post document
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      // Get the post author's ID
      String postAuthorId = postDoc['userId'];

      // Get the post author's name and surname
      DocumentSnapshot postAuthorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postAuthorId)
          .get();
      String postAuthorName = postAuthorDoc['prenom'];
      String postAuthorSurname = postAuthorDoc['nom'];

      // Get the reporter's name and surname
      String? reporterUid = _firebaseService.getCurrentUser()?.uid;
      DocumentSnapshot reporterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reporterUid)
          .get();
      String reporterName = reporterDoc['prenom'];
      String reporterSurname = reporterDoc['nom'];

      // Report the post using FirebaseService
      await _firebaseService.reportPost(postId, reporterUid!, postAuthorName,
          postAuthorSurname, reporterName, reporterSurname);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post signalé avec succès !')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec du signalement du post : $error')),
      );
    }
  }

  Widget _buildPostListItem(
      BuildContext context, DocumentSnapshot postSnapshot) {
    final post = postSnapshot.data() as Map<String, dynamic>?;

    if (post != null && post.containsKey('postContent')) {
      bool estPostUtilisateurActuel =
          post['userId'] == _firebaseService.getCurrentUser()?.uid;

      return FutureBuilder<String>(
        future: _firebaseService.getAuthorName(post['userId']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          String nomAuteur = snapshot.data!;
          String initiales = PostModel(
            id: postSnapshot.id,
            content: post['postContent'],
            category: post['category'],
            userId: post['userId'],
            niveau: '',
            avatarUrl: '',
          ).getInitials(nomAuteur.split(' ')[0], nomAuteur.split(' ')[1]);

          return FutureBuilder<String?>(
            future: _firebaseService.getDownloadUrl(post['userId']),
            builder: (context, photoSnapshot) {
              return StreamBuilder<int>(
                stream: _firebaseService.getCommentCountStream(postSnapshot.id),
                builder: (context, commentCountSnapshot) {
                  int commentCount = commentCountSnapshot.data ?? 0;

                  return FutureBuilder<String?>(
                    future: _firebaseService.getUserNiveau(post['userId']),
                    builder: (context, niveauSnapshot) {
                      if (!niveauSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      String niveau = niveauSnapshot.data ?? "Niveau inconnu";

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 5.0,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: post['avatarUrl'] != null
                                        ? NetworkImage(post['avatarUrl'])
                                        : null,
                                    child: post['avatarUrl'] == null
                                        ? Text(
                                            initiales,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nomAuteur,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'niveau: $niveau',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (estPostUtilisateurActuel) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color(0xFF2f7dc8),
                                      ),
                                      onPressed: () {
                                        _showEditDialog(postSnapshot.id,
                                            post['postContent']);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(
                                            postSnapshot.id);
                                      },
                                    ),
                                  ],
                                  if (!estPostUtilisateurActuel)
                                    IconButton(
                                      icon: const Icon(Icons.report,
                                          color: Colors.orange),
                                      onPressed: () {
                                        _reportPost(postSnapshot.id);
                                      },
                                    ),
                                  Stack(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.comment,
                                            color: Colors.green),
                                        onPressed: () {
                                          _commentOnPost(postSnapshot.id);
                                        },
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Colors.red,
                                          child: Text(
                                            commentCount.toString(),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20.0),
                              Text(
                                post['postContent'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (post['fileUrl'] != null &&
                                  post['fileUrl'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageScreen(
                                            imageUrl: post['fileUrl'],
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: const Color(0xFF2f7dc8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: Text(
                                      'Voir ${_isImageUrl(post['fileUrl']) ? "l\'image" : "le fichier"}',
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10.0),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  'Categorie:'
                                  '  ${post['category']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2f7dc8),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
                    },
                  );
                },
              );
            },
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Stream<QuerySnapshot> getFilteredPostsStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance.collection('posts').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('posts')
          .where('keywords', arrayContains: query.toLowerCase())
          .snapshots();
    }
  }

  bool _isImageUrl(String url) {
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif');
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            _role = snapshot.data()?['role'];
          });
        } else {
          print("Utilisateur non trouvé");
        }
      } else {
        print("Utilisateur non authentifié");
      }
    } catch (e) {
      print("Erreur lors du chargement du rôle de l'utilisateur: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        backgroundColor: const Color(0xFF2f7dc8), // Couleur bleue hexadécimale
        actions: [
          StreamBuilder<int>(
            stream: _firebaseService.getUnreadNotificationsCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                int unreadCount = snapshot.data!;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NotificationPage()),
                        );
                      },
                    ),
                    if (unreadCount >= 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationPage()),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('$_prenom $_nom'),
              accountEmail: Text(_currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blue,
                backgroundImage:
                    _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                child: _imageUrl == null
                    ? Text(
                        _getInitials(),
                        style: const TextStyle(
                          fontSize: 24.0,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            if (_role == 'Moderateur') // Ajout de la condition pour le rôle
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('Retour'),
                onTap: () {
                  Navigator.pop(context); // Fermer le Drawer
                  Navigator.pop(context); // Retourner à la page précédente
                },
              ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Accueil'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      prenom: _prenom,
                      nom: _nom,
                      email: _currentUser?.email ?? '',
                      niveau: _niveau,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Déconnexion'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Catégories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  height: 100.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _onItemTapped(index),
                        child: Container(
                          width: 100.0,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white38,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                categoryIcons[index],
                                size: 40,
                                color: const Color(0xFF2f7dc8),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                categories[index],
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2f7dc8),
                                ),
                              ),
                              Text(
                                '[${_lessonCounts[categories[index]] ?? 0}]',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2f7dc8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Posts récents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getRecentPostsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var posts = snapshot.data!.docs;
                if (posts.isEmpty) {
                  return const Center(
                    child: Text('Aucun post disponible.'),
                  );
                }

                // Filter posts based on search query
                var filteredPosts = posts.where((post) {
                  final postData = post.data() as Map<String, dynamic>;
                  final postContent = postData['postContent'] as String;
                  return postContent.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    return _buildPostListItem(context, filteredPosts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTopic,
        backgroundColor: const Color(0xFF2f7dc8),
        child: const Icon(Icons
            .add), // Assurez-vous que le FAB correspond à la couleur de l'AppBar
      ),
    );
  }
}
