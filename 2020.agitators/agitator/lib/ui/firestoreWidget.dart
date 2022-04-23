import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:http/http.dart' as http;

import 'package:riotagitator/login.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:riotagitator/main.dart';

/*
Firestore認証Widget
*/
class FbLoginPage extends StatefulWidget {
  @override
  _FbLoginPageState createState() => _FbLoginPageState();
}

class _FbLoginPageState extends State<FbLoginPage> {
  String loginUserEmail = "";
  String loginUserPassword = "";
  String debugMsg = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 450,
          padding: EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              Container(height: 32),
              TextFormField(
                decoration: InputDecoration(
                    labelText: "Login ID ", hintText: "Mail Address"),
                onChanged: (String value) =>
                    setState(() => loginUserEmail = value),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                onChanged: (String value) =>
                    setState(() => loginUserPassword = value),
              ),
              Container(height: 32),
              Row(
                children: [
                  ElevatedButton(
                    child: Text("Sign in"),
                    onPressed: () =>
                        loginAsUser(loginUserEmail, loginUserPassword),
                    onLongPress: () =>
                        loginAsUser("kyoya.p4@gmail.com", "kyoyap4"),
                  ),
                  //RaisedButton(
                  //    child: Text("as Device"),
                  //    onPressed: () => loginAsDevice("", "")),
                ],
              ),
              Text(debugMsg),
            ],
          ),
        ),
      ),
    );
  }

  loginAsUser(String mailAddr, String password) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
          email: mailAddr, password: password);
      //final User user = result.user;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FirebaseSignInWidget(appBuilder: (context, snapshot) => RiotApp(snapshot.data),),
        ),
      );
    } catch (e) {
      setState(() {
        debugMsg = "Failed: $e\n login: $mailAddr";
        print(debugMsg);
      });
    }
  }

  loginAsDevice(String deviceId, String password) async {
    fetchCustomToken("dev1", "Sharp_01").then((e) {
      //TODO test
      print(e);
    });
    //TODO
    /*try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final UserCredential result = await auth.signInWithCustomToken();
      final User user = result.user;
      setState(() {
        debugMsg = "Success: ${user.email}";
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          //settings: const RouteSettings(name: "/home"),
          builder: (context) => MyApp(),
        ),
      );
    } catch (e) {
      setState(() {
        debugMsg = "Failed: ${e}";
        print(debugMsg);
      });
    }
     */
  }

  Future<http.Response> fetchCustomToken(
      String deviceId, String password) async {
    String url =
        //"http://shokkaa.0t0.jp:8080/customToken?id=$deviceId&pw=$password"; // This is Kawano's private service
        //"http://192.168.3.102:8080/customToken?id=$deviceId&pw=$password"; // This is Kawano's private service
        "http://192.168.3.9:8080/customToken?id=$deviceId&pw=$password"; // This is Kawano's private service

    return http.get(url, headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': 'true'
    });
  }
}
