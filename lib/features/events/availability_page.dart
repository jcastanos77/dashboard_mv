import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/business_helper.dart';
import '../events/create_event_page.dart';

class AvailabilityPage extends StatefulWidget {
  final String businessId;
  const AvailabilityPage({super.key, required this.businessId});

  @override
  State<AvailabilityPage> createState() =>
      _AvailabilityPageState();
}

class _AvailabilityPageState
    extends State<AvailabilityPage> {

  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  Map<String, int> _availability = {};
  Map<String, String> _serviceNames = {};
  Map<String, int> _serviceCapacity = {};
  List<QueryDocumentSnapshot> _events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {

    setState(() => _loading = true);

    final businessId = widget.businessId;

    if (businessId == null) {
      return;
    }

    final start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day);

    final end =
    start.add(const Duration(days: 1));

    /// EVENTOS DEL DÍA
    final eventsSnap =
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('events')
        .where('date',
        isGreaterThanOrEqualTo: start)
        .where('date',
        isLessThan: end)
        .get();

    /// DISPONIBILIDAD DEL DÍA
    final dateId =
    DateFormat('yyyy-MM-dd')
        .format(_selectedDate);

    final availabilitySnap =
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('availability')
        .doc(dateId)
        .get();

    /// SERVICIOS
    final servicesSnap =
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('services')
        .get();

    final servicesMap = {
      for (var doc in servicesSnap.docs)
        doc.id: doc['name'] as String
    };

    final capacityMap = {
      for (var doc in servicesSnap.docs)
        doc.id:
        (doc['dailyCapacity'] ?? 0)
        as int
    };

    Map<String, int> availabilityMap = {};

    final rawData = availabilitySnap.data();
    if (rawData != null) {
      availabilityMap = rawData.map(
            (key, value) =>
            MapEntry(key, (value as num).toInt()),
      );
    }

    setState(() {
      _events = eventsSnap.docs;
      _availability = availabilityMap;
      _serviceNames = servicesMap;
      _serviceCapacity = capacityMap;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(
      backgroundColor:
      const Color(0xFFF2F2F7),

      navigationBar:
      CupertinoNavigationBar(
        middle: const Text(
          "Disponibilidad",
          style: TextStyle(
              fontWeight:
              FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
              CupertinoIcons.add),
          onPressed: () async {
            await Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) =>
                 CreateEventPage(businessId: widget.businessId,),
              ),
            );
            _loadData();
          },
        ),
      ),

      child: SafeArea(
        child: _loading
            ? const Center(
          child:
          CupertinoActivityIndicator(),
        )
            : ListView(
          padding:
          const EdgeInsets
              .fromLTRB(
              16,
              16,
              16,
              120),
          children: [

            /// SELECTOR PRINCIPAL
            GestureDetector(
              onTap:
              _openFullScreenDatePicker,
              child: Container(
                padding:
                const EdgeInsets
                    .all(18),
                decoration:
                BoxDecoration(
                  color:
                  CupertinoColors
                      .white,
                  borderRadius:
                  BorderRadius
                      .circular(
                      20),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [

                    const Text(
                      "Fecha seleccionada",
                      style:
                      TextStyle(
                        color:
                        CupertinoColors
                            .inactiveGray,
                      ),
                    ),

                    Text(
                      DateFormat(
                          'dd MMM yyyy')
                          .format(
                          _selectedDate),
                      style:
                      const TextStyle(
                        fontSize:
                        17,
                        fontWeight:
                        FontWeight
                            .w600,
                        color:
                        CupertinoColors
                            .systemBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
                height: 14),

            /// CHIPS RÁPIDOS
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection:
                Axis.horizontal,
                children: [

                  _quickChip(
                      "Hoy",
                      DateTime
                          .now()),

                  _quickChip(
                      "Mañana",
                      DateTime.now()
                          .add(
                          const Duration(
                              days:
                              1))),

                  _quickChip(
                      "+7 días",
                      DateTime.now()
                          .add(
                          const Duration(
                              days:
                              7))),

                  _quickChip(
                      "Fin de semana",
                      _nextSaturday()),
                ],
              ),
            ),

            const SizedBox(
                height: 28),

            const Text(
              "Capacidad del día",
              style: TextStyle(
                fontWeight:
                FontWeight.w600,
                color:
                CupertinoColors
                    .inactiveGray,
              ),
            ),

            const SizedBox(
                height: 12),

            ..._serviceNames.entries
                .map((entry) {

              final used =
                  _availability[
                  entry.key] ??
                      0;

              final capacity =
                  _serviceCapacity[
                  entry.key] ??
                      0;

              final available =
                  capacity - used;

              return Container(
                margin:
                const EdgeInsets
                    .only(
                    bottom:
                    12),
                padding:
                const EdgeInsets
                    .all(16),
                decoration:
                BoxDecoration(
                  color:
                  CupertinoColors
                      .white,
                  borderRadius:
                  BorderRadius
                      .circular(
                      20),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [

                    Text(
                        entry.value),

                    Text(
                      available <= 0
                          ? "FULL"
                          : "$available disponibles",
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .w600,
                        color: available >
                            0
                            ? CupertinoColors
                            .systemGreen
                            : CupertinoColors
                            .systemRed,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(
                height: 28),

            const Text(
              "Eventos del día",
              style: TextStyle(
                fontWeight:
                FontWeight.w600,
                color:
                CupertinoColors
                    .inactiveGray,
              ),
            ),

            const SizedBox(
                height: 12),

            if (_events.isEmpty)
              const Text(
                "No hay eventos este día",
                style: TextStyle(
                    color:
                    CupertinoColors
                        .inactiveGray),
              ),

            ..._events.map((doc) {

              final data =
              doc.data() as Map<String, dynamic>;

              final total =
              (data['totalPrice'] ?? 0) as num;

              final paid =
              (data['totalPaid'] ?? 0) as num;

              final remaining =
                  total - paid;

              final date =
              (data['date'] as Timestamp)
                  .toDate();

              return Container(
                margin:
                const EdgeInsets.only(
                    bottom: 12),
                padding:
                const EdgeInsets.all(16),
                decoration:
                BoxDecoration(
                  color:
                  CupertinoColors.white,
                  borderRadius:
                  BorderRadius.circular(
                      20),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    /// CLIENTE
                    Text(
                      data['clientName'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// UBICACIÓN
                    if (data['locationName'] !=
                        null)
                      Text(
                        "📍 ${data['locationName']}",
                        style: const TextStyle(
                          color:
                          CupertinoColors
                              .inactiveGray,
                        ),
                      ),

                    /// PAQUETE
                    if (data['packageName'] !=
                        null)
                      Text(
                        "🛠 ${data['packageName']}",
                        style: const TextStyle(
                          color:
                          CupertinoColors
                              .inactiveGray,
                        ),
                      ),

                    const SizedBox(height: 10),

                    /// ESTADO DE PAGO
                    Align(
                      alignment:
                      Alignment.centerRight,
                      child: Text(
                        remaining <= 0
                            ? "Liquidado"
                            : "Restante \$${remaining.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w600,
                          color: remaining <= 0
                              ? CupertinoColors
                              .systemGreen
                              : CupertinoColors
                              .systemOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          ],
        ),
      ),
    );
  }

  void _openFullScreenDatePicker() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _FullScreenDatePicker(
              initialDate:
              _selectedDate,
              onDateSelected:
                  (date) {
                setState(() {
                  _selectedDate =
                      date;
                });
                _loadData();
              },
            ),
      ),
    );
  }

  Widget _quickChip(
      String label,
      DateTime date) {

    final normalized = DateTime(
        date.year,
        date.month,
        date.day);

    final isSelected =
        normalized ==
            DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate =
              normalized;
        });
        _loadData();
      },
      child: Container(
        margin:
        const EdgeInsets
            .only(right: 10),
        padding:
        const EdgeInsets
            .symmetric(
            horizontal: 14,
            vertical: 8),
        decoration:
        BoxDecoration(
          color: isSelected
              ? CupertinoColors
              .systemBlue
              : CupertinoColors
              .white,
          borderRadius:
          BorderRadius
              .circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? CupertinoColors
                .white
                : CupertinoColors
                .black,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),
    );
  }

  DateTime _nextSaturday() {
    final now = DateTime.now();
    int daysToAdd =
        (6 - now.weekday) % 7;
    if (daysToAdd == 0)
      daysToAdd = 7;
    return now.add(
        Duration(days: daysToAdd));
  }
}

class _FullScreenDatePicker
    extends StatefulWidget {

  final DateTime initialDate;
  final Function(DateTime)
  onDateSelected;

  const _FullScreenDatePicker({
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_FullScreenDatePicker>
  createState() =>
      _FullScreenDatePickerState();
}

class _FullScreenDatePickerState
    extends State<
        _FullScreenDatePicker> {

  late DateTime _tempDate;

  @override
  void initState() {
    super.initState();
    _tempDate =
        widget.initialDate;
  }

  @override
  Widget build(
      BuildContext context) {

    return CupertinoPageScaffold(
      navigationBar:
      CupertinoNavigationBar(
        middle: const Text(
            "Seleccionar fecha"),
        trailing: CupertinoButton(
          padding:
          EdgeInsets.zero,
          child:
          const Text("Listo"),
          onPressed: () {
            widget
                .onDateSelected(
                _tempDate);
            Navigator.pop(
                context);
          },
        ),
      ),
      child: SafeArea(
        child: Center(
          child:
          CupertinoDatePicker(
            mode:
            CupertinoDatePickerMode
                .date,
            initialDateTime:
            _tempDate,
            minimumYear: 2023,
            maximumYear: 2035,
            onDateTimeChanged:
                (date) {
              _tempDate =
                  date;
            },
          ),
        ),
      ),
    );
  }
}
