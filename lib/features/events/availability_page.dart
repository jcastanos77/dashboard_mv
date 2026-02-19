import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  Map<String, int> _realAvailability = {};
  Map<String, String> _resourceLabels = {};
  List<QueryDocumentSnapshot> _events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {

    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;

    final start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day);

    final end = start.add(const Duration(days: 1));

    /// EVENTOS DEL DÍA
    final eventsSnap =
    await db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    /// CALCULAR DISPONIBILIDAD REAL
    final real = await _calculateAvailability(_selectedDate);

    if (!mounted) return;

    setState(() {
      _events = eventsSnap.docs;
      _realAvailability = real;
      _loading = false;
    });
  }

  Future<Map<String, int>> _calculateAvailability(DateTime date) async {

    final db = FirebaseFirestore.instance;

    final businessDoc = await db
        .collection('businesses')
        .doc(widget.businessId)
        .get();

    final resources =
    Map<String, dynamic>.from(businessDoc.data()?['resources'] ?? {});

    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    final eventsSnap = await db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: dateStart)
        .where('date', isLessThan: dateEnd)
        .get();

    Map<String, int> used = {};

    for (var doc in eventsSnap.docs) {

      final services =
      List<Map<String, dynamic>>.from(doc['services'] ?? []);

      for (var s in services) {

        String? resourceType = s['resourceType'];

        /// 🔥 Compatibilidad eventos viejos
        if (resourceType == null) {

          final serviceId = s['serviceId'];

          if (serviceId != null) {
            final serviceDoc = await db
                .collection('businesses')
                .doc(widget.businessId)
                .collection('services')
                .doc(serviceId)
                .get();

            resourceType =
            serviceDoc.data()?['resourceType'];
          }
        }

        if (resourceType == null) continue;

        used[resourceType] =
            (used[resourceType] ?? 0) + 1;
      }
    }

    Map<String, int> result = {};

    for (var entry in resources.entries) {

      final total =
          (entry.value as num?)?.toInt() ?? 0;

      final usedCount =
          used[entry.key] ?? 0;

      result[entry.key] = total - usedCount;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: const Text(
          "Disponibilidad",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () async {
            await Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) =>
                    CreateEventPage(businessId: widget.businessId),
              ),
            );
            _loadData();
          },
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [

            /// SELECTOR FECHA
            GestureDetector(
              onTap: _openFullScreenDatePicker,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Fecha seleccionada",
                      style: TextStyle(
                        color: CupertinoColors.inactiveGray,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy')
                          .format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Capacidad del día",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.inactiveGray,
              ),
            ),

            const SizedBox(height: 12),

            ..._realAvailability.entries.map((entry) {

              final available = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [

                    Text(entry.key),

                    Text(
                      available <= 0
                          ? "FULL"
                          : "$available disponibles",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: available > 0
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 28),

            const Text(
              "Eventos del día",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.inactiveGray,
              ),
            ),

            const SizedBox(height: 12),

            if (_events.isEmpty)
              const Text(
                "No hay eventos este día",
                style: TextStyle(
                  color: CupertinoColors.inactiveGray,
                ),
              ),

            ..._events.map((doc) {

              final data =
              doc.data() as Map<String, dynamic>;

              final total =
              (data['totalPrice'] ?? 0) as num;

              final paid =
              (data['totalPaid'] ?? 0) as num;

              final remaining = total - paid;

              final services =
              List<Map<String, dynamic>>.from(data['services'] ?? []);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      data['clientName'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    if ((data['locationName'] ?? '').isNotEmpty)
                      Text(
                        "📍 ${data['locationName']}",
                        style: const TextStyle(
                          color: CupertinoColors.inactiveGray,
                        ),
                      ),

                    const SizedBox(height: 6),

                    /// 🔥 SERVICIOS NUEVO MODELO
                    ...services.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "🎪 ${s['serviceName'] ?? ''} • ${s['packageName'] ?? ''}",
                          style: const TextStyle(
                            color: CupertinoColors.inactiveGray,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        remaining <= 0
                            ? "Liquidado"
                            : "Restante \$${remaining.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: remaining <= 0
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemOrange,
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
              initialDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _loadData();
              },
            ),
      ),
    );
  }
}

class _FullScreenDatePicker extends StatefulWidget {

  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const _FullScreenDatePicker({
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_FullScreenDatePicker>
  createState() => _FullScreenDatePickerState();
}

class _FullScreenDatePickerState
    extends State<_FullScreenDatePicker> {

  late DateTime _tempDate;

  @override
  void initState() {
    super.initState();
    _tempDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: const Text("Seleccionar fecha"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text("Listo"),
          onPressed: () {
            widget.onDateSelected(_tempDate);
            Navigator.pop(context);
          },
        ),
      ),
      child: SafeArea(
        child: Center(
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _tempDate,
            minimumYear: 2023,
            maximumYear: 2035,
            onDateTimeChanged: (date) {
              _tempDate = date;
            },
          ),
        ),
      ),
    );
  }
}
