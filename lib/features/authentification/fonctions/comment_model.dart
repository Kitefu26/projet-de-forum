import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String content;
  final String authorId;
  final String prenom;
  final String nom;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.prenom,
    required this.nom,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'authorId': authorId,
      'prenom': prenom,
      'nom': nom,
      'timestamp': timestamp,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      prenom: map['prenom'] ?? '',
      nom: map['nom'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
