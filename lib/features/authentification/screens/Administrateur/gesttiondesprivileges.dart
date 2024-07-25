import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../fonctions/firebase_service.dart';

class GiveModeratorPrivilegesScreen extends StatefulWidget {
  @override
  _GiveModeratorPrivilegesScreenState createState() =>
      _GiveModeratorPrivilegesScreenState();
}

class _GiveModeratorPrivilegesScreenState
    extends State<GiveModeratorPrivilegesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<DocumentSnapshot> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      QuerySnapshot snapshot = await _firebaseService.getAllUsers();
      setState(() {
        _users = snapshot.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return (data['niveau'] == 'Master 1' ||
                  data['niveau'] == 'Master 2') &&
              data['role'] != 'admin';
        }).toList();
      });
      print("Users loaded: ${_users.length}"); // Debug print
    } catch (e) {
      print("Error loading users: $e"); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur lors du chargement des utilisateurs: $e")),
      );
    }
  }

  Future<void> _giveModeratorPrivileges(String userId) async {
    try {
      await _firebaseService.giveModeratorPrivileges(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Privilèges de modérateur donnés avec succès')),
      );
      _loadUsers(); // Recharger les utilisateurs pour mettre à jour les rôles
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  Future<void> _removeModeratorPrivileges(String userId) async {
    try {
      await _firebaseService.removeModeratorPrivileges(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Privilèges de modérateur retirés avec succès')),
      );
      _loadUsers(); // Recharger les utilisateurs pour mettre à jour les rôles
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des privilèges de modérateur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _users.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final userData = user.data() as Map<String, dynamic>;
                  String prenom = userData.containsKey('prenom')
                      ? userData['prenom']
                      : 'N/A';
                  String nom =
                      userData.containsKey('nom') ? userData['nom'] : 'N/A';
                  String role = userData.containsKey('role')
                      ? userData['role']
                      : 'Etudiant';
                  String niveau = userData.containsKey('niveau')
                      ? userData['niveau']
                      : 'N/A';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$prenom $nom',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Rôle: $role',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Niveau: $niveau',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Color(0xFF2f7dc8),
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    _giveModeratorPrivileges(user.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF2f7dc8),
                                ),
                                child: Text('Donner privilèges'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    _removeModeratorPrivileges(user.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Retirer privilèges'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
