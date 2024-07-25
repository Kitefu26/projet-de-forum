import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../Accueil/home_screens.dart';
import '../connexion/sign_in_screens.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String _role = 'Etudiant';
  bool _blocked = false;
  bool _obscureText = true;
  bool _emailExistsError = false;
  String? _selectedNiveau; // Add this line

  // Add a FocusNode for the password field to control focus programmatically
  final FocusNode _passwordFocusNode = FocusNode();

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Save user info in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'nom': _nomController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'niveau': _selectedNiveau, // Change this line
          'email': _emailController.text.trim(),
          'role': _role,
          'bloquer': _blocked
        });

        // Redirect to home screen after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          setState(() {
            _emailExistsError = true;
          });
        } else {
          print('Connection error: ${e.message}');
        }
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('Inscription'),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss keyboard on tap outside
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Card(
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
                                'S\'inscrire',
                                style: TextStyle(
                                  color: Colors.brown,
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 25.0),
                              _buildTextField(
                                controller: _nomController,
                                labelText: 'Nom',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom';
                                  }
                                  return null;
                                },
                                // Move focus to next field when pressing "Next" on keyboard
                                onEditingComplete: () => FocusScope.of(context)
                                    .nextFocus(), // Move to next field
                              ),
                              const SizedBox(height: 15.0),
                              _buildTextField(
                                controller: _prenomController,
                                labelText: 'Prénom',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre prénom';
                                  }
                                  return null;
                                },
                                // Move focus to niveau field when pressing "Next" on keyboard
                                onEditingComplete: () => FocusScope.of(context)
                                    .nextFocus(), // Move to next field
                              ),
                              const SizedBox(height: 15.0),
                              _buildDropdownField(
                                labelText: 'Niveau',
                                icon: Icons.school,
                                validator: (value) {
                                  if (value == null) {
                                    return 'Veuillez choisir votre niveau';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _selectedNiveau = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 15.0),
                              _buildTextField(
                                controller: _emailController,
                                labelText: 'Email',
                                icon: Icons.email,
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
                                onChanged: (value) {
                                  setState(() {
                                    _emailExistsError = false;
                                  });
                                },
                                // Move focus to password field when pressing "Next" on keyboard
                                onEditingComplete: () => FocusScope.of(context)
                                    .nextFocus(), // Move to next field
                              ),
                              if (_emailExistsError)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text(
                                    'Cet email est déjà utilisé.',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 15.0),
                              _buildTextField(
                                controller: _passwordController,
                                labelText: 'Mot de passe',
                                icon: Icons.lock,
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre mot de passe';
                                  }
                                  if (value.length < 8) {
                                    return 'Au moins 8 caractères';
                                  }
                                  return null;
                                },
                                // Assign focus node to password field
                                focusNode: _passwordFocusNode,
                              ),
                              const SizedBox(height: 20.0),
                              ElevatedButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                ),
                                onPressed: _signUp,
                                child: const Text('S\'inscrire'),
                              ),
                              const SizedBox(
                                  height:
                                      5.0), // Ajustement de l'espace entre le bouton et le texte suivant
                              RichText(
                                text: TextSpan(
                                  text: 'Vous avez déjà un compte? ',
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 12),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Connectez-vous',
                                      style: const TextStyle(
                                          color: Colors.brown, fontSize: 13),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SignInScreen(),
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
                    // Bottom padding to prevent the text from being covered by the keyboard
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required String? Function(String?) validator,
    bool isPassword = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    FocusNode? focusNode,
  }) {
    return Card(
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Color(0xFF795548)),
          prefixIcon: Icon(icon, color: Colors.brown),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.brown),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.brown,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
        ),
        obscureText: isPassword ? _obscureText : false,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required IconData icon,
    required String? Function(String?) validator,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Color(0xFF795548)),
          prefixIcon: Icon(icon, color: Colors.brown),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.brown),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        items: ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2']
            .map((niveau) => DropdownMenuItem<String>(
                  value: niveau,
                  child: Text(niveau),
                ))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
