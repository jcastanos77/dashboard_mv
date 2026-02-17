import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/business_helper.dart';
import '../events/create_event_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {

  List<QueryDocumentSnapshot> _events = [];
  Map<DateTime, int> _weeklyCount = {};
  DateTime _weekStart = _startOfWeek(DateTime.now());

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  static DateTime _startOfWeek(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  Future<void> _loadData() async {

    final businessId = await getBusinessId();

    final today = DateTime.now();
    final startToday =
    DateTime(today.year, today.month, today.day);

    final eventsSnap =
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: startToday)
        .orderBy('date')
        .limit(50)
        .get();

    final weekEnd =
    _weekStart.add(const Duration(days: 7));

    final weeklySnap =
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: _weekStart)
        .where('date', isLessThan: weekEnd)
        .get();

    Map<DateTime, int> weeklyMap = {};

    for (var doc in weeklySnap.docs) {
      final date =
      (doc['date'] as Timestamp).toDate();

      final day = DateTime(
          date.year, date.month, date.day);

      weeklyMap[day] =
          (weeklyMap[day] ?? 0) + 1;
    }

    setState(() {
      _events = eventsSnap.docs;
      _weeklyCount = weeklyMap;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final sortedDays = _weeklyCount.keys.toList()..sort();

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
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          "Próximos Eventos",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () async {
            await Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => const CreateEventPage(),
              ),
            );
            setState(() => _loading = true);
            await _loadData();
          },
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
          children: [

            /// SEMANAL
            if (_weeklyCount.isNotEmpty)
              SizedBox(
                height: 95,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: sortedDays.map((day) {

                    final count =
                        _weeklyCount[day] ?? 0;

                    final isToday =
                        DateTime.now().year == day.year &&
                            DateTime.now().month == day.month &&
                            DateTime.now().day == day.day;

                    return Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isToday
                            ? CupertinoColors.activeBlue
                            : cardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Text(
                            DateFormat('E')
                                .format(day)
                                .substring(0, 3)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday
                                  ? CupertinoColors.white
                                  : secondary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? CupertinoColors.white
                                  : label,
                            ),
                          ),

                          if (count > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? CupertinoColors.white.withOpacity(0.25)
                                    : CupertinoColors.systemGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? CupertinoColors.white
                                      : CupertinoColors.systemGreen,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            /// LISTA
            Expanded(
              child: _events.isEmpty
                  ? Center(
                child: Text(
                  "No hay eventos próximos",
                  style: TextStyle(color: secondary),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _events.length,
                itemBuilder: (context, index) {

                  final data =
                  _events[index].data()
                  as Map<String, dynamic>;

                  final total =
                  (data['totalPrice'] ?? 0) as num;

                  final paid =
                  (data['totalPaid'] ?? 0) as num;

                  final remaining =
                      total - paid;

                  final date =
                  (data['date'] as Timestamp).toDate();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          data['clientName'],
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: label,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(date),
                          style: TextStyle(color: secondary),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "📍 ${data['locationName'] ?? ''}",
                          style: TextStyle(color: secondary),
                        ),

                        Text(
                          "🛠 ${data['packageName'] ?? ''}",
                          style: TextStyle(color: secondary),
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            remaining == 0
                                ? "Liquidado"
                                : "Restante \$${remaining.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: remaining == 0
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
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
