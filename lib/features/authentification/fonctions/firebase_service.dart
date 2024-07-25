import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../screens/Accueil/post_detail_screens.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Méthode pour obtenir le nom de l'utilisateur connecté
  Future<String> getCurrentUserDisplayName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return user.displayName ?? 'Utilisateur';
    } else {
      throw Exception('Utilisateur non connecté');
    }
  }

  //envoyeur de notification
  Future<void> sendNotificationToAllUsers(String postId) async {
    try {
      // Get the post document
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      String postContent = postDoc['postContent'];
      String postUserId = postDoc['userId'];
      String postCategory = postDoc['category'];

      // Get the post creator's name
      DocumentSnapshot postUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postUserId)
          .get();
      String postUserName = '${postUserDoc['prenom']} ${postUserDoc['nom']}';

      // Get all users except the post creator and admin
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        // Check if userData is not null and contains the 'role' key
        bool isAdmin = userData != null &&
            userData.containsKey('role') &&
            userData['role'] == 'admin';

        // Skip the post creator and admin
        if (userId == postUserId || isAdmin) {
          continue;
        }

        // Create a new notification document
        Map<String, dynamic> notificationData = {
          'type': 'new_post',
          'postId': postId,
          'userId': userId,
          'userName': postUserName,
          'postContent': postContent,
          'category': postCategory,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        };

        // Add the notification document to the notifications collection
        await FirebaseFirestore.instance
            .collection('notificationPosts')
            .add(notificationData);
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification: $e');
      throw e;
    }
  }

  Stream<int> getUnreadNotificationsCount() {
    return FirebaseFirestore.instance
        .collection('notificationPosts')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('read',
            isEqualTo:
                false) // Update this line to use 'ead' instead of 'isRead'
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Authentification
  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<String> getUserRole(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      return userDoc['role'] ??
          'Etudiant'; // Renvoie 'Utilisateur' si aucun rôle n'est défini
    } else {
      throw Exception('Utilisateur non trouvé');
    }
  }

  Future<bool> getUserBlock(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      return userDoc['bloquer'];
    } else {
      throw Exception('Utilisateur non trouvé');
    }
  }

  // Firestore
  Future<DocumentSnapshot> getUserDocument(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> editPost(String postId, String newContent,
      {String? imageUrl}) async {
    // Générer les mots-clés
    List<String> keywords = generateKeywords(newContent);

    // Créer le document du post avec les mots-clés
    Map<String, dynamic> updateData = {
      'postContent': newContent,
      'keywords': keywords,
    };
    if (imageUrl != null) {
      updateData['imageUrl'] = imageUrl;
    }

    await _firestore.collection('posts').doc(postId).update(updateData);
  }

  Future<QuerySnapshot> getAllUsers() async {
    return await _firestore.collection('users').get();
  }

  Stream<QuerySnapshot> getModeratorReportsStream() {
    return _firestore
        .collection('reports')
        .where('type', isEqualTo: 'moderator')
        .snapshots();
  }

  Future<void> giveModeratorPrivileges(String userId) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    DocumentSnapshot userDoc = await userRef.get();
    if (userDoc.exists) {
      await userRef.update({
        'role': 'Moderateur',
      });
    } else {
      throw Exception('User not found');
    }
  }

  Future<void> removeModeratorPrivileges(String userId) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    DocumentSnapshot userDoc = await userRef.get();
    if (userDoc.exists) {
      await userRef.update({
        'role': 'Etudiant',
      });
    } else {
      throw Exception('User not found');
    }
  }

  Stream<QuerySnapshot> getAdminReportsStream() {
    return _firestore.collection('adminReports').snapshots();
  }

  Stream<QuerySnapshot> getPostsStream() {
    return _firestore.collection('posts').snapshots();
  }

  Future<String> getAuthorName(String userId) async {
    DocumentSnapshot userDoc = await getUserDocument(userId);
    if (userDoc.exists) {
      return userDoc['prenom'] + ' ' + userDoc['nom'];
    } else {
      return 'Auteur inconnu';
    }
  }

  Future<DocumentSnapshot> getPostDetails(String postId) async {
    return await _firestore.collection('posts').doc(postId).get();
  }

  Stream<QuerySnapshot> getRecentPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<int> getLessonCountForCategory(String category) async {
    QuerySnapshot snapshot = await _firestore
        .collection('lessons')
        .where('category', isEqualTo: category)
        .get();
    return snapshot.docs.length;
  }

  // Méthodes pour les commentaires
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> updateUserProfile(String userId, String prenom, String nom,
      String email, String niveau, String password) async {
    User? user = _auth.currentUser;

    if (user != null) {
      // Mettre à jour l'email si nécessaire
      if (email.isNotEmpty && email != user.email) {
        await user.updateEmail(email);
      }

      // Mettre à jour le mot de passe si nécessaire
      if (password.isNotEmpty) {
        await user.updatePassword(password);
      }

      // Mettre à jour le profil dans Firestore
      await _firestore.collection('users').doc(userId).update({
        'prenom': prenom,
        'nom': nom,
        'email': email,
        'niveau': niveau,
      });
    }
  }

  Future<void> addComment(
      String postId, Map<String, dynamic> commentData) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(commentData);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> updateComment(
      String postId, String commentId, Map<String, dynamic> updateData) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update(updateData);
  }

  // Méthodes pour les images
  Future<String?> uploadImage(File imageFile, String postId) async {
    try {
      String fileName =
          'posts/$postId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image : $e');
      return null;
    }
  }

  Future<String?> pickAndUploadImage(String userId) async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        String fileName = path.basename(imageFile.path);
        Reference ref =
            FirebaseStorage.instance.ref().child('avatars/$userId/$fileName');
        UploadTask uploadTask = ref.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        String imageUrl = await snapshot.ref.getDownloadURL();
        return imageUrl;
      } else {
        print('Aucune image sélectionnée.');
        return null;
      }
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image: $e');
      return null;
    }
  }

  Future<void> createPost(
      String content, String niveau, String category, String userId,
      {String? imageUrl}) async {
    // Générer les mots-clés
    List<String> keywords = generateKeywords(content);

    // Récupérer l'URL de l'avatar de l'utilisateur
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    String userAvatarUrl = userDoc['avatarUrl'] ?? '';

    // Créer le document du post avec les mots-clés
    await _firestore.collection('posts').add({
      'content': content,
      'category': category,
      'niveau': niveau,
      'userId': userId,
      'commentCount': 0,
      'imageUrl': imageUrl,
      'keywords': keywords,
      'userAvatarUrl':
          userAvatarUrl, // Ajouter l'URL de l'avatar de l'utilisateur
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  List<String> generateKeywords(String content) {
    return content
        .toLowerCase() // Convertir en minuscules
        .split(RegExp(r'\W+')) // Diviser par les caractères non alphabétiques
        .where((word) => word.isNotEmpty) // Supprimer les mots vides
        .toSet() // Supprimer les doublons
        .toList();
  }

  Stream<QuerySnapshot> getFilteredPostsStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true) // Ajoutez cette ligne
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('posts')
          .where('keywords', arrayContains: query.toLowerCase())
          .orderBy('timestamp', descending: true) // Ajoutez cette ligne
          .snapshots();
    }
  }

  Stream<int> getPostCountForCategory(String category) {
    return _firestore
        .collection('posts')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  Future<String?> getUserNiveau(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc['niveau'];
      }
    } catch (e) {
      print("Erreur lors de la récupération du niveau de l'utilisateur: $e");
    }
    return null;
  }

  Stream<int> getCommentCountStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<String?> uploadImageToStorage(File imageFile, String email) async {
    try {
      String fileName = 'avatar_$email.jpg'; // Nom du fichier dans Storage
      Reference ref = _storage.ref().child('avatars/$fileName');

      // Téléchargement du fichier
      await ref.putFile(imageFile);

      // Récupération de l'URL de téléchargement
      String downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print(
          'Erreur lors du téléchargement de l\'image vers Firebase Storage: $e');
      return null;
    }
  }

  Future<String?> getDownloadUrl(String email) async {
    try {
      String fileName = 'avatar_$email.jpg'; // Nom du fichier dans Storage
      Reference ref = _storage.ref().child('avatars/$fileName');

      // Récupération de l'URL de téléchargement
      String downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print(
          'Erreur lors de la récupération de l\'URL de téléchargement depuis Firebase Storage: $e');
      return null;
    }
  }

  Future<void> updateProfilePictureUrl(String email, String url) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        await _firestore.collection('users').doc(documentSnapshot.id).update({
          'profilePictureUrl': url,
        });
      }
    } catch (e) {
      print('Error updating profile picture URL: $e');
    }
  }

  Future<void> reportPost(
      String postId,
      String reporterUid,
      String postAuthorName,
      String postAuthorSurname,
      String reporterName,
      String reporterSurname) async {
    // Récupérer le contenu du post
    DocumentSnapshot postSnapshot =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    if (!postSnapshot.exists) {
      throw Exception('Post not found');
    }
    Map<String, dynamic> postData = postSnapshot.data() as Map<String, dynamic>;
    String postContent = postData['postContent'] ??
        'Content not available'; // Ajustez selon le champ du contenu

    // Ajouter un rapport de signalement
    await FirebaseFirestore.instance.collection('reportPosts').doc(postId).set({
      'postId': postId,
      'reportedBy': reporterUid,
      'postAuthorName': postAuthorName,
      'postAuthorSurname': postAuthorSurname,
      'reporterName': reporterName,
      'reporterSurname': reporterSurname,
      'postContent': postContent,
      'reportedAt': FieldValue.serverTimestamp(),
    });

    // Ajouter une notification de signalement
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'reportPosts',
      'postId': postId,
      'reporterUid': reporterUid,
      'reporterName': reporterName,
      'reporterSurname': reporterSurname,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'postContent':
          postContent, // Inclure le contenu du post dans la notification
    });
  }

  //methode de signalement commentaire
  Future<void> reportComment(String postId, String commentId, String userId,
      String reporterName, String reporterSurname) async {
    try {
      // Retrieve the comment author's information from the nested comments collection
      DocumentSnapshot commentDoc = await FirebaseFirestore.instance
          .collection('posts') // The parent collection
          .doc(postId) // The specific post document
          .collection('comments') // The nested comments collection
          .doc(commentId) // The specific comment document
          .get();

      if (!commentDoc.exists) {
        throw Exception('Commentaire introuvable');
      }

      Map<String, dynamic> commentData =
          commentDoc.data() as Map<String, dynamic>;

      // Debug: Print the commentData Map to check available fields
      print('Comment Data: $commentData');

      String authorName = commentData['prenom'] ??
          'Inconnu'; // Adjust according to your field names
      String authorSurname = commentData['nom'] ??
          'Inconnu'; // Adjust according to your field names
      String commentContent = commentData['content'] ??
          'Pas de description'; // Adjust according to your field names

      // Add the report to the 'reports' collection
      await FirebaseFirestore.instance.collection('reports').add({
        'postId': postId,
        'commentId': commentId,
        'reportedBy': userId,
        'reporterName': reporterName,
        'reporterSurname': reporterSurname,
        'authorName': authorName,
        'authorSurname': authorSurname,
        'content': commentContent,
        'reportedAt': FieldValue.serverTimestamp(),
        'read':
            false, // Assuming you want to track if a report has been read by a moderator
      });

      // Send a notification to the moderator
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'reports',
        'postId': postId,
        'commentId': commentId,
        'reportedBy': userId,
        'reporterName': reporterName,
        'reporterSurname': reporterSurname,
        'authorName': authorName,
        'authorSurname': authorSurname,
        'content': commentContent,
        'reportedAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('Signalement ajouté avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout du signalement: $e');
      throw e;
    }
  }

  Future<void> updateUserAvatar(File imageFile, String userId) async {
    try {
      String? email = _auth.currentUser?.email;
      if (email == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Téléchargement de l'image sur Firebase Storage
      String? imageUrl = await uploadImageToStorage(imageFile, email);
      if (imageUrl == null) {
        throw Exception('Échec du téléchargement de l\'image');
      }

      // Mise à jour de l'URL de l'avatar dans le document utilisateur
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'avatarUrl': imageUrl});

      // Mise à jour de l'URL de l'avatar dans les posts de l'utilisateur
      QuerySnapshot userPostsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      for (QueryDocumentSnapshot postDoc in userPostsSnapshot.docs) {
        await postDoc.reference.update({'userAvatarUrl': imageUrl});
      }

      // Mise à jour de l'URL de l'avatar dans les commentaires de l'utilisateur
      QuerySnapshot userCommentsSnapshot = await _firestore
          .collectionGroup('comments')
          .where('userId', isEqualTo: userId)
          .get();
      for (QueryDocumentSnapshot commentDoc in userCommentsSnapshot.docs) {
        await commentDoc.reference.update({'userAvatarUrl': imageUrl});
      }
      print('Avatar mis à jour avec succès.');
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'avatar : $e');
    }
  }

  //bloquer utilisateur
  Future<void> blockUserByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentReference userDoc = querySnapshot.docs.first.reference;
        print('Document ID: ${userDoc.id}'); // Ajouté pour débogage
        await userDoc.update({'bloquer': true});
        print('Utilisateur bloqué avec succès');
      } else {
        print('Utilisateur non trouvé');
      }
    } catch (e) {
      print('Erreur lors du blocage de l\'utilisateur : $e');
      throw e; // Vous pouvez aussi choisir de renvoyer une erreur spécifique ici.
    }
  }

  //débloquer utilisateur
  Future<void> unblockUserByEmail(String email) async {
    var userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (userQuery.docs.isNotEmpty) {
      var userId = userQuery.docs.first.id;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'bloquer': false,
      });
    }
  }

  //
  Future<void> reportUser(
      String userId, String prenom, String nom, String email) {
    return _firestore.collection('reportUser').add({
      'userId': userId,
      'prenom': prenom,
      'nom': nom,
      'email': email,
      'date': DateTime.now(),
    });
  }

  Future<QuerySnapshot> getReportedUsers() {
    return _firestore.collection('reportUser').get();
  }

  Future<QuerySnapshot> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true) // Trier par date décroissante
        .get();
  }
}
