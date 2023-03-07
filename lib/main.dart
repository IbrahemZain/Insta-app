import 'package:flutter/material.dart';
import 'package:insta_app/pages/home.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

// bool shouldUseFirestoreEmulator = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey:
        'AAAAgB3m9zc:APA91bFgSl_27RPKMfQvRygakxQP-g0h91Hvhxs68ui7uIl1GO38x5cvf4rAEcxOJBrxv3TssW0H4mieZYQehWjtJi83keqaKzTP2S5kYoe7kMJ5YdOvrxQfu9GX7QTcCXkRiJZRsF46',
    appId: '1:550257489719:android:5f01bb4a975b66e1884cb2',
    messagingSenderId: '550257489719',
    projectId: 'insta-449be',
    storageBucket: 'gs://insta-449be.appspot.com',
  ));
   FirebaseFirestore.instance.settings;

  // if (shouldUseFirestoreEmulator) {
  //   FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  // }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      home: Home(),
    );
  }
}
