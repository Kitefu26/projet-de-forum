import 'package:flutter/material.dart';
import '../connexion/sign_in_screens.dart';
import '../inscription/sign_up_screens.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/background.png'), // Remplacez 'assets/images/background.png' par le chemin de votre image d'arrière-plan
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            _buildImage(),
            _buildWelcomeText(context),
            Expanded(child: Container()),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 150.0, left: 15.0),
          child: Image.asset(
              'assets/images/welcome_screen.png'), // Remplacez 'assets/images/welcome_screen.png' par le chemin de votre image
        ));
  }

  Widget _buildWelcomeText(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(top: 180.0),
        child: Column(
          children: [
            const Text(
              'Bienvenue !',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2f7dc8),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: 'Partageons nos savoirs, construisons notre avenir\n'
                      'Ensemble, pour apprendre et grandir',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.brown,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFF2f7dc8),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10),
                    bottom: Radius.circular(10)), // Adjust the value as needed
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
              child: Text('Connexion'),
            ),
          ),
          ElevatedButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.brown,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10),
                    bottom: Radius.circular(10)), // Adjust the value as needed
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignUpScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
              child: Text('Inscription'),
            ),
          ),
        ],
      ),
    );
  }
}
