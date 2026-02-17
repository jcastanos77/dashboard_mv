import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _error = "Credenciales inválidas";
      });
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _register() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _error = "No se pudo crear la cuenta";
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const SizedBox(height: 40),

                /// LOGO / TITULO
                const Text(
                  "Dashboard",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Administra tus eventos fácilmente",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.inactiveGray,
                  ),
                ),

                const SizedBox(height: 40),

                /// CARD FORM
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [

                      _inputField(
                        controller: _emailController,
                        placeholder: "Email",
                        icon: CupertinoIcons.mail,
                      ),

                      const SizedBox(height: 14),

                      _inputField(
                        controller: _passController,
                        placeholder: "Password",
                        icon: CupertinoIcons.lock,
                        obscure: true,
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// BOTON LOGIN
                CupertinoButton(
                  borderRadius: BorderRadius.circular(18),
                  color: CupertinoColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                    "Iniciar sesión",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// BOTON REGISTER
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _loading ? null : _register,
                  child: const Text(
                    "Crear cuenta",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [

          Icon(
            icon,
            size: 18,
            color: CupertinoColors.inactiveGray,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
