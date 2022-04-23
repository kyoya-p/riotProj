
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/firestoreWidget.dart';

/* Landing page
  - Authentication Check
 */

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class FirebaseSignInWidget extends StatelessWidget {
  FirebaseSignInWidget({required this.appBuilder});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RIOT Sign In', home: _getLandingPage());
  }

  final AsyncWidgetBuilder<User> appBuilder;

  Widget _getLandingPage() {
    return StreamBuilder<User>(
      stream: firebaseAuth.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return appBuilder(context, snapshot);
        } else {
          return FbLoginPage();
        }
      },
    );
  }
}

IconButton loginButton(BuildContext context) => IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FbLoginPage()),
        );
      },
      icon: Icon(Icons.account_circle),
    );
