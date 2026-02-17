import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/option_model.dart';

class OptionFormPage extends StatefulWidget {
  final String serviceId;
  final OptionModel? optionModel;
  final String businessId;

  const OptionFormPage({
    super.key,
    required this.serviceId,
    this.optionModel,
    required this.businessId,
  });

  @override
  State<OptionFormPage> createState() =>
      _OptionFormPageState();
}

class _OptionFormPageState extends State<OptionFormPage> {

  final _nameController = TextEditingController();
  final _extraCostController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.optionModel != null) {
      _nameController.text =
          widget.optionModel!.name;
      _extraCostController.text =
          widget.optionModel!.extraCost.toString();
    }
  }

  Future<void> _save() async {

    if (_nameController.text.trim().isEmpty) return;

    final extraCost =
        double.tryParse(_extraCostController.text) ?? 0;

    final data = {
      'name': _nameController.text.trim(),
      'extraCost': extraCost,
      'isActive': true,
    };

    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
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

    if (mounted) Navigator.pop(context);
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
    CupertinoColors.secondaryLabel
        .resolveFrom(context);

    final isEditing =
        widget.optionModel != null;

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          isEditing ? "Editar Opción" : "Nueva Opción",
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding:
          const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [

            /// CARD FORM
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    "Nombre",
                    style: TextStyle(
                      fontSize: 13,
                      color: secondary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: "Ej. Barra premium",
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Costo extra",
                    style: TextStyle(
                      fontSize: 13,
                      color: secondary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  CupertinoTextField(
                    controller: _extraCostController,
                    keyboardType:
                    TextInputType.number,
                    placeholder: "0",
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// SAVE BUTTON
            CupertinoButton.filled(
              onPressed: _save,
              borderRadius:
              BorderRadius.circular(16),
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}
