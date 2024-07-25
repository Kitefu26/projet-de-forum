import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../fonctions/firebase_service.dart';

class ReportUserScreen extends StatefulWidget {
  @override
  _ReportUserScreenState createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<DocumentSnapshot> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      QuerySnapshot snapshot = await _firebaseService.getAllUsers();
      setState(() {
        _users = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du chargement des utilisateurs: $e"),
        ),
      );
    }
  }

  void _reportUser(DocumentSnapshot user) async {
    final userData = user.data() as Map<String, dynamic>;
    String userId = user.id;
    String prenom = userData['prenom'] ?? 'Inconnu';
    String nom = userData['nom'] ?? 'Inconnu';
    String email = userData['email'] ?? 'Inconnu';

    // Code pour enregistrer le signalement dans Firestore ou autre service
    try {
      await _firebaseService.reportUser(userId, prenom, nom, email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Signalement effectué pour $prenom $nom."),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du signalement: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DocumentSnapshot> filteredUsers = _users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final userName = '${userData['prenom']} ${userData['nom']}';
      return userName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Signaler des utilisateurs'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: filteredUsers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final userData = user.data() as Map<String, dynamic>;
                String userId = user.id;
                String userName = '${userData['prenom']} ${userData['nom']}';

                return Card(
                  elevation: 5.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(userName),
                    trailing: IconButton(
                      icon: Icon(Icons.report, color: Colors.orange),
                      onPressed: () => _reportUser(user),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
