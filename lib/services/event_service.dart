import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  Future<void> createEventWithPayment({
    required String businessId,
    required DateTime date,
    required String serviceId,
    required double totalPrice,
    required double firstPayment,
    required Map<String, dynamic> eventData,
  }) async {

    if (firstPayment < 500) {
      throw Exception(
          "Se requieren 500 mínimo para apartar");
    }

    final businessRef =
    _db.collection('businesses')
        .doc(businessId);

    final dateId =
    DateFormat('yyyy-MM-dd').format(date);

    final availabilityRef =
    businessRef.collection('availability')
        .doc(dateId);

    final serviceRef =
    businessRef.collection('services')
        .doc(serviceId);

    await _db.runTransaction((transaction) async {

      /// 1️⃣ Leer capacidad real del servicio
      final serviceSnap =
      await transaction.get(serviceRef);

      if (!serviceSnap.exists) {
        throw Exception("Servicio no existe");
      }

      final capacity =
      serviceSnap['dailyCapacity'] as int;

      /// 2️⃣ Leer disponibilidad actual
      final availabilitySnap =
      await transaction.get(availabilityRef);

      int currentCount = 0;

      if (availabilitySnap.exists) {
        currentCount =
        (availabilitySnap.data()?[serviceId] ?? 0) as int;
      }

      if (currentCount >= capacity) {
        throw Exception(
            "No hay disponibilidad ese día");
      }

      /// 3️⃣ Crear evento
      final eventRef =
      businessRef.collection('events').doc();

      transaction.set(eventRef, {
        ...eventData,
        'serviceId': serviceId,
        'date': DateTime(
            date.year, date.month, date.day),
        'totalPrice': totalPrice,
        'totalPaid': firstPayment,
        'status': 'confirmed',
        'createdAt':
        FieldValue.serverTimestamp(),
      });

      /// 4️⃣ Crear pago inicial
      transaction.set(
        eventRef.collection('payments').doc(),
        {
          'amount': firstPayment,
          'date': FieldValue.serverTimestamp(),
          'method': 'anticipo',
        },
      );

      /// 5️⃣ Actualizar disponibilidad
      transaction.set(
        availabilityRef,
        {serviceId: currentCount + 1},
        SetOptions(merge: true),
      );
    });
  }

  Future<void> deleteEvent({
    required String businessId,
    required String eventId,
    required DateTime date,
    required String serviceId,
  }) async {

    final businessRef =
    _db.collection('businesses')
        .doc(businessId);

    final dateId =
    DateFormat('yyyy-MM-dd').format(date);

    final availabilityRef =
    businessRef.collection('availability')
        .doc(dateId);

    final eventRef =
    businessRef.collection('events')
        .doc(eventId);

    await _db.runTransaction((transaction) async {

      final availabilitySnap =
      await transaction.get(availabilityRef);

      if (availabilitySnap.exists) {

        final currentCount =
        (availabilitySnap.data()?[serviceId] ?? 0) as int;

        transaction.update(availabilityRef, {
          serviceId:
          currentCount > 0 ? currentCount - 1 : 0
        });
      }

      transaction.delete(eventRef);
    });
  }

  Future<void> addPayment({
    required String businessId,
    required String eventId,
    required double amount,
    required String method,
  }) async {

    final businessRef =
    _db.collection('businesses')
        .doc(businessId);

    final eventRef =
    businessRef.collection('events')
        .doc(eventId);

    await _db.runTransaction((transaction) async {

      final snapshot =
      await transaction.get(eventRef);

      if (!snapshot.exists) {
        throw Exception("Evento no existe");
      }

      final currentPaid =
      (snapshot.data()?['totalPaid'] ?? 0) as num;

      final totalPrice =
      (snapshot.data()?['totalPrice'] ?? 0) as num;

      final newPaid =
          currentPaid + amount;

      if (newPaid > totalPrice) {
        throw Exception(
            "El pago excede el total");
      }

      /// Actualizar total pagado
      transaction.update(eventRef, {
        'totalPaid': newPaid,
      });

      /// Registrar pago
      transaction.set(
        eventRef.collection('payments').doc(),
        {
          'amount': amount,
          'date': FieldValue.serverTimestamp(),
          'method': method,
        },
      );
    });
  }

  Stream<QuerySnapshot> getEventsByDay({
    required String businessId,
    required DateTime day,
  }) {

    final start =
    DateTime(day.year, day.month, day.day);

    final end =
    start.add(const Duration(days: 1));

    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('events')
        .where('date',
        isGreaterThanOrEqualTo: start)
        .where('date',
        isLessThan: end)
        .snapshots();
  }
}
