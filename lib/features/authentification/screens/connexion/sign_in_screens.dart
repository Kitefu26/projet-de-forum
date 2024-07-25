import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forumapp0/features/authentification/screens/Bienvenue/welcome_sreen.dart';
import 'package:forumapp0/features/authentification/screens/connexion/reset_password.dart';
import '../../fonctions/firebase_service.dart';
import '../Accueil/home_screens.dart'; // Importez la page d'accueil
import '../Administrateur/admin_screens.dart';
import '../inscription/sign_up_screens.dart';
import '../modérateur/moderator_home_screen.dart';
import 'dart:async'; // Importez le package async pour le timer

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  bool _obscureText = true;
  bool _isLoading = false;
  int _failedAttempts = 0;
  DateTime? _lastFailedAttemptTime;
  Timer? _unblockTimer;

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Check if user is blocked
      if (_failedAttempts >= 3) {
        final currentTime = DateTime.now();
        if (_lastFailedAttemptTime != null &&
            currentTime.difference(_lastFailedAttemptTime!).inSeconds < 30) {
          // User is still blocked
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Vous avez été bloqué après trois tentatives de connexion échouées. Veuillez réessayer après 30 secondes.'),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        } else {
          // Reset failed attempts and continue
          var userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: _emailController.text.trim())
              .get();

          if (userQuery.docs.isNotEmpty) {
            var userId = userQuery.docs.first.id;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'bloquer': false,
            });
            _failedAttempts = 0;
          }
        }
      }

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Réinitialiser le compteur de tentatives échouées après une connexion réussie
        _failedAttempts = 0;

        // Vérifier l'email et le mot de passe pour déterminer le type d'utilisateur
        String userId = userCredential.user!.uid;
        String userRole = await _firebaseService.getUserRole(userId);
        bool userBlok = await _firebaseService.getUserBlock(userId);

        if (userBlok) {
          _showBlockedDialog();
          return;
        }

        // Vérifier si l'utilisateur est l'administrateur
        if (_emailController.text.trim() == 'admin123@gmail.com' &&
            _passwordController.text.trim() == 'admin123') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminScreen()),
          );
        } else if (userRole == 'Moderateur' && userBlok == false) {
          // Rediriger vers la page ModeratorScreen pour le modérateur
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ModeratorHomeScreen()),
          );
        } else if (userRole == 'Admin' && userBlok == false) {
          // Rediriger vers la page AdminScreen pour l'administrateur
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminScreen()),
          );
        } else if (userRole == 'Etudiant' && userBlok == false) {
          // Rediriger vers la page HomeScreen pour les utilisateurs normaux
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Utilisateur non trouvé';
            break;
          case 'wrong-password':
            errorMessage = 'Mot de passe incorrect';
            _failedAttempts += 1;
            _lastFailedAttemptTime = DateTime.now();
            if (_failedAttempts >= 3) {
              await _firebaseService
                  .blockUserByEmail(_emailController.text.trim());
              errorMessage =
                  'Vous avez été bloqué après trois tentatives de connexion échouées.';
              _showBlockedAfterAttemptsDialog();
            }
            break;
          case 'invalid-email':
            errorMessage = 'Email invalide';
            break;
          default:
            errorMessage = 'Une erreur s\'est produite. Veuillez réessayer.';
            _failedAttempts += 1;
            _lastFailedAttemptTime = DateTime.now();
            if (_failedAttempts >= 3) {
              await _firebaseService
                  .blockUserByEmail(_emailController.text.trim());
              errorMessage =
                  'Vous avez été bloqué après trois tentatives de connexion échouées.';
              _showBlockedAfterAttemptsDialog();
            }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        // Journal de l'erreur pour un débogage plus facile
        print('Erreur lors de la connexion : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur s\'est produite : $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showBlockedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Utilisateur bloqué'),
          content: const Text(
              'Vous avez été bloqué pour non respect des modalités de l\'application.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomeScreen()));
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  void _showBlockedAfterAttemptsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Utilisateur bloqué'),
          content: const Text(
              'Vous avez été bloqué après trois tentatives de connexion échouées. Veuillez réessayer après 30 secondes.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomeScreen()));
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    // Démarrer un timer pour débloquer l'utilisateur après 30 secondes
    _unblockTimer?.cancel(); // Annuler le timer précédent s'il existe
    _unblockTimer = Timer(const Duration(seconds: 30), () async {
      setState(() {
        _failedAttempts = 0;
      });
      // Réinitialiser le champ `bloquer` dans Firestore
      await _firebaseService.unblockUserByEmail(_emailController.text.trim());
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _unblockTimer?.cancel(); // Annuler le timer lorsqu'il n'est plus nécessaire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2f7dc8),
        title: const Text('Connexion'),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(36.0).copyWith(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'Se connecter',
                          style: TextStyle(
                            color: Color(0xFF2f7dc8),
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        _buildTextField(
                          labelText: 'Email',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Veuillez entrer un email valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15.0),
                        _buildTextField(
                          labelText: 'Mot de passe',
                          icon: Icons.lock_outline,
                          obscureText: _obscureText,
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF2f7dc8),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF2f7dc8)),
                                onPressed: _signIn,
                                child: const Text('Se connecter'),
                              ),
                        Align(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PasswordResetScreen()));
                            },
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(color: Color(0xFF2f7dc8)),
                            ),
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Pas encore inscrit? ',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal),
                            children: <TextSpan>[
                              TextSpan(
                                text: ' Inscrivez-vous',
                                style: const TextStyle(
                                    color: Color(0xFF2f7dc8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
