import 'package:flutter/cupertino.dart';
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
    required this.businessId,
  });

  @override
  State<OptionsPage> createState() =>
      _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {

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

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        middle: Text("Opciones - ${widget.serviceName}"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => OptionFormPage(
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
              .collection('options')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            final options = snapshot.data!.docs
                .map((d) => OptionModel.fromMap(
                d.data() as Map<String, dynamic>,
                d.id))
                .toList();

            if (options.isEmpty) {
              return Center(
                child: Text(
                  "No hay opciones",
                  style: TextStyle(color: secondary),
                ),
              );
            }

            return ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: options.length,
              itemBuilder: (context, index) {

                final option = options[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => OptionFormPage(
                          serviceId: widget.serviceId,
                          optionModel: option,
                          businessId: widget.businessId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin:
                    const EdgeInsets.only(bottom: 14),
                    padding:
                    const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius:
                      BorderRadius.circular(22),
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
                                option.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.w600,
                                  color: label,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "Extra \$${option.extraCost.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// SWITCH
                        CupertinoSwitch(
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
                      ],
                    ),
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
