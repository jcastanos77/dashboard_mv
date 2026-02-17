import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditEventPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final String businessId;

  const EditEventPage({
    super.key,
    required this.eventId,
    required this.eventData,
    required this.businessId,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {

  late DateTime _selectedDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.eventData['date'].toDate();
  }

  Future<void> _updateEvent() async {

    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;

    final oldDate = widget.eventData['date'].toDate();
    final oldDateId = DateFormat('yyyy-MM-dd').format(oldDate);
    final newDateId = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final serviceId = widget.eventData['serviceId'];

    final businessRef =
    db.collection('businesses').doc(widget.businessId);

    final eventRef =
    businessRef.collection('events').doc(widget.eventId);

    final oldAvailabilityRef =
    businessRef.collection('availability').doc(oldDateId);

    final newAvailabilityRef =
    businessRef.collection('availability').doc(newDateId);

    final serviceRef =
    businessRef.collection('services').doc(serviceId);

    await db.runTransaction((tx) async {

      final serviceSnap = await tx.get(serviceRef);
      final capacity = serviceSnap['dailyCapacity'];

      final newAvailabilitySnap =
      await tx.get(newAvailabilityRef);

      int newCount = 0;

      if (newAvailabilitySnap.exists) {
        newCount =
            newAvailabilitySnap.data()?[serviceId] ?? 0;
      }

      if (newCount >= capacity) {
        throw Exception("No hay disponibilidad en la nueva fecha");
      }

      /// Liberar fecha anterior
      final oldAvailabilitySnap =
      await tx.get(oldAvailabilityRef);

      if (oldAvailabilitySnap.exists) {

        final oldCount =
            oldAvailabilitySnap.data()?[serviceId] ?? 0;

        tx.update(oldAvailabilityRef, {
          serviceId: oldCount - 1
        });
      }

      /// Ocupar nueva fecha
      tx.set(
        newAvailabilityRef,
        {serviceId: newCount + 1},
        SetOptions(merge: true),
      );

      /// Actualizar evento
      tx.update(eventRef, {
        'date': DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
      });
    });

    setState(() => _loading = false);
    Navigator.pop(context);
  }

  void _openDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [

            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime(2023),
                maximumDate: DateTime(2035),
                onDateTimeChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),

            CupertinoButton(
              child: const Text("Listo"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final bg =
    CupertinoColors.systemGroupedBackground.resolveFrom(context);

    final cardBg =
    CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    final label =
    CupertinoColors.label.resolveFrom(context);

    final secondary =
    CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: const CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text("Editar Evento"),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [

            /// DATE CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: GestureDetector(
                onTap: _openDatePicker,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Fecha del evento",
                      style: TextStyle(
                        fontSize: 13,
                        color: secondary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      DateFormat('dd MMM yyyy')
                          .format(_selectedDate),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: label,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// SAVE BUTTON
            CupertinoButton.filled(
              onPressed: _loading ? null : _updateEvent,
              child: _loading
                  ? const CupertinoActivityIndicator(
                color: CupertinoColors.white,
              )
                  : const Text("Guardar Cambios"),
            ),
          ],
        ),
      ),
    );
  }
}
