import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/business_helper.dart';
import '../../models/package_model.dart';

class PackageFormPage extends StatefulWidget {
  final String serviceId;
  final PackageModel? packageModel;

  const PackageFormPage({
    super.key,
    required this.serviceId,
    this.packageModel,
  });

  @override
  State<PackageFormPage> createState() =>
      _PackageFormPageState();
}

class _PackageFormPageState
    extends State<PackageFormPage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController =
  TextEditingController();
  final _priceController =
  TextEditingController();

  late Future<String> _businessFuture;

  @override
  void initState() {
    super.initState();
    _businessFuture = getBusinessId();

    if (widget.packageModel != null) {
      _nameController.text =
          widget.packageModel!.name;
      _quantityController.text =
          widget.packageModel!.quantity
              .toString();
      _priceController.text =
          widget.packageModel!.price
              .toString();
    }
  }

  Future<void> _save(String businessId) async {

    if (!_formKey.currentState!.validate())
      return;

    final data = {
      'name': _nameController.text.trim(),
      'quantity':
      int.parse(_quantityController.text),
      'price':
      double.parse(_priceController.text),
      'isActive': true,
    };

    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _businessFuture,
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final businessId = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.packageModel == null
                ? "Nuevo Paquete"
                : "Editar Paquete"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: "Nombre"),
                    validator: (v) =>
                    v == null || v.isEmpty
                        ? "Requerido"
                        : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _quantityController,
                    keyboardType:
                    TextInputType.number,
                    decoration: const InputDecoration(
                        labelText:
                        "Cantidad personas/vasos"),
                    validator: (v) =>
                    v == null ||
                        int.tryParse(v) ==
                            null
                        ? "Número inválido"
                        : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                    TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Precio"),
                    validator: (v) =>
                    v == null ||
                        double.tryParse(v) ==
                            null
                        ? "Número inválido"
                        : null,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          _save(businessId),
                      child: const Text("Guardar"),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
