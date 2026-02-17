import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/business_helper.dart';
import '../../models/service_model.dart';

class ServiceFormPage extends StatefulWidget {
  final ServiceModel? service;

  const ServiceFormPage({super.key, this.service});

  @override
  State<ServiceFormPage> createState() =>
      _ServiceFormPageState();
}

class _ServiceFormPageState
    extends State<ServiceFormPage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();

  late Future<String> _businessFuture;

  @override
  void initState() {
    super.initState();
    _businessFuture = getBusinessId();

    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _capacityController.text =
          widget.service!.dailyCapacity.toString();
    }
  }

  Future<void> _save(String businessId) async {

    if (!_formKey.currentState!.validate()) return;

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
        .doc(businessId)
        .collection('services');

    if (widget.service == null) {
      await ref.add(data);
    } else {
      await ref.doc(widget.service!.id).update(data);
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
            title: Text(widget.service == null
                ? "Nuevo Servicio"
                : "Editar Servicio"),
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
                    controller: _capacityController,
                    keyboardType:
                    TextInputType.number,
                    decoration: const InputDecoration(
                        labelText:
                        "Capacidad diaria"),
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
