import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import 'dart:typed_data';


class SettingsPage extends StatefulWidget {
  final String businessId;

  const SettingsPage({
    super.key,
    required this.businessId,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  String? businessName;
  String? businessId;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .get();

    if (!mounted) return;

    setState(() {
      businessName = snap.data()?['name'] ?? 'Negocio';
      businessId = widget.businessId;
    });
  }

  Future<void> _logout(BuildContext context) async {
    showCupertinoDialog(
      context: context,
      builder: (_) =>
          CupertinoAlertDialog(
            title: const Text("Cerrar sesión"),
            content: const Text("¿Seguro que deseas salir de tu cuenta?"),
            actions: [
              CupertinoDialogAction(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text("Cerrar sesión"),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context);
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          "Configuración",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [

            /// =============================
            /// HEADER EMPRESA
            /// =============================

            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(businessId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      width: 110,
                      height: 110,
                      child: CupertinoActivityIndicator(),
                    );
                  }

                  final data =
                  snapshot.data!.data() as Map<String, dynamic>?;

                  final logoUrl = data?['logoUrl'];
                  final businessName = data?['name'] ?? '';

                  return Column(
                    children: [

                      GestureDetector(
                        onTap: _pickAndUploadLogo,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: CupertinoColors.systemGrey5,
                          backgroundImage: logoUrl != null
                              ? NetworkImage(logoUrl)
                              : null,
                          child: logoUrl == null
                              ? const Icon(
                            CupertinoIcons.camera,
                            size: 28,
                          )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        businessName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            /// =============================
            /// CUENTA
            /// =============================

            _sectionTitle("Cuenta"),

            _card(
              cardBg,
              child: Column(
                children: [

                  _settingsTile(
                    icon: CupertinoIcons.person,
                    title: "Perfil",
                    subtitle:
                    FirebaseAuth.instance.currentUser?.email ?? "",
                  ),

                  const SizedBox(height: 16),

                  _settingsTile(
                    icon: CupertinoIcons.building_2_fill,
                    title: "Negocio",
                    subtitle: "Mv Snacks Bar",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// =============================
            /// RECURSOS (ANTES FLOTABA)
            /// =============================

            _sectionTitle("Recursos"),

            _card(
              cardBg,
              child: Column(
                children: [

                  _settingsTile(
                    icon: CupertinoIcons.cube_box_fill,
                    title: "snacks_bar",
                    subtitle: "Disponibles: 3",
                  ),

                  const SizedBox(height: 16),

                  _settingsTile(
                    icon: CupertinoIcons.cube_box_fill,
                    title: "elotes_bar",
                    subtitle: "Disponibles: 2",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// =============================
            /// SISTEMA
            /// =============================

            _sectionTitle("Sistema"),

            _card(
              cardBg,
              child: Column(
                children: [

                  _settingsTile(
                    icon: CupertinoIcons.bell,
                    title: "Notificaciones",
                    subtitle: "Próximamente",
                  ),

                  const SizedBox(height: 16),

                  _settingsTile(
                    icon: CupertinoIcons.lock,
                    title: "Privacidad",
                    subtitle: "Próximamente",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            /// LOGOUT

            CupertinoButton(
              color: CupertinoColors.systemRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              onPressed: () => _logout(context),
              child: const Text(
                "Cerrar sesión",
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "Dashboard MV Snacks v1.0",
                style: TextStyle(
                  fontSize: 12,
                  color: secondary,
                ),
              ),
            ),
            const SizedBox(height: 62),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadLogo() async {

    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {

      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((event) async {

        final bytes = reader.result as Uint8List;

        final ref = FirebaseStorage.instance
            .ref('business_logos/${widget.businessId}.jpg');

        await ref.putData(bytes);

        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .update({
          'logoUrl': url,
        });

        setState(() {});
      });
    });
  }

}


  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _card(Color bg, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [

        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.inactiveGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
