import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateBusinessPage extends StatefulWidget {
  const CreateBusinessPage({super.key});

  @override
  State<CreateBusinessPage> createState() =>
      _CreateBusinessPageState();
}

class _CreateBusinessPageState
    extends State<CreateBusinessPage> {

  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _createBusiness() async {

    if (_controller.text.trim().isEmpty) return;

    setState(() => _loading = true);

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    final db =
        FirebaseFirestore.instance;

    final businessRef =
    db.collection('businesses').doc();

    await db.runTransaction((tx) async {

      tx.set(businessRef, {
        'name': _controller.text.trim(),
        'ownerId': uid,
        'createdAt':
        FieldValue.serverTimestamp(),
      });

      tx.set(
        db.collection('users').doc(uid),
        {
          'businessId':
          businessRef.id,
        },
      );
    });

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(
      backgroundColor:
      const Color(0xFFF2F2F7),

      child: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
              horizontal: 24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [

              /// TÍTULO GRANDE
              const Text(
                "Crea tu negocio",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Configura tu barra para comenzar a gestionar eventos.",
                style: TextStyle(
                  color:
                  CupertinoColors
                      .inactiveGray,
                ),
              ),

              const SizedBox(height: 40),

              /// CAMPO
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                    horizontal: 16),
                decoration:
                BoxDecoration(
                  color:
                  CupertinoColors
                      .white,
                  borderRadius:
                  BorderRadius
                      .circular(
                      18),
                ),
                child: CupertinoTextField(
                  controller:
                  _controller,
                  placeholder:
                  "Ej: Barra Snacks Jorge",
                  padding:
                  const EdgeInsets
                      .symmetric(
                      vertical:
                      14),
                  style:
                  const TextStyle(
                    fontSize: 16,
                  ),
                  decoration:
                  const BoxDecoration(),
                ),
              ),

              const SizedBox(height: 30),

              /// BOTÓN
              SizedBox(
                width:
                double.infinity,
                child:
                CupertinoButton(
                  borderRadius:
                  BorderRadius
                      .circular(
                      18),
                  color:
                  CupertinoColors
                      .systemBlue,
                  onPressed:
                  _loading
                      ? null
                      : _createBusiness,
                  child:
                  _loading
                      ? const CupertinoActivityIndicator(
                    color:
                    CupertinoColors
                        .white,
                  )
                      : const Text(
                    "Crear negocio",
                    style:
                    TextStyle(
                      color: Colors.white,
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
