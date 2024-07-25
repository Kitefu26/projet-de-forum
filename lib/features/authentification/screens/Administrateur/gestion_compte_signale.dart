import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../fonctions/firebase_service.dart';

class ReportedUserScreen extends StatefulWidget {
  @override
  _ReportedUserScreenState createState() => _ReportedUserScreenState();
}

class _ReportedUserScreenState extends State<ReportedUserScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<DocumentSnapshot> _reportedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadReportedUsers();
  }

  Future<void> _loadReportedUsers() async {
    try {
      QuerySnapshot snapshot = await _firebaseService.getReportedUsers();
      setState(() {
        _reportedUsers = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Erreur lors du chargement des utilisateurs signalés: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Utilisateurs Signalés'),
      ),
      body: _reportedUsers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _reportedUsers.length,
              itemBuilder: (context, index) {
                final user = _reportedUsers[index];
                final userData = user.data() as Map<String, dynamic>;
                String userId = user.id;
                String prenom = userData['prenom'] ?? 'Inconnu';
                String nom = userData['nom'] ?? 'Inconnu';
                String email = userData['email'] ?? 'Inconnu';

                return Card(
                  elevation: 5.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text('$prenom $nom'),
                    subtitle: Text(email),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportedUserDetailsPage(
                            userId: userId,
                            prenom: prenom,
                            nom: nom,
                            email: email,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class ReportedUserDetailsPage extends StatelessWidget {
  final String userId;
  final String prenom;
  final String nom;
  final String email;

  ReportedUserDetailsPage({
    required this.userId,
    required this.prenom,
    required this.nom,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'Utilisateur Signalé'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: $userId',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              'Prénom: $prenom',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'Nom: $nom',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'Email: $email',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
