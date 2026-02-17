import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/business_helper.dart';

class EditEventPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EditEventPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EditEventPage> createState() =>
      _EditEventPageState();
}

class _EditEventPageState
    extends State<EditEventPage> {

  late DateTime _selectedDate;
  late Future<String> _businessFuture;

  @override
  void initState() {
    super.initState();

    _selectedDate =
        widget.eventData['date'].toDate();

    _businessFuture = getBusinessId();
  }

  Future<void> _updateEvent(
      String businessId) async {

    final db = FirebaseFirestore.instance;

    final oldDate =
    widget.eventData['date'].toDate();

    final oldDateId =
    DateFormat('yyyy-MM-dd')
        .format(oldDate);

    final newDateId =
    DateFormat('yyyy-MM-dd')
        .format(_selectedDate);

    final serviceId =
    widget.eventData['serviceId'];

    final businessRef =
    db.collection('businesses')
        .doc(businessId);

    final eventRef =
    businessRef.collection('events')
        .doc(widget.eventId);

    final oldAvailabilityRef =
    businessRef.collection('availability')
        .doc(oldDateId);

    final newAvailabilityRef =
    businessRef.collection('availability')
        .doc(newDateId);

    final serviceRef =
    businessRef.collection('services')
        .doc(serviceId);

    await db.runTransaction((tx) async {

      final serviceSnap =
      await tx.get(serviceRef);

      final capacity =
      serviceSnap['dailyCapacity'];

      final newAvailabilitySnap =
      await tx.get(newAvailabilityRef);

      int newCount = 0;

      if (newAvailabilitySnap.exists) {
        newCount =
            newAvailabilitySnap.data()?[
            serviceId] ??
                0;
      }

      if (newCount >= capacity) {
        throw Exception(
            "No hay disponibilidad en la nueva fecha");
      }

      /// 1️⃣ Liberar fecha anterior
      final oldAvailabilitySnap =
      await tx.get(oldAvailabilityRef);

      if (oldAvailabilitySnap.exists) {

        final oldCount =
            oldAvailabilitySnap.data()?[
            serviceId] ??
                0;

        tx.update(oldAvailabilityRef, {
          serviceId: oldCount - 1
        });
      }

      /// 2️⃣ Ocupar nueva fecha
      tx.set(
        newAvailabilityRef,
        {serviceId: newCount + 1},
        SetOptions(merge: true),
      );

      /// 3️⃣ Actualizar evento
      tx.update(eventRef, {
        'date': DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day),
      });
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _businessFuture,
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator()),
          );
        }

        final businessId = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Editar Evento"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                ListTile(
                  title: const Text("Nueva Fecha"),
                  subtitle: Text(
                      DateFormat('dd MMM yyyy')
                          .format(_selectedDate)),
                  trailing: const Icon(
                      Icons.calendar_today),
                  onTap: () async {
                    final picked =
                    await showDatePicker(
                      context: context,
                      initialDate:
                      _selectedDate,
                      firstDate:
                      DateTime(2023),
                      lastDate:
                      DateTime(2035),
                    );

                    if (picked != null) {
                      setState(() {
                        _selectedDate =
                            picked;
                      });
                    }
                  },
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () =>
                      _updateEvent(
                          businessId),
                  child: const Text(
                      "Guardar Cambios"),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
