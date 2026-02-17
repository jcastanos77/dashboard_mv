import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/business_helper.dart';
import '../../models/package_model.dart';
import 'package_form_page.dart';

class PackagesPage extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const PackagesPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<PackagesPage> createState() =>
      _PackagesPageState();
}

class _PackagesPageState
    extends State<PackagesPage> {

  late Future<String> _businessFuture;

  @override
  void initState() {
    super.initState();
    _businessFuture = getBusinessId();
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
            title: Text("Paquetes - ${widget.serviceName}"),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .doc(businessId)
                .collection('services')
                .doc(widget.serviceId)
                .collection('packages')
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final packages = snapshot.data!.docs
                  .map((d) => PackageModel.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id))
                  .toList();

              if (packages.isEmpty) {
                return const Center(
                    child: Text("No hay paquetes"));
              }

              return ListView.builder(
                itemCount: packages.length,
                itemBuilder: (context, index) {

                  final package = packages[index];

                  return ListTile(
                    title: Text(package.name),
                    subtitle: Text(
                        "${package.quantity} personas • \$${package.price}"),
                    trailing: Switch(
                      value: package.isActive,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(businessId)
                            .collection('services')
                            .doc(widget.serviceId)
                            .collection('packages')
                            .doc(package.id)
                            .update({'isActive': val});
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PackageFormPage(
                                serviceId:
                                widget.serviceId,
                                packageModel:
                                package,
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
                      PackageFormPage(
                        serviceId:
                        widget.serviceId,
                      ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
