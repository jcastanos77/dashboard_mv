import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/package_model.dart';
import 'package_form_page.dart';

class PackagesPage extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String businessId;

  const PackagesPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.businessId,
  });

  @override
  State<PackagesPage> createState() =>
      _PackagesPageState();
}

class _PackagesPageState
    extends State<PackagesPage> {

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
        middle: Text("Paquetes - ${widget.serviceName}"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) =>
                    PackageFormPage(
                      serviceId: widget.serviceId,
                      businessId: widget.businessId,
                    ),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('businesses')
              .doc(widget.businessId)
              .collection('services')
              .doc(widget.serviceId)
              .collection('packages')
              .orderBy('quantity')
              .snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            final packages = snapshot.data!.docs
                .map((d) => PackageModel.fromMap(
                d.data() as Map<String, dynamic>,
                d.id))
                .toList();

            if (packages.isEmpty) {
              return Center(
                child: Text(
                  "No hay paquetes",
                  style: TextStyle(color: secondary),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: packages.length,
              itemBuilder: (context, index) {

                final package = packages[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [

                      /// INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            Text(
                              package.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: label,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "${package.quantity} personas • \$${package.price}",
                              style: TextStyle(
                                color: secondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// SWITCH
                      CupertinoSwitch(
                        value: package.isActive,
                        onChanged: (val) {
                          FirebaseFirestore.instance
                              .collection('businesses')
                              .doc(widget.businessId)
                              .collection('services')
                              .doc(widget.serviceId)
                              .collection('packages')
                              .doc(package.id)
                              .update({'isActive': val});
                        },
                      ),

                      const SizedBox(width: 8),

                      /// EDIT
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.chevron_right,
                          size: 18,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) =>
                                  PackageFormPage(
                                    serviceId: widget.serviceId,
                                    packageModel: package,
                                    businessId: widget.businessId,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
