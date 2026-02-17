import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../business/create_business_page.dart';
import '../home/home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {

            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
            userSnapshot.data!.data() as Map<String, dynamic>?;

            if (data == null || data['businessId'] == null) {
              return const CreateBusinessPage();
            }

            return HomePage(
              businessId: data['businessId'],
            );
          },
        );
      },
    );
  }
}
