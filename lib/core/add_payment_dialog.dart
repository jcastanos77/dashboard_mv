import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPaymentSheet extends StatefulWidget {
  final String businessId;
  final String eventId;
  final double currentPaid;
  final double totalPrice;

  const AddPaymentSheet({
    super.key,
    required this.businessId,
    required this.eventId,
    required this.currentPaid,
    required this.totalPrice,
  });

  @override
  State<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<AddPaymentSheet> {

  final _controller = TextEditingController();
  String? _error;

  Future<void> _addPayment() async {

    final amount = double.tryParse(_controller.text);

    if (amount == null || amount <= 0) {
      setState(() => _error = "Monto inválido");
      return;
    }

    final newTotal = widget.currentPaid + amount;

    if (newTotal > widget.totalPrice) {
      setState(() => _error = "Excede el total");
      return;
    }

    final db = FirebaseFirestore.instance;

    final eventRef = db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .doc(widget.eventId);

    await db.runTransaction((tx) async {
      tx.update(eventRef, {
        'totalPaid': newTotal,
      });

      tx.set(
        eventRef.collection('payments').doc(),
        {
          'amount': amount,
          'date': FieldValue.serverTimestamp(),
          'method': 'abono',
        },
      );
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    final bg =
    CupertinoColors.systemGroupedBackground.resolveFrom(context);

    return CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// HANDLE
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Text(
                "Nuevo Abono",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              CupertinoTextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                placeholder: "Monto",
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              CupertinoButton.filled(
                onPressed: _addPayment,
                child: const Text("Guardar"),
              ),

              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
