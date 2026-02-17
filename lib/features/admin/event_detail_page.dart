import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/add_payment_dialog.dart';
import '../../core/business_helper.dart';
import '../events/edit_event_page.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EventDetailPage> createState() =>
      _EventDetailPageState();
}

class _EventDetailPageState
    extends State<EventDetailPage> {

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
              body: Center(
                  child:
                  CircularProgressIndicator()));
        }

        final businessId = snapshot.data!;

        final total =
        widget.eventData['totalPrice'];
        final paid =
        widget.eventData['totalPaid'];
        final remaining =
            total - paid;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Detalle Evento"),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditEventPage(
                        eventId: widget.eventId,
                        eventData: widget.eventData,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding:
            const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  widget.eventData[
                  'clientName'],
                  style:
                  const TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight
                          .bold),
                ),

                const SizedBox(height: 10),

                Text(
                    "Fecha: ${DateFormat('dd MMM yyyy').format(widget.eventData['date'].toDate())}"),

                const SizedBox(height: 10),

                Text("Total: \$${total}"),
                Text("Pagado: \$${paid}"),
                Text(
                  "Restante: \$${remaining}",
                  style: TextStyle(
                      color:
                      remaining == 0
                          ? Colors.green
                          : Colors.red),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Pagos",
                  style: TextStyle(
                      fontWeight:
                      FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot>(
                    stream:
                    FirebaseFirestore
                        .instance
                        .collection(
                        'businesses')
                        .doc(businessId)
                        .collection(
                        'events')
                        .doc(widget
                        .eventId)
                        .collection(
                        'payments')
                        .snapshots(),
                    builder:
                        (context, snap) {

                      if (!snap.hasData)
                        return const SizedBox();

                      final payments =
                          snap.data!.docs;

                      return ListView
                          .builder(
                        itemCount:
                        payments
                            .length,
                        itemBuilder:
                            (context,
                            index) {

                          final data =
                          payments[
                          index]
                              .data()
                          as Map<
                              String,
                              dynamic>;

                          return ListTile(
                            title: Text(
                                "\$${data['amount']}"),
                            subtitle: Text(
                                data[
                                'method']),
                          );
                        },
                      );
                    },
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          AddPaymentDialog(
                            businessId:
                            businessId,
                            eventId:
                            widget.eventId,
                            currentPaid:
                            paid,
                            totalPrice:
                            total,
                          ),
                    );
                  },
                  child:
                  const Text("Agregar Abono"),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    final message = """
Hola ${widget.eventData['clientName']} 👋

Detalle de tu evento:

📅 Fecha: ${DateFormat('dd MMM yyyy').format(widget.eventData['date'].toDate())}

💰 Total: \$${total}
💵 Pagado: \$${paid}
🔴 Restante: \$${remaining}

Gracias por confiar en nosotros 🙌
""";

                    final phone =
                    widget.eventData[
                    'phone'];

                    final url =
                        "https://wa.me/52$phone?text=${Uri.encodeComponent(message)}";

                    launchUrl(
                        Uri.parse(url));
                  },
                  child: const Text(
                      "Enviar por WhatsApp"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
