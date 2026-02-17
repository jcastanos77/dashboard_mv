import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String> getBusinessId() async {

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception("Usuario no autenticado");
  }

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) {
    throw Exception("Documento de usuario no existe");
  }

  final data = doc.data();

  if (data == null || data['businessId'] == null) {
    throw Exception("Usuario sin negocio asignado");
  }

  return data['businessId'] as String;
}
