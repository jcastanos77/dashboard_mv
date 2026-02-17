import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/add_payment_dialog.dart';
import '../events/edit_event_page.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final String businessId;

  const EventDetailPage({
    super.key,
    required this.eventId,
    required this.eventData,
    required this.businessId,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {

  @override
  Widget build(BuildContext context) {

    final data = widget.eventData;

    final total = (data['totalPrice'] ?? 0) as num;
    final paid = (data['totalPaid'] ?? 0) as num;
    final remaining = total - paid;

    final Timestamp? timestamp = data['date'];
    final DateTime date = timestamp?.toDate() ?? DateTime.now();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Detalle Evento"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.pencil),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => EditEventPage(
                  eventId: widget.eventId,
                  eventData: widget.eventData,
                  businessId: widget.businessId,
                ),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [

            /// CLIENT INFO CARD
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['clientName'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: const TextStyle(
                      color: CupertinoColors.inactiveGray,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// FINANCIAL CARD
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _moneyRow("Total", total),
                  _moneyRow("Pagado", paid),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      remaining == 0
                          ? "Liquidado"
                          : "Restante \$${remaining.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: remaining == 0
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// PAYMENTS TITLE
            const Text(
              "Pagos",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            /// PAYMENTS LIST
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('businesses')
                  .doc(widget.businessId)
                  .collection('events')
                  .doc(widget.eventId)
                  .collection('payments')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snap) {

                if (!snap.hasData) {
                  return const CupertinoActivityIndicator();
                }

                final payments = snap.data!.docs;

                if (payments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "Sin pagos registrados",
                      style: TextStyle(
                        color: CupertinoColors.inactiveGray,
                      ),
                    ),
                  );
                }

                return Column(
                  children: payments.map((doc) {

                    final payment =
                    doc.data() as Map<String, dynamic>;

                    return _sectionCard(
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "\$${payment['amount']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            payment['method'] ?? '',
                            style: const TextStyle(
                              color: CupertinoColors.inactiveGray,
                            ),
                          ),
                        ],
                      ),
                    );

                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            /// ACTION BUTTONS
            CupertinoButton.filled(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AddPaymentDialog(
                    businessId: widget.businessId,
                    eventId: widget.eventId,
                    currentPaid: paid.toDouble(),
                    totalPrice: total.toDouble(),
                  ),
                );
              },
              child: const Text("Agregar Abono"),
            ),

            const SizedBox(height: 12),

            CupertinoButton(
              color: CupertinoColors.systemGreen,
              onPressed: () async {

                final phone = data['phone'] ?? '';

                if (phone.isEmpty) return;

                final message = """
Hola ${data['clientName']} 👋

Detalle de tu evento:

📅 Fecha: ${DateFormat('dd MMM yyyy').format(date)}

💰 Total: \$${total}
💵 Pagado: \$${paid}
🔴 Restante: \$${remaining}

Gracias por confiar en nosotros 🙌
""";

                final url =
                    "https://wa.me/52$phone?text=${Uri.encodeComponent(message)}";

                await launchUrl(Uri.parse(url));
              },
              child: const Text("Enviar por WhatsApp"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _moneyRow(String label, num value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "\$${value.toStringAsFixed(0)}",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
