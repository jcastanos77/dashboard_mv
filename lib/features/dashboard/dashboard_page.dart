import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  final String businessId;

  const DashboardPage({
    super.key,
    required this.businessId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _money(num value) => NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  ).format(value);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final nextYearStart = DateTime(now.year + 1, 1, 1);
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final decemberStart = DateTime(now.year, 12, 1);
    final januaryNextYear = DateTime(now.year + 1, 1, 1);
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final eventsQuery = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: yearStart)
        .where('date', isLessThan: nextYearStart);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: eventsQuery.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No se pudieron cargar las finanzas.\n${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snap.hasData) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            double monthSales = 0;
            double monthPaid = 0;
            double yearSales = 0;
            double yearPaid = 0;
            double decemberSales = 0;
            double decemberPaid = 0;
            int decemberEvents = 0;

            int todayCount = 0;
            int upcomingCount = 0;

            for (final doc in snap.data!.docs) {
              final data = doc.data();

              final price = (data['totalPrice'] as num?)?.toDouble() ?? 0;
              final paid = (data['totalPaid'] as num?)?.toDouble() ?? 0;

              final rawDate = data['date'];
              if (rawDate is! Timestamp) continue;

              final date = rawDate.toDate();
              final eventDay = DateTime(date.year, date.month, date.day);

              // Totales de todo el año actual.
              yearSales += price;
              yearPaid += paid;

              // Totales del mes actual.
              if (!eventDay.isBefore(monthStart) &&
                  eventDay.isBefore(nextMonthStart)) {
                monthSales += price;
                monthPaid += paid;
              }

              if (!eventDay.isBefore(decemberStart) &&
                  eventDay.isBefore(januaryNextYear)) {
                decemberSales += price;
                decemberPaid += paid;
                decemberEvents++;
              }

              if (!eventDay.isBefore(todayStart) &&
                  eventDay.isBefore(tomorrowStart)) {
                todayCount++;
              } else if (eventDay.isAfter(todayStart)) {
                upcomingCount++;
              }
            }

            final monthPending = monthSales - monthPaid;
            final yearPending = yearSales - yearPaid;
            final decemberPending = decemberSales - decemberPaid;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _sectionTitle('Finanzas del mes'),
                _card(
                  'Ingresos del mes',
                  _money(monthPaid),
                  CupertinoColors.systemGreen,
                ),
                _card(
                  'Ventas totales del mes',
                  _money(monthSales),
                  CupertinoColors.systemBlue,
                ),
                _card(
                  'Pendiente por cobrar del mes',
                  _money(monthPending),
                  CupertinoColors.systemRed,
                ),

                const SizedBox(height: 18),

                _sectionTitle('Proyección de diciembre ${now.year}'),
                _card(
                  'Ventas de eventos agendados',
                  _money(decemberSales),
                  CupertinoColors.systemBlue,
                ),
                _card(
                  'Ya cobrado de esos eventos',
                  _money(decemberPaid),
                  CupertinoColors.systemGreen,
                ),
                _card(
                  'Pendiente por cobrar',
                  _money(decemberPending),
                  CupertinoColors.systemRed,
                ),
                _card(
                  'Eventos agendados',
                  '$decemberEvents',
                  CupertinoColors.systemPurple,
                ),

                const SizedBox(height: 18),

                _sectionTitle('Finanzas del año ${now.year}'),
                _card(
                  'Ingresos del año',
                  _money(yearPaid),
                  CupertinoColors.systemGreen,
                ),
                _card(
                  'Ventas totales del año',
                  _money(yearSales),
                  CupertinoColors.systemBlue,
                ),
                _card(
                  'Pendiente por cobrar del año',
                  _money(yearPending),
                  CupertinoColors.systemRed,
                ),

                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Los ingresos representan los pagos registrados. '
                        'Para calcular ganancias netas reales, también se deben '
                        'registrar y restar los costos y gastos.',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _sectionTitle('Operación'),
                _card(
                  'Eventos hoy',
                  '$todayCount',
                  CupertinoColors.systemOrange,
                ),
                _card(
                  'Próximos eventos del año',
                  '$upcomingCount',
                  CupertinoColors.systemPurple,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.inactiveGray,
        ),
      ),
    );
  }

  Widget _card(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
