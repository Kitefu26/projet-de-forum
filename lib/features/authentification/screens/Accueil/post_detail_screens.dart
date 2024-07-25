import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../fonctions/firebase_service.dart';
import '../../fonctions/post_model.dart';

class CommentModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String prenom;
  final String nom;
  final DateTime timestamp;
  final String avatarUrl;

  CommentModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.prenom,
    required this.nom,
    required this.timestamp,
    required this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'prenom': prenom,
      'nom': nom,
      'timestamp': timestamp,
      'avatarUrl': avatarUrl,
    };
  }
}

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required String postContent,
    required Null Function() onUpdatePost,
    required String category,
    required isCommentMode,
  });

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  User? _currentUser;
  String _currentUserPrenom = '';
  String _currentUserNom = '';
  String _prenom = '';
  String _nom = '';
  String _niveau = '';
  late PostModel _post;

  @override
  void initState() {
    super.initState();
    _currentUser = _firebaseService.getCurrentUser();
    _loadUserInfo();
    // Initialize _post here
    _post = PostModel(
      id: '', // Provide a placeholder value if necessary
      content: '', // Provide a placeholder value if necessary
      category: '', // Provide a placeholder value if necessary
      userId: '', // Provide a placeholder value if necessary
      niveau: '',
      avatarUrl: '', // Provide a placeholder value if necessary
    );
    _loadPostDetails();
  }

  Future<void> _loadUserInfo() async {
    try {
      DocumentSnapshot userDoc =
          await _firebaseService.getUserDocument(_currentUser!.uid);
      if (userDoc.exists) {
        setState(() {
          _currentUserPrenom = userDoc['prenom'] ?? '';
          _currentUserNom = userDoc['nom'] ?? '';
          _niveau = userDoc['niveau'] ?? '';
        });
      }
    } catch (e) {
      print(
          "Erreur lors de la récupération des informations de l'utilisateur: $e");
    }
  }

  Future<void> _loadPostDetails() async {
    try {
      DocumentSnapshot postDoc =
          await _firebaseService.getPostDetails(widget.postId);
      if (postDoc.exists) {
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        _post = PostModel(
          id: postDoc.id,
          content: postData['postContent'] ?? '',
          category: postData['category'] ?? '',
          userId: postData['userId'] ?? '',
          niveau: postData['niveau'] ?? '',
          avatarUrl: postData['avatarUrl'] ?? '',
        );

        DocumentSnapshot userDoc =
            await _firebaseService.getUserDocument(_post.userId);
        if (userDoc.exists) {
          setState(() {
            _prenom = userDoc['prenom'] ?? '';
            _nom = userDoc['nom'] ?? '';
            _niveau = userDoc['niveau'] ?? '';
// Fetch avatarUrl here
          });
        }

        setState(() {});
      }
    } catch (e) {
      print("Erreur lors de la récupération des détails du post: $e");
    }
  }

  void _confirmDeleteComment(CommentModel comment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Voulez-vous vraiment supprimer ce commentaire?'),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteComment(comment);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditCommentDialog(CommentModel comment) {
    final _editController = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier le commentaire'),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(
              hintText: 'Modifier votre commentaire...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Enregistrer'),
              onPressed: () async {
                if (_editController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateComment(comment, _editController.text);
                } else {
                  print('Commentaire vide');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: comment.avatarUrl.isNotEmpty
                  ? Container(
                      width: 40, // or any other size you want
                      height: 40, // or any other size you want
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Image.network(
                        comment.avatarUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      comment.prenom[0] + comment.nom[0],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${comment.prenom} ${comment.nom}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    comment.content,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Publié le ${DateFormat('dd-MM-yyyy à HH:mm').format(comment.timestamp)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            _currentUser!.uid == comment.authorId
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF2f7dc8),
                        ),
                        onPressed: () {
                          _editComment(comment);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDeleteComment(comment);
                        },
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.report, color: Colors.orange),
                    onPressed: () {
                      _confirmReportComment(comment);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateComment(CommentModel comment, String newContent) async {
    try {
      await _firebaseService.updateComment(
        widget.postId,
        comment.id,
        {'content': newContent}, // No need for the cast
      );
      print('Commentaire mis à jour avec succès');
      setState(() {}); // Refresh UI
    } catch (e) {
      print('Erreur lors de la mise à jour du commentaire: $e');
    }
  }

  void _confirmReportComment(CommentModel comment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Signaler le commentaire'),
          content: const Text('Voulez-vous vraiment signaler ce commentaire?'),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Signaler'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _reportComment(comment);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _reportComment(CommentModel comment) async {
    try {
      // Fetch user details from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Adjust the collection name if needed
          .doc(_currentUser!.uid) // Get the current user document
          .get();

      // Extract user details
      String reporterName =
          userDoc['prenom'] ?? 'Inconnu'; // Adjust the field name if needed
      String reporterSurname =
          userDoc['nom'] ?? 'Inconnu'; // Adjust the field name if needed

      // Call the reportComment function
      await _firebaseService.reportComment(
        widget.postId,
        comment.id,
        _currentUser!.uid,
        reporterName,
        reporterSurname,
      );

      print('Commentaire signalé avec succès');
    } catch (e) {
      print('Erreur lors du signalement du commentaire: $e');
    }
  }

  void _editComment(CommentModel comment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _controller =
            TextEditingController(text: comment.content);
        return AlertDialog(
          title: const Text('Modifier le commentaire'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Modifier votre commentaire...',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Enregistrer'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateComment(comment, _controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(CommentModel comment) async {
    try {
      await _firebaseService.deleteComment(widget.postId, comment.id);
      print('Commentaire supprimé avec succès');
      setState(() {});
    } catch (e) {
      print('Erreur lors de la suppression du commentaire: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du Post'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: _post.avatarUrl != ''
                    ? Container(
                        width: 40, // or any other size you want
                        height: 40, // or any other size you want
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Image(
                          image: NetworkImage(_post.avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        _post.getInitials(_prenom, _nom),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_prenom $_nom',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _niveau,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _post.content,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Catégorie: ${_post.category}',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Commentaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getCommentsStream(widget.postId),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Aucun commentaire pour ce post.'),
                );
              }

              List<CommentModel> comments = snapshot.data!.docs.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return CommentModel(
                  id: doc.id,
                  content: data['content'] ?? '',
                  authorId: data['authorId'] ?? '',
                  authorName: data['authorName'] ?? '',
                  prenom: data['prenom'] ?? '',
                  nom: data['nom'] ?? '',
                  timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
                  avatarUrl: data['avatarUrl'] ?? '',
                );
              }).toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return _buildCommentItem(comments[index]);
                },
              );
            },
          ),
          CommentForm(
            postId: widget.postId,
            prenom: _currentUserPrenom,
            nom: _currentUserNom,
            authorId: _currentUser!.uid,
          ),
        ],
      ),
    );
  }
}

