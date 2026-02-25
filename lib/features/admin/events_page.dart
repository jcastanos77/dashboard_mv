import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../events/create_event_page.dart';
import 'event_detail_page.dart';

class EventsPage extends StatefulWidget {
  final String businessId;

  const EventsPage({
    super.key,
    required this.businessId,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventListItem {
  final bool isHeader;
  final DateTime? date;
  final QueryDocumentSnapshot? doc;

  _EventListItem.header(this.date)
      : isHeader = true,
        doc = null;

  _EventListItem.event(this.doc)
      : isHeader = false,
        date = null;
}

class _EventsPageState extends State<EventsPage> {

  final ItemScrollController _itemScrollController =
  ItemScrollController();

  final ItemPositionsListener _itemPositionsListener =
  ItemPositionsListener.create();

  List<QueryDocumentSnapshot> _events = [];
  List<_EventListItem> _flattenedItems = [];

  Map<DateTime, int> _countByDate = {};
  Map<DateTime, int> _indexByDate = {};

  DateTime? _selectedDay;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {

    setState(() => _loading = true);

    final today = DateTime.now();
    final startToday =
    DateTime(today.year, today.month, today.day);

    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: startToday)
        .orderBy('date')
        .get();

    _events = snap.docs;
    _flattenedItems.clear();
    _indexByDate.clear();
    _countByDate.clear();

    DateTime? lastDate;

    for (var doc in _events) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final day = DateTime(date.year, date.month, date.day);

      _countByDate[day] =
          (_countByDate[day] ?? 0) + 1;

      if (lastDate == null || lastDate != day) {
        _indexByDate[day] = _flattenedItems.length;
        _flattenedItems.add(_EventListItem.header(day));
        lastDate = day;
      }

      _flattenedItems.add(_EventListItem.event(doc));
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _deleteEvent(QueryDocumentSnapshot doc) async {

    final db = FirebaseFirestore.instance;

    final data = doc.data() as Map<String, dynamic>;
    final eventDate = (data['date'] as Timestamp).toDate();

    final dateOnly = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    );

    final dateId =
    DateFormat('yyyy-MM-dd').format(dateOnly);

    final businessRef =
    db.collection('businesses').doc(widget.businessId);

    /// 1️⃣ BORRAR EVENTO
    await doc.reference.delete();

    /// 2️⃣ RELEER EVENTOS RESTANTES
    final remainingEvents = await businessRef
        .collection('events')
        .where('date', isEqualTo: dateOnly)
        .get();

    Map<String, int> recalculated = {};

    for (var e in remainingEvents.docs) {

      final services =
      List<Map<String, dynamic>>.from(
          e['services'] ?? []);

      for (var s in services) {
        final type = s['resourceType'];

        recalculated[type] =
            (recalculated[type] ?? 0) + 1;
      }
    }

    /// 3️⃣ ACTUALIZAR AVAILABILITY COMPLETO
    final availabilityRef =
    businessRef.collection('availability').doc(dateId);

    await availabilityRef.set(
      recalculated,
      SetOptions(merge: false),
    );

    await _loadData();
  }

  void _scrollToDate(DateTime day) {

    setState(() {
      _selectedDay = day;
    });

    final index = _indexByDate[day];

    if (index != null) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final sortedDays =
    _countByDate.keys.toList()..sort();

    final bg =
    CupertinoColors.systemGroupedBackground
        .resolveFrom(context);

    final cardBg =
    CupertinoColors.secondarySystemGroupedBackground
        .resolveFrom(context);

    final label =
    CupertinoColors.label.resolveFrom(context);

    final secondary =
    CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          "Eventos Futuros",
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
                    CreateEventPage(
                        businessId: widget.businessId),
              ),
            );
            await _loadData();
          },
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(
          child: CupertinoActivityIndicator(),
        )
            : Column(
          children: [
            SizedBox(height: 16,),
            /// CHIPS DE FECHA
            if (sortedDays.isNotEmpty)
              SizedBox(
                height: 95,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 16),
                  children: sortedDays.map((day) {

                    final count =
                        _countByDate[day] ?? 0;

                    final isSelected =
                        _selectedDay != null &&
                            _selectedDay == day;

                    return GestureDetector(
                      onTap: () =>
                          _scrollToDate(day),
                      child: AnimatedContainer(
                        duration:
                        const Duration(
                            milliseconds: 250),
                        width: 75,
                        margin:
                        const EdgeInsets.only(
                            right: 12),
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors
                              .systemBlue
                              : cardBg,
                          borderRadius:
                          BorderRadius.circular(
                              20),
                        ),
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [

                            Text(
                              DateFormat(
                                  'MMM',
                                  'es')
                                  .format(day)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w600,
                                color: isSelected
                                    ? CupertinoColors
                                    .white
                                    : secondary,
                              ),
                            ),

                            const SizedBox(
                                height: 4),

                            Text(
                              DateFormat(
                                  'd',
                                  'es')
                                  .format(day),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.w700,
                                color: isSelected
                                    ? CupertinoColors
                                    .white
                                    : label,
                              ),
                            ),

                            const SizedBox(
                                height: 6),

                            if (count > 0)
                              Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                  color: isSelected
                                      ? CupertinoColors
                                      .white
                                      : CupertinoColors
                                      .systemGreen,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            SizedBox(height: 16,),
            /// LISTA CON SCROLL PERFECTO
            Expanded(
              child:
              ScrollablePositionedList.builder(
                itemScrollController:
                _itemScrollController,
                itemPositionsListener:
                _itemPositionsListener,
                padding:
                const EdgeInsets.fromLTRB(
                    16, 12, 16, 100),
                itemCount:
                _flattenedItems.length,
                itemBuilder:
                    (context, index) {

                  final item =
                  _flattenedItems[index];

                  if (item.isHeader) {
                    return Padding(
                      padding:
                      const EdgeInsets.only(
                          top: 24,
                          bottom: 8),
                      child: Text(
                        DateFormat(
                            "EEEE d 'de' MMMM yyyy",
                            'es')
                            .format(
                            item.date!),
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.w600,
                          fontSize: 13,
                          color: CupertinoColors
                              .inactiveGray,
                        ),
                      ),
                    );
                  }

                  final doc = item.doc!;
                  final data =
                  doc.data()
                  as Map<String,
                      dynamic>;

                  final total =
                  (data['totalPrice'] ??
                      0)
                  as num;

                  final paid =
                  (data['totalPaid'] ??
                      0)
                  as num;

                  final remaining =
                      total - paid;

                  final services =
                  (data['services'] ??
                      []) as List;

                  return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          CupertinoIcons.delete,
                          color: CupertinoColors.white,
                        ),
                      ),
                      confirmDismiss: (_) async {

                        return await showCupertinoDialog<bool>(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: const Text("Eliminar evento"),
                            content: const Text(
                                "¿Seguro que quieres borrar este evento?"),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text("Cancelar"),
                                onPressed: () =>
                                    Navigator.pop(context, false),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text("Eliminar"),
                                onPressed: () =>
                                    Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await _deleteEvent(doc);
                      },
                      child: GestureDetector(
                        onTap: () async{

                          final result = await Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => EventDetailPage(
                                eventId: doc.id,
                                eventData: data,
                                businessId:
                                widget.businessId,
                              ),
                            ),
                          );

                          if (result == true) {
                            await _loadData();
                          }
                        },
                        child: Container(
                      margin:
                      const EdgeInsets.only(
                          bottom: 14),
                      padding:
                      const EdgeInsets.all(
                          18),
                      decoration:
                      BoxDecoration(
                        color: cardBg,
                        borderRadius:
                        BorderRadius
                            .circular(
                            22),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [

                          Text(
                            data['clientName'] ??
                                '',
                            style:
                            TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight
                                  .w600,
                              color: label,
                            ),
                          ),

                          const SizedBox(
                              height: 6),

                          if ((data['locationName'] ??
                              '')
                              .isNotEmpty)
                            Text(
                              "📍 ${data['locationName']}",
                              style: TextStyle(
                                  color:
                                  secondary),
                            ),

                          const SizedBox(
                              height: 6),

                          ...services.map(
                                  (service) {
                                return Padding(
                                  padding:
                                  const EdgeInsets
                                      .only(
                                      bottom:
                                      4),
                                  child: Text(
                                    "🎪 ${service['serviceName']} • ${service['packageName'] ?? ''}",
                                    style:
                                    TextStyle(
                                      fontSize:
                                      13,
                                      color:
                                      label,
                                    ),
                                  ),
                                );
                              }).toList(),

                          const SizedBox(
                              height: 12),

                          Align(
                            alignment:
                            Alignment
                                .centerRight,
                            child: Text(
                              remaining ==
                                  0
                                  ? "Liquidado"
                                  : "Restante \$${remaining.toStringAsFixed(0)}",
                              style:
                              TextStyle(
                                fontWeight:
                                FontWeight
                                    .w600,
                                color:
                                remaining ==
                                    0
                                    ? CupertinoColors
                                    .systemGreen
                                    : CupertinoColors
                                    .systemOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),)
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
