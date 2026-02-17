import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/option_model.dart';
import 'option_form_page.dart';

class OptionsPage extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String businessId;

  const OptionsPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.businessId
  });

  @override
  State<OptionsPage> createState() =>
      _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            title: Text("Opciones - ${widget.serviceName}"),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .doc(widget.businessId)
                .collection('services')
                .doc(widget.serviceId)
                .collection('options')
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final options = snapshot.data!.docs
                  .map((d) => OptionModel.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id))
                  .toList();

              if (options.isEmpty) {
                return const Center(
                    child: Text("No hay opciones"));
              }

              return ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {

                  final option = options[index];

                  return ListTile(
                    title: Text(option.name),
                    subtitle: Text(
                        "Extra: \$${option.extraCost}"),
                    trailing: Switch(
                      value: option.isActive,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(widget.businessId)
                            .collection('services')
                            .doc(widget.serviceId)
                            .collection('options')
                            .doc(option.id)
                            .update({'isActive': val});
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OptionFormPage(
                                serviceId:
                                widget.serviceId,
                                optionModel:
                                option,
                                businessId: widget.businessId,
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OptionFormPage(
                        serviceId:
                        widget.serviceId,
                        businessId: widget.businessId,
                      ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
  }
}
