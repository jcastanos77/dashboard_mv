import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_model.dart';

class ServiceFormPage extends StatefulWidget {
  final ServiceModel? service;
  final String businessId;

  const ServiceFormPage({
    super.key,
    this.service,
    required this.businessId,
  });

  @override
  State<ServiceFormPage> createState() =>
      _ServiceFormPageState();
}

class _ServiceFormPageState
    extends State<ServiceFormPage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _capacityController.text =
          widget.service!.dailyCapacity.toString();
    }
  }

  Future<void> _save() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final name = _nameController.text.trim();
    final capacity =
    int.parse(_capacityController.text.trim());

    final data = {
      'name': name,
      'dailyCapacity': capacity,
      'isActive': true,
    };

    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('services');

    if (widget.service == null) {
      await ref.add(data);
    } else {
      await ref.doc(widget.service!.id).update(data);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    final bg =
    CupertinoColors.systemGroupedBackground
        .resolveFrom(context);

    final cardBg =
    CupertinoColors.secondarySystemGroupedBackground
        .resolveFrom(context);

    final label =
    CupertinoColors.label.resolveFrom(context);

    final secondary =
    CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.service == null
              ? "Nuevo Servicio"
              : "Editar Servicio",
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                /// CARD FORM
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [

                      /// NAME
                      CupertinoTextFormFieldRow(
                        controller: _nameController,
                        placeholder: "Nombre del servicio",
                        style: TextStyle(color: label),
                        validator: (v) =>
                        v == null || v.isEmpty
                            ? "Requerido"
                            : null,
                      ),

                      const SizedBox(height: 16),

                      /// CAPACITY
                      CupertinoTextFormFieldRow(
                        controller: _capacityController,
                        placeholder: "Capacidad diaria",
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: label),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Requerido";
                          }
                          if (int.tryParse(v) == null) {
                            return "Número inválido";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 6),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Cuántos eventos puedes cubrir ese día",
                          style: TextStyle(
                            fontSize: 12,
                            color: secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// SAVE BUTTON
                CupertinoButton.filled(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                      : const Text("Guardar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
