import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Utilisateurs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher utilisateur...',
                hintStyle: TextStyle(fontWeight: FontWeight.bold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                prefixIcon: Icon(Icons.search),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }

                // Liste des utilisateurs
                List<DocumentSnapshot> users = snapshot.data!.docs;

                // Filtrer les utilisateurs selon la recherche et exclure les administrateurs
                List<DocumentSnapshot> filteredUsers = users.where((user) {
                  Map<String, dynamic> userData =
                      user.data() as Map<String, dynamic>;
                  String fullName =
                      '${userData['nom'] ?? ''} ${userData['prenom'] ?? ''}'
                          .toLowerCase();
                  String role = userData['role'] ?? '';
                  return fullName.contains(searchQuery) && role != 'admin';
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(child: Text('Aucun utilisateur trouvé.'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    // Données de l'utilisateur
                    Map<String, dynamic> userData =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    String userId = filteredUsers[index].id;

                    // Récupérer prénom et nom
                    String prenom =
                        userData['prenom'] ?? 'Utilisateur sans prénom';
                    String nom = userData['nom'] ?? 'Utilisateur sans nom';

                    // Vérifier si l'utilisateur est bloqué
                    bool isBlocked = userData['bloquer'] ?? false;

                    return ListTile(
                      title: Text('$nom $prenom'),
                      subtitle:
                          Text(userData['email'] ?? 'Email non disponible'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isBlocked ? Icons.lock : Icons.lock_open,
                              color:
                                  isBlocked ? Colors.deepOrange : Colors.green,
                            ),
                            onPressed: () {
                              // Changer l'état de blocage de l'utilisateur
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Confirmation'),
                                    content: Text(
                                        'Voulez-vous ${isBlocked ? 'débloquer' : 'bloquer'} cet utilisateur ?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Annuler'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text(isBlocked
                                            ? 'Débloquer'
                                            : 'Bloquer'),
                                        onPressed: () async {
                                          // Mettre à jour le statut de l'utilisateur dans Firestore
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .update({'bloquer': !isBlocked});
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Utilisateur ${isBlocked ? 'débloqué' : 'bloqué'} avec succès')),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Supprimer l'utilisateur
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Confirmation'),
                                    content: Text(
                                        'Voulez-vous vraiment supprimer cet utilisateur ?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Annuler'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('Supprimer'),
                                        onPressed: () async {
                                          // Supprimer l'utilisateur de Firestore
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .delete();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Utilisateur supprimé avec succès')),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