class CommentForm extends StatefulWidget {
  final String postId;
  final String prenom;
  final String nom;
  final String authorId;

  const CommentForm({
    super.key,
    required this.postId,
    required this.prenom,
    required this.nom,
    required this.authorId,
  });

  @override
  _CommentFormState createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final _controller = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchAvatarUrl();
  }

  Future<void> _fetchAvatarUrl() async {
    try {
      DocumentSnapshot userDoc =
          await _firebaseService.getUserDocument(widget.authorId);
      if (userDoc.exists) {
        setState(() {
          _avatarUrl = userDoc['avatarUrl'] ?? '';
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'avatarUrl: $e');
    }
  }

  Future<void> _submitComment() async {
    if (_controller.text.isNotEmpty) {
      try {
        DocumentSnapshot userDoc =
            await _firebaseService.getUserDocument(widget.authorId);
        if (userDoc.exists) {
          String avatarUrl = userDoc['avatarUrl'] ?? '';

          CommentModel newComment = CommentModel(
            id: '',
            content: _controller.text,
            authorId: widget.authorId,
            authorName: '${widget.prenom} ${widget.nom}',
            prenom: widget.prenom,
            nom: widget.nom,
            timestamp: DateTime.now(),
            avatarUrl: avatarUrl,
          );

          await _firebaseService.addComment(widget.postId, newComment.toMap());
          _controller.clear();
        }
      } catch (e) {
        print('Erreur lors de la soumission du commentaire: $e');
      }
    } else {
      print('Commentaire vide');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Écrire un commentaire...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.send,
              color: Color(0xFF2f7dc8),
            ),
            onPressed: _submitComment,
          ),
        ],
      ),
    );
  }
}
