import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../fonctions/firebase_service.dart';
import '../Bienvenue/welcome_sreen.dart';
import 'gestionUtilisateur_screen.dart'; // Importez ManageUsersScreen
import 'gestion_compte_signale.dart';
import 'gesttiondesprivileges.dart'; // Importez GiveModeratorPrivilegesScreen

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
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

  void _showUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManageUsersScreen()),
    );
  }

  void _viewNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReportedUserScreen()),
    );
  }

  void _giveModeratorPrivileges() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GiveModeratorPrivilegesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> buttons = [
      {
        'icon': Icons.people,
        'text': 'Gestion des comptes etudiants ',
        'onTap': _showUsers
      },
      {
        'icon': Icons.person_add,
        'text': 'Donner privilèges de modérateur',
        'onTap': _giveModeratorPrivileges
      },
      {
        'icon': Icons.notifications,
        'text': 'Voir les comptes etudiants signales',
        'onTap': _viewNotifications
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Admin'),
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
              leading: const Icon(Icons.people),
              title: const Text('Gérer les utilisateurs'),
              onTap: _showUsers,
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Voir les notifications'),
              onTap: _viewNotifications,
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Donner privilèges de modérateur'),
              onTap: _giveModeratorPrivileges,
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
                      offset: Offset(0, 3),
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
