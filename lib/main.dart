import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'features/authentification/screens/Accueil/post_screens.dart';
import 'features/authentification/screens/Bienvenue/welcome_sreen.dart';
import 'features/authentification/screens/connexion/sign_in_screens.dart';
import 'features/authentification/screens/notifications/notifications.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  }

  // Firebase Storage initialization is included in Firebase.initializeApp
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Forum App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      navigatorKey: navigatorKey,
      routes: {
        '/': (context) => WelcomeScreen(),
        '/notification': (context) => NotificationsScreen(),
        '/signin': (context) => SignInScreen(),
        '/writepost': (context) => WritePostScreen(
              postTitle: '',
              postCategory: '',
              initialLikes: [],
              initialContent: '',
              postId: '',
              onUpdate: () {},
              postNiveau: '',
            ),
      },
    );
  }
}
