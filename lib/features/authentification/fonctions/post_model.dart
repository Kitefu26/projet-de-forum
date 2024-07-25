class PostModel {
  final String id;
  final String content;
  final String category;
  final String userId;
  final int commentCount;
  final String? imageUrl; // Champ optionnel pour l'URL de l'image
  final String niveau;
  final String avatarUrl;

  PostModel({
    required this.id,
    required this.content,
    required this.category,
    required this.userId,
    required this.niveau,
    this.commentCount = 0,
    this.imageUrl, // Champ imageUrl ajouté au constructeur
    required this.avatarUrl,
  });

  factory PostModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PostModel(
      id: documentId,
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      userId: data['userId'] ?? '',
      niveau: data['niveau'] ?? '', // Récupération de l'URL de l'image
      commentCount: data['commentCount'] ?? 0,
      imageUrl: data['imageUrl'],
      avatarUrl: data['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'category': category,
      'userId': userId,
      'niveau': niveau,
      'commentCount': commentCount,
      'imageUrl': imageUrl, // Ajout de l'URL de l'image au map
      'avatarUrl': avatarUrl,
    };
  }

  String getInitials(String prenom, String nom) {
    return prenom.isNotEmpty && nom.isNotEmpty
        ? prenom[0].toUpperCase() + nom[0].toUpperCase()
        : '';
  }
}
