import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/business_helper.dart';
import '../../models/service_model.dart';
import 'options_page.dart';
import 'packages_page.dart';
import 'service_form_page.dart';

class ServicesPage extends StatefulWidget {
  final String businessId;

  const ServicesPage({
    super.key,
    required this.businessId
  });

  @override
  State<ServicesPage> createState() =>
      _ServicesPageState();
}

class _ServicesPageState
    extends State<ServicesPage> {

  @override
  Widget build(BuildContext context) {
    final businessId = widget.businessId;

        return CupertinoPageScaffold(
          backgroundColor:
          const Color(0xFFF2F2F7),

          navigationBar:
          CupertinoNavigationBar(
            middle: const Text(
              "Servicios",
              style: TextStyle(
                  fontWeight:
                  FontWeight.w600),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                  CupertinoIcons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => ServiceFormPage(businessId: businessId),
                  ),
                );
              },
            ),
          ),

          child: SafeArea(
            child: StreamBuilder<
                QuerySnapshot>(
              stream: FirebaseFirestore
                  .instance
                  .collection(
                  'businesses')
                  .doc(businessId)
                  .collection('services')
                  .snapshots(),
              builder:
                  (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child:
                    CupertinoActivityIndicator(),
                  );
                }

                final services =
                snapshot.data!.docs
                    .map((d) =>
                    ServiceModel
                        .fromMap(
                      d.data()
                      as Map<String,
                          dynamic>,
                      d.id,
                    ))
                    .toList();

                if (services.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay servicios aún",
                      style: TextStyle(
                        color:
                        CupertinoColors
                            .inactiveGray,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                      16,
                      12,
                      16,
                      120),
                  itemCount:
                  services.length,
                  itemBuilder:
                      (context, index) {

                    final service =
                    services[index];

                    return Container(
                      margin:
                      const EdgeInsets
                          .only(
                          bottom:
                          14),
                      padding:
                      const EdgeInsets
                          .all(16),
                      decoration:
                      BoxDecoration(
                        color:
                        CupertinoColors
                            .white,
                        borderRadius:
                        BorderRadius
                            .circular(
                            20),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [

                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [

                                  Text(
                                    service
                                        .name,
                                    style:
                                    const TextStyle(
                                      fontSize:
                                      17,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                    ),
                                  ),

                                  const SizedBox(
                                      height:
                                      4),

                                  Text(
                                    "Capacidad diaria: ${service.dailyCapacity}",
                                    style:
                                    const TextStyle(
                                      color:
                                      CupertinoColors
                                          .inactiveGray,
                                    ),
                                  ),
                                ],
                              ),

                              CupertinoSwitch(
                                value:
                                service
                                    .isActive,
                                onChanged:
                                    (val) {
                                  FirebaseFirestore
                                      .instance
                                      .collection(
                                      'businesses')
                                      .doc(
                                      businessId)
                                      .collection(
                                      'services')
                                      .doc(service
                                      .id)
                                      .update({
                                    'isActive':
                                    val
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(
                              height: 12),

                          CupertinoButton(
                            padding:
                            EdgeInsets.zero,
                            child: const Text(
                              "Administrar",
                              style: TextStyle(
                                color:
                                CupertinoColors
                                    .systemBlue,
                              ),
                            ),
                            onPressed: () {
                              _showActions(
                                  context,
                                  service);
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

  void _showActions(
      BuildContext context,
      ServiceModel service) {

    showCupertinoModalPopup(
      context: context,
      builder: (_) =>
          CupertinoActionSheet(
            title: Text(service.name),
            actions: [

              CupertinoActionSheetAction(
                child: const Text("Paquetes"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) =>
                          PackagesPage(
                            serviceId:
                            service.id,
                            serviceName:
                            service.name,
                            businessId: widget.businessId,
                          ),
                    ),
                  );
                },
              ),

              CupertinoActionSheetAction(
                child: const Text("Opciones"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) =>
                          OptionsPage(
                            serviceId:
                            service.id,
                            serviceName:
                            service.name,
                            businessId: widget.businessId,
                          ),
                    ),
                  );
                },
              ),
            ],
            cancelButton:
            CupertinoActionSheetAction(
              isDefaultAction: true,
              child: const Text("Cancelar"),
              onPressed: () =>
                  Navigator.pop(context),
            ),
          ),
    );
  }
}
