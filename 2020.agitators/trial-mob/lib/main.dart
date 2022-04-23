import 'package:flutter/material.dart';
import './main_test_firestore.dart' as test_firestore;
import './main_test_adduser.dart' as test_adduser;
import './main_test_login.dart' as test_login;
import 'ui/riotAgitator.dart';

void main() {
  //runApp(MyApp());
  runApp(test_firestore.MyApp()); //test用コード
  //runApp(test_adduser.MyApp()); //test用コード
  //runApp(test_login.MyApp()); //test用コード
}
