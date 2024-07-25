import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      print('Attempting to send password reset email to: $email');

      try {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        final QuerySnapshot users = await firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (users.docs.isNotEmpty) {
          try {
            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'E-mail de réinitialisation de mot de passe envoyé')),
            );
          } on FirebaseAuthException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Erreur lors de l\'envoi de l\'e-mail de réinitialisation de mot de passe : ${e.message}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adresse e-mail inconnue')),
          );
        }
      } catch (e) {
        print('Erreur lors de la récupération des utilisateurs : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Une erreur s\'est produite. Veuillez réessayer.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réinitialiser le mot de passe'),
        backgroundColor: const Color(0xFF2f7dc8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Text(
                'Récupération du mot de passe',
                style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600]),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 30.0),
              const Text(
                'Saisissez votre adresse e-mail',
                style: TextStyle(
                  fontSize: 18.0,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 30.0),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF2f7dc8)),
                      onPressed: _sendPasswordResetEmail,
                      child: const Text('Envoyer'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
