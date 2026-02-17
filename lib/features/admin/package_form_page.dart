import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/package_model.dart';

class PackageFormPage extends StatefulWidget {
  final String serviceId;
  final PackageModel? packageModel;
  final String businessId;

  const PackageFormPage({
    super.key,
    required this.serviceId,
    this.packageModel,
    required this.businessId,
  });

  @override
  State<PackageFormPage> createState() =>
      _PackageFormPageState();
}

class _PackageFormPageState
    extends State<PackageFormPage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.packageModel != null) {
      _nameController.text =
          widget.packageModel!.name;
      _quantityController.text =
          widget.packageModel!.quantity.toString();
      _priceController.text =
          widget.packageModel!.price.toString();
    }
  }

  Future<void> _save() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final data = {
      'name': _nameController.text.trim(),
      'quantity': int.parse(_quantityController.text),
      'price': double.parse(_priceController.text),
      'isActive': true,
    };

    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('services')
        .doc(widget.serviceId)
        .collection('packages');

    if (widget.packageModel == null) {
      await ref.add(data);
    } else {
      await ref
          .doc(widget.packageModel!.id)
          .update(data);
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
          widget.packageModel == null
              ? "Nuevo Paquete"
              : "Editar Paquete",
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
            const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [

              /// FORM CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius:
                  BorderRadius.circular(22),
                ),
                child: Column(
                  children: [

                    _iosField(
                      controller: _nameController,
                      placeholder: "Nombre del paquete",
                      validator: (v) =>
                      v == null || v.isEmpty
                          ? "Requerido"
                          : null,
                    ),

                    const SizedBox(height: 14),

                    _iosField(
                      controller: _quantityController,
                      placeholder:
                      "Cantidad personas / vasos",
                      keyboard:
                      TextInputType.number,
                      validator: (v) =>
                      v == null ||
                          int.tryParse(v) == null
                          ? "Número inválido"
                          : null,
                    ),

                    const SizedBox(height: 14),

                    _iosField(
                      controller: _priceController,
                      placeholder: "Precio",
                      keyboard:
                      TextInputType.number,
                      validator: (v) =>
                      v == null ||
                          double.tryParse(v) ==
                              null
                          ? "Número inválido"
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// SAVE BUTTON
              CupertinoButton.filled(
                onPressed:
                _loading ? null : _save,
                child: _loading
                    ? const CupertinoActivityIndicator(
                  color: CupertinoColors.white,
                )
                    : const Text("Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iosField({
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboard =
        TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return CupertinoTextFormFieldRow(
      controller: controller,
      keyboardType: keyboard,
      placeholder: placeholder,
      padding: const EdgeInsets.symmetric(
          vertical: 14, horizontal: 12),
      style: const TextStyle(fontSize: 15),
      validator: validator,
    );
  }
}
