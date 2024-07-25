import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forumapp0/features/authentification/screens/modérateur/post_screen_moderator.dart';
import '../../fonctions/firebase_service.dart';
import '../Accueil/home_screens.dart';
import '../Bienvenue/welcome_sreen.dart';
import '../notifications/notifications.dart';
import 'etudiants_signales.dart';

class ModeratorHomeScreen extends StatefulWidget {
  @override
  _ModeratorHomeScreenState createState() => _ModeratorHomeScreenState();
}

class _ModeratorHomeScreenState extends State<ModeratorHomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  User? _currentUser;
  String _prenom = '';
  String _nom = '';

  @override
  void initState() {
    super.initState();
    _currentUser = _firebaseService.getCurrentUser();
    if (_currentUser != null) {
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _prenom = userDoc['prenom'];
          _nom = userDoc['nom'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Erreur lors de la récupération des informations de l'utilisateur: $e")),
      );
    }
  }

  String _getInitials() {
    if (_prenom.isNotEmpty && _nom.isNotEmpty) {
      return _prenom[0].toUpperCase() + _nom[0].toUpperCase();
    }
    return 'NN';
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostsScreen()),
    );
  }

  void _homeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  void _viewNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsScreen()),
    );
  }

  void _signalerUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReportUserScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> buttons = [
      {'icon': Icons.home, 'text': 'Mon compte', 'onTap': _homeScreen},
      {
        'icon': Icons.comment_outlined,
        'text': 'Voir les posts',
        'onTap': _showPosts
      },
      {
        'icon': Icons.person_outline_sharp,
        'text': 'Signaler un utilisateur',
        'onTap': _signalerUser
      },
      {
        'icon': Icons.report,
        'text': 'Posts et Commentaires signales',
        'onTap': _viewNotifications
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Modérateur'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30.0,
                    backgroundColor: Colors.white,
                    child: Text(
                      _getInitials(),
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    '$_prenom $_nom',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUser?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Voir les posts'),
              onTap: _showPosts,
            ),
            ListTile(
              leading: const Icon(Icons.comment_rounded),
              title: const Text('Mon compte'),
              onTap: _homeScreen,
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_sharp),
              title: const Text('Signaler un utilisateur'),
              onTap: _signalerUser,
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Posts et Commentaires signales'),
              onTap: _viewNotifications,
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app_outlined),
              title: const Text('Se déconnecter'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          children: buttons.map((button) {
            return GestureDetector(
              onTap: button['onTap'],
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      button['icon'],
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      button['text'],
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
