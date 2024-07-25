import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../fonctions/firebase_service.dart';

class ModeratorScreen extends StatefulWidget {
  @override
  _ModeratorScreenState createState() => _ModeratorScreenState();
}

class _ModeratorScreenState extends State<ModeratorScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Stream<QuerySnapshot>? _reportsStream;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _reportsStream = _firebaseService.getModeratorReportsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Modérateur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _reportsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Aucun rapport disponible.'));
                  }

                  final reports = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final reportData =
                          reports[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(
                              'Utilisateur signalé: ${reportData['userId']}'),
                          subtitle: Text(
                              'Signalé par: ${reportData['reporterName']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.arrow_forward),
                            onPressed: () {
                              // Ajouter des actions supplémentaires ici si nécessaire
                              _showReportDetails(reportData);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> reportData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails du rapport'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Utilisateur signalé: ${reportData['userId']}'),
              SizedBox(height: 10),
              Text('Signalé par: ${reportData['reporterName']}'),
              SizedBox(height: 10),
              Text('Date du signalement: ${reportData['timestamp']}'),
              SizedBox(height: 10),
              Text('Description du problème: ${reportData['description']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Ajouter des actions supplémentaires si nécessaire
              },
              child: Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                // Action pour marquer le rapport comme traité
                _markReportAsProcessed(reportData);
                Navigator.of(context).pop();
              },
              child: Text('Marquer comme traité'),
            ),
          ],
        );
      },
    );
  }

  void _markReportAsProcessed(Map<String, dynamic> reportData) {
    // Implémentez la logique pour marquer le rapport comme traité dans Firebase
    // Par exemple, mettre à jour le statut du rapport dans la collection Firestore
  }
}
