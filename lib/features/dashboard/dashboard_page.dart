import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/business_helper.dart';

class DashboardPage extends StatefulWidget {
  final String businessId;
  const DashboardPage({super.key, required this.businessId});

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState
    extends State<DashboardPage> {

  @override
  Widget build(BuildContext context) {
    final businessId = widget.businessId;

        final now = DateTime.now();
        final startMonth =
        DateTime(now.year, now.month, 1);
        final endMonth =
        DateTime(now.year, now.month + 1, 1);

        final todayStart =
        DateTime(now.year, now.month, now.day);
        final todayEnd =
        todayStart.add(const Duration(days: 1));

        return CupertinoPageScaffold(
          backgroundColor:
          const Color(0xFFF2F2F7),

          navigationBar:
          const CupertinoNavigationBar(
            transitionBetweenRoutes: false,
            middle: Text(
              "Dashboard",
              style: TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
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
                  .collection('events')
                  .where('date',
                  isGreaterThanOrEqualTo:
                  startMonth)
                  .where('date',
                  isLessThan:
                  endMonth)
                  .snapshots(),
              builder:
                  (context, snap) {

                if (!snap.hasData) {
                  return const Center(
                    child:
                    CupertinoActivityIndicator(),
                  );
                }

                final events =
                    snap.data!.docs;

                double totalSales = 0;
                double totalPaid = 0;

                int todayCount = 0;
                int upcomingCount = 0;

                for (var doc in events) {
                  final data =
                  doc.data()
                  as Map<String,
                      dynamic>;

                  final price =
                  (data['totalPrice']
                      ?? 0)
                  as num;

                  final paid =
                  (data['totalPaid']
                      ?? 0)
                  as num;

                  totalSales +=
                      price.toDouble();
                  totalPaid +=
                      paid.toDouble();

                  final date =
                  (data['date']
                  as Timestamp)
                      .toDate();

                  if (date
                      .isAfter(
                      todayStart) &&
                      date.isBefore(
                          todayEnd)) {
                    todayCount++;
                  }

                  if (date.isAfter(
                      now)) {
                    upcomingCount++;
                  }
                }

                final pending =
                    totalSales -
                        totalPaid;

                return ListView(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                      16,
                      16,
                      16,
                      120),
                  children: [

                    _sectionTitle(
                        "Finanzas"),

                    _card(
                      "Ingresos del mes",
                      "\$${totalPaid.toStringAsFixed(2)}",
                      CupertinoColors
                          .systemGreen,
                    ),

                    _card(
                      "Ventas totales mes",
                      "\$${totalSales.toStringAsFixed(2)}",
                      CupertinoColors
                          .systemBlue,
                    ),

                    _card(
                      "Pendiente por cobrar",
                      "\$${pending.toStringAsFixed(2)}",
                      CupertinoColors
                          .systemRed,
                    ),

                    const SizedBox(
                        height: 24),

                    _sectionTitle(
                        "Operación"),

                    _card(
                      "Eventos hoy",
                      "$todayCount",
                      CupertinoColors
                          .systemOrange,
                    ),

                    _card(
                      "Próximos eventos",
                      "$upcomingCount",
                      CupertinoColors
                          .systemPurple,
                    ),
                  ],
                );
              },
            ),
          ),
        );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding:
      const EdgeInsets.only(
          bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color:
          CupertinoColors
              .inactiveGray,
        ),
      ),
    );
  }

  Widget _card(
      String title,
      String value,
      Color color) {

    return Container(
      margin:
      const EdgeInsets.only(
          bottom: 14),
      padding:
      const EdgeInsets.all(
          16),
      decoration: BoxDecoration(
        color:
        CupertinoColors.white,
        borderRadius:
        BorderRadius.circular(
            20),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment
            .spaceBetween,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
