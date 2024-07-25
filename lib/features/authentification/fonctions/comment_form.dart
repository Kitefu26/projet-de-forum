import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CommentForm extends StatefulWidget {
  final String postId;
  final String prenom;
  final String nom;
  final String authorId;

  CommentForm({
    required this.postId,
    required this.prenom,
    required this.nom,
    required this.authorId,
  });

  @override
  _CommentFormState createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'content': _commentController.text,
        'authorId': widget.authorId,
        'prenom': widget.prenom,
        'nom': widget.nom,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    } catch (e) {
      print("Erreur lors de l'ajout du commentaire: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: 'Ajouter un commentaire',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          _isSubmitting
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submitComment,
                  child: Text('Soumettre'),
                ),
        ],
      ),
    );
  }
}
