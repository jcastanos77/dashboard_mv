import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

    final bg = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    final data = widget.eventData;

    final total = (data['totalPrice'] ?? 0) as num;
    final paid = (data['totalPaid'] ?? 0) as num;
    final remaining = total - paid;

    final Timestamp? timestamp = data['date'];
    final DateTime date = timestamp?.toDate() ?? DateTime.now();

    return CupertinoPageScaffold(
      backgroundColor: bg,
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [

            /// CLIENT HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['clientName'] ?? '',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: label,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(
                      color: secondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// FINANCIAL CARD
            /// FINANCIAL BLOCK
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// RESTANTE PROTAGONISTA
                  Text(
                    remaining == 0
                        ? "Liquidado"
                        : "\$${remaining.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: remaining == 0
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.label.resolveFrom(context),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    remaining == 0 ? "Evento pagado" : "Pendiente",
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Divider(
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),

                  const SizedBox(height: 16),

                  _moneyRow("Total", total, label),
                  _moneyRow("Pagado", paid, label),
                ],
              ),
            ),


            const SizedBox(height: 28),

            Text(
              "Pagos",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: label,
              ),
            ),

            const SizedBox(height: 12),

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
                  return Text(
                    "Sin pagos registrados",
                    style: TextStyle(color: secondary),
                  );
                }

                return Column(
                  children: payments.map((doc) {

                    final payment =
                    doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "\$${payment['amount']}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: label,
                            ),
                          ),
                          Text(
                            payment['method'] ?? '',
                            style: TextStyle(color: secondary),
                          ),
                        ],
                      ),
                    );

                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 32),

            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(18),
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

            const SizedBox(height: 14),

            CupertinoButton(
              borderRadius: BorderRadius.circular(18),
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
              child: const Text("Enviar por WhatsApp", style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(String labelText, num value, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            labelText,
            style: TextStyle(
              color: labelColor,
              fontSize: 16,
            ),
          ),
          Text(
            "\$${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
