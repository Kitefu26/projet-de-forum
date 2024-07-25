import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../fonctions/firebase_service.dart';
import 'home_screens.dart';

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({
    Key? key,
    required this.postCategory,
    required this.postTitle,
    required this.initialLikes,
    required this.initialContent,
    required this.postId,
    required this.onUpdate,
    required this.postNiveau,
  }) : super(key: key);

  final String postCategory;
  final String postNiveau;
  final String postTitle;
  final List initialLikes;
  final String initialContent;
  final String postId;
  final Null Function() onUpdate;

  @override
  _WritePostScreenState createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final TextEditingController _postTextController = TextEditingController();
  final TextEditingController _postTitleController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;
  File? _selectedFile;
  final FirebaseService _firebaseService = FirebaseService();

  final List<String> categories = [
    'Programmation',
    'Mathématique',
    'Droit',
    'Environnement',
    'Comptabilité',
    'Physique',
    'Chimie',
    'Réseaux',
    'Santé',
    'Autres',
  ];

  @override
  void dispose() {
    _postTextController.dispose();
    _postTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      if (!(await _requestGalleryPermission())) {
        // Si la permission d'accès à la galerie est refusée, ne rien faire
        return;
      }

      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Erreur lors du choix du fichier : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du choix du fichier : $e'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<bool> _requestGalleryPermission() async {
    // Vérifier si la permission d'accès à la galerie est déjà accordée
    if (await Permission.storage.request().isGranted) {
      return true; // La permission est déjà accordée
    }

    // Demander la permission d'accès à la galerie
    var status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _submitPost() async {
    if (_selectedCategory != null && _postTextController.text.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Récupérer l'URL de l'avatar de l'utilisateur
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          String avatarUrl = userDoc['avatarUrl'];

          String? fileUrl;
          if (_selectedFile != null) {
            fileUrl = await _uploadFileToStorage(_selectedFile!);
            if (fileUrl == null) {
              throw Exception('Erreur lors du téléchargement du fichier.');
            }
          }

          // Ajout du post à la collection 'posts'
          DocumentReference postRef =
              await FirebaseFirestore.instance.collection('posts').add({
            'userId': user.uid,
            'category': _selectedCategory,
            'postTitle': _postTitleController.text,
            'postContent': _postTextController.text,
            'timestamp': Timestamp.now(),
            'fileUrl': fileUrl, // URL du fichier ajouté (si disponible)
            'avatarUrl': avatarUrl, // URL de l'avatar de l'utilisateur
          });

          // Send notification to all users
          await _firebaseService.sendNotificationToAllUsers(postRef.id);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post ajouté avec succès !'),
              duration: Duration(seconds: 5),
            ),
          );

          // Réinitialisation du formulaire
          _postTextController.clear();
          setState(() {
            _selectedCategory = null;
            _selectedFile = null;
            _isSubmitting = false;
          });

          // Redirection vers la page HomeScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );

          widget.onUpdate();
        } catch (e) {
          print('Erreur lors de la soumission du post : $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la soumission du post : $e'),
              duration: const Duration(seconds: 5),
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez remplir tous les champs et sélectionner une catégorie.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<String?> _uploadFileToStorage(File file) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child("files/$fileName");
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String fileUrl = await taskSnapshot.ref.getDownloadURL();
      return fileUrl;
    } catch (e) {
      print('Erreur lors du téléchargement du fichier : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement du fichier : $e'),
          duration: Duration(seconds: 5),
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Écrire un nouveau sujet'),
        backgroundColor: const Color(0xFF2f7dc8),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Sélectionnez une catégorie'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                items:
                    categories.map<DropdownMenuItem<String>>((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 12.0,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _postTextController,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Sujet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 12.0,
                  ),
                  hintText: 'Écrivez votre sujet ici...',
                ),
              ),
              const SizedBox(height: 20.0),
              if (_selectedFile != null) // Afficher l'image sélectionnée
                Column(
                  children: [
                    Image.file(_selectedFile!),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ElevatedButton(
                onPressed: _pickFile,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 10.0),
                    Text(
                      'Téléverser un fichier',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF2f7dc8),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Soumettre',
                        style: TextStyle(fontSize: 16.0),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
