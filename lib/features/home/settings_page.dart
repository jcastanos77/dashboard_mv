import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  final String businessId;

  const SettingsPage({
    super.key,
    required this.businessId,
  });

  Future<void> _logout(BuildContext context) async {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
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
    final bg =
    CupertinoColors.systemGroupedBackground.resolveFrom(context);

    final cardBg =
    CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    final label =
    CupertinoColors.label.resolveFrom(context);

    final secondary =
    CupertinoColors.secondaryLabel.resolveFrom(context);

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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [

            /// CUENTA
            _sectionTitle("Cuenta"),

            _card(
              cardBg,
              child: Column(
                children: [

                  _settingsTile(
                    icon: CupertinoIcons.person,
                    title: "Perfil",
                    subtitle: FirebaseAuth.instance.currentUser?.email ?? "",
                  ),

                  const SizedBox(height: 12),

                  _settingsTile(
                    icon: CupertinoIcons.building_2_fill,
                    title: "ID Negocio",
                    subtitle: businessId,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// SISTEMA
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

                  const SizedBox(height: 12),

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
          ],
        ),
      ),
    );
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
}
