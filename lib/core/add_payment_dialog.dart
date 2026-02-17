import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPaymentDialog
    extends StatefulWidget {

  final String businessId;
  final String eventId;
  final double currentPaid;
  final double totalPrice;

  const AddPaymentDialog({
    super.key,
    required this.businessId,
    required this.eventId,
    required this.currentPaid,
    required this.totalPrice,
  });

  @override
  State<AddPaymentDialog> createState() =>
      _AddPaymentDialogState();
}

class _AddPaymentDialogState
    extends State<AddPaymentDialog> {

  final _controller =
  TextEditingController();

  Future<void> _addPayment() async {

    final amount =
    double.parse(_controller.text);

    final newTotal =
        widget.currentPaid + amount;

    if (newTotal >
        widget.totalPrice) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              "Excede el total"),
        ),
      );
      return;
    }

    final db =
        FirebaseFirestore.instance;

    final eventRef = db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .doc(widget.eventId);

    await db.runTransaction(
            (tx) async {

          tx.update(eventRef, {
            'totalPaid': newTotal,
          });

          tx.set(
            eventRef
                .collection('payments')
                .doc(),
            {
              'amount': amount,
              'date':
              FieldValue.serverTimestamp(),
              'method': 'abono',
            },
          );
        });

    Navigator.pop(context);
  }

  @override
  Widget build(
      BuildContext context) {
    return AlertDialog(
      title: const Text("Nuevo Abono"),
      content: TextField(
        controller: _controller,
        keyboardType:
        TextInputType.number,
        decoration:
        const InputDecoration(
            labelText: "Monto"),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _addPayment,
          child:
          const Text("Guardar"),
        ),
      ],
    );
  }
}
