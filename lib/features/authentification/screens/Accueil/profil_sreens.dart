import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forumapp0/features/authentification/screens/Accueil/post_detail_screens.dart';
import '../../fonctions/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  final String prenom;
  final String nom;
  final String email;
  final String niveau;

  const ProfileScreen({
    super.key,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.niveau,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  String? _profilePictureUrl;

  final FirebaseService _firebaseService = FirebaseService();

  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _niveauController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController(text: widget.prenom);
    _nomController = TextEditingController(text: widget.nom);
    _emailController = TextEditingController(text: widget.email);
    _niveauController = TextEditingController(text: widget.niveau);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _loadProfilePicture();
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _niveauController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _loadProfilePicture() async {
    String? url = await _firebaseService.getDownloadUrl(widget.email);
    if (url != null) {
      setState(() {
        _profilePictureUrl = url;
      });
    }
  }

  String getInitials(String prenom, String nom) {
    return prenom.isNotEmpty && nom.isNotEmpty ? '${prenom[0]}${nom[0]}' : '';
  }

  void _changeProfilePicture(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });

      String? imageURL = await _firebaseService.uploadImageToStorage(
          _imageFile!, widget.email);
      if (imageURL != null) {
        setState(() {
          _profilePictureUrl = imageURL;
        });
        String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userId.isNotEmpty) {
          await _firebaseService.updateUserAvatar(_imageFile!, userId);
        }
        _showSelectedImageDialog(context);
      }
    } else {
      print('Aucune image sélectionnée.');
    }
  }

  void _showSelectedImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image sélectionnée'),
          content: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              image: DecorationImage(
                image: NetworkImage(_profilePictureUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      // Reauthenticate the user with the current password before updating the password
      User? user = FirebaseAuth.instance.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(
          email: widget.email, password: _currentPasswordController.text);

      try {
        await user?.reauthenticateWithCredential(credential);
        await _firebaseService.updateUserProfile(
          userId,
          _prenomController.text,
          _nomController.text,
          _emailController.text,
          _niveauController.text,
          _newPasswordController.text,
        );
        _toggleEditMode();
      } catch (e) {
        print("Erreur d'authentification: $e");
        // Afficher un message d'erreur à l'utilisateur
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF2f7dc8),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _saveChanges : _toggleEditMode,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: () => _changeProfilePicture(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profilePictureUrl != null
                            ? NetworkImage(_profilePictureUrl!)
                            : null,
                        child: _profilePictureUrl == null
                            ? Text(
                                getInitials(widget.nom, widget.prenom),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _isEditing
                    ? Column(
                        children: [
                          TextField(
                            controller: _prenomController,
                            decoration: InputDecoration(
                              labelText: 'Prénom',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.grey[200],
                              labelStyle: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: 'Entrez votre prénom',
                            ),
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          TextField(
                            controller: _nomController,
                            decoration: InputDecoration(
                              labelText: 'Nom',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.grey[200],
                              labelStyle: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: 'Entrez votre nom',
                            ),
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          TextField(
                            controller: _currentPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe actuel',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              filled: true,
                              fillColor: Colors.grey[200],
                              labelStyle: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: 'Entrez votre mot de passe actuel',
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          TextField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Nouveau mot de passe',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.grey[200],
                              labelStyle: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: 'Entrez votre nouveau mot de passe',
                            ),
                            obscureText: true,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            '${widget.nom} ${widget.prenom}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.email,
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Niveau: ${widget.niveau}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!_isEditing) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Vos Posts',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: _buildUserPosts(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserPosts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
          child: Text('Vous devez être connecté pour voir vos posts.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Aucun post trouvé pour cet utilisateur.'));
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(
                data['postContent'] ?? '',
                style: TextStyle(fontSize: 18.0),
              ),
              subtitle: Text('Catégorie: ${data['category']}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      postId: document.id,
                      postContent: data['postContent'] ?? '',
                      onUpdatePost: () {},
                      category: data['category'] ?? '',
                      isCommentMode: false,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
