import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/business_helper.dart';
import '../../models/option_model.dart';

class OptionFormPage extends StatefulWidget {
  final String serviceId;
  final OptionModel? optionModel;

  const OptionFormPage({
    super.key,
    required this.serviceId,
    this.optionModel,
  });

  @override
  State<OptionFormPage> createState() =>
      _OptionFormPageState();
}

class _OptionFormPageState
    extends State<OptionFormPage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _extraCostController =
  TextEditingController();

  late Future<String> _businessFuture;

  @override
  void initState() {
    super.initState();
    _businessFuture = getBusinessId();

    if (widget.optionModel != null) {
      _nameController.text =
          widget.optionModel!.name;
      _extraCostController.text =
          widget.optionModel!.extraCost
              .toString();
    }
  }

  Future<void> _save(String businessId) async {

    if (!_formKey.currentState!.validate())
      return;

    final data = {
      'name': _nameController.text.trim(),
      'extraCost':
      double.parse(_extraCostController.text),
      'isActive': true,
    };

    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('services')
        .doc(widget.serviceId)
        .collection('options');

    if (widget.optionModel == null) {
      await ref.add(data);
    } else {
      await ref
          .doc(widget.optionModel!.id)
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
            title: Text(widget.optionModel == null
                ? "Nueva Opción"
                : "Editar Opción"),
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
                    controller: _extraCostController,
                    keyboardType:
                    TextInputType.number,
                    decoration: const InputDecoration(
                        labelText:
                        "Costo extra (0 si no aplica)"),
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
