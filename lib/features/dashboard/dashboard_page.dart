
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  int _selectedYear = DateTime.now().year;

  final List<String> _monthNames = const [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  String _money(num value) => NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  ).format(value);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final yearStart = DateTime(_selectedYear, 1, 1);
    final nextYearStart = DateTime(_selectedYear + 1, 1, 1);

    final monthStart = DateTime(_selectedYear, now.month, 1);
    final nextMonthStart = DateTime(
      _selectedYear,
      now.month + 1,
      1,
    );

    final decemberStart = DateTime(_selectedYear, 12, 1);
    final januaryNextYear = DateTime(_selectedYear + 1, 1, 1);

    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final eventsQuery = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .where(
      'date',
      isGreaterThanOrEqualTo: yearStart,
    )
        .where(
      'date',
      isLessThan: nextYearStart,
    );

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

            final monthlySales = List<double>.filled(12, 0);

            for (final doc in snap.data!.docs) {
              final data = doc.data();

              final price =
                  (data['totalPrice'] as num?)?.toDouble() ?? 0;
              final paid =
                  (data['totalPaid'] as num?)?.toDouble() ?? 0;

              final rawDate = data['date'];

              if (rawDate is! Timestamp) continue;

              final date = rawDate.toDate();
              final eventDay = DateTime(
                date.year,
                date.month,
                date.day,
              );

              // Ventas mensuales del año seleccionado.
              monthlySales[date.month - 1] += price;

              // Totales del año seleccionado.
              yearSales += price;
              yearPaid += paid;

              // Totales del mes correspondiente al año seleccionado.
              if (!eventDay.isBefore(monthStart) &&
                  eventDay.isBefore(nextMonthStart)) {
                monthSales += price;
                monthPaid += paid;
              }

              // Proyección de diciembre del año seleccionado.
              if (!eventDay.isBefore(decemberStart) &&
                  eventDay.isBefore(januaryNextYear)) {
                decemberSales += price;
                decemberPaid += paid;
                decemberEvents++;
              }

              // Eventos de hoy y eventos futuros.
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

            final bestMonthIndex = monthlySales.indexOf(
              monthlySales.reduce((a, b) => a > b ? a : b),
            );

            final bestMonthSales = monthlySales[bestMonthIndex];
            final hasSales = monthlySales.any((value) => value > 0);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _yearSelector(),

                _salesChart(monthlySales),

                if (hasSales) ...[
                  _sectionTitle('Mejor mes del año'),
                  _card(
                    'Mes más vendido: ${_monthNames[bestMonthIndex]}',
                    _money(bestMonthSales),
                    CupertinoColors.systemPurple,
                  ),
                  const SizedBox(height: 8),
                ],

                _sectionTitle('Finanzas de ${_monthNames[now.month - 1]}'),
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

                _sectionTitle('Proyección de diciembre $_selectedYear'),
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

                _sectionTitle('Finanzas del año $_selectedYear'),
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
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _sectionTitle('Operación'),
                _card(
                  'Eventos hoy',
                  '${_selectedYear == now.year ? todayCount : 0}',
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

  Widget _yearSelector() {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(
      7,
          (index) => currentYear - 2 + index,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.calendar,
            color: CupertinoColors.systemBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Consultar año',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 36),
            onPressed: () {
              showCupertinoModalPopup<void>(
                context: context,
                builder: (popupContext) {
                  return CupertinoActionSheet(
                    title: const Text('Selecciona un año'),
                    actions: years.map((year) {
                      return CupertinoActionSheetAction(
                        onPressed: () {
                          setState(() {
                            _selectedYear = year;
                          });
                          Navigator.pop(popupContext);
                        },
                        child: Text(
                          year == _selectedYear
                              ? '✓ $year'
                              : '$year',
                        ),
                      );
                    }).toList(),
                    cancelButton: CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.pop(popupContext);
                      },
                      child: const Text('Cancelar'),
                    ),
                  );
                },
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_selectedYear',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 14,
                  color: CupertinoColors.systemBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _salesChart(List<double> monthlySales) {
    final maxSales = monthlySales.fold<double>(
      0,
          (previous, current) =>
      current > previous ? current : previous,
    );

    final chartMaxY = maxSales == 0 ? 100.0 : maxSales * 1.2;
    final interval = chartMaxY / 4;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas por mes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Comparativo de ventas registradas',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (
                        group,
                        groupIndex,
                        rod,
                        rodIndex,
                        ) {
                      return BarTooltipItem(
                        '${_monthNames[group.x]}\n'
                            '${_money(rod.toY)}',
                        const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value >= 1000
                              ? '\$${(value / 1000).toStringAsFixed(0)}k'
                              : '\$${value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= 12) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthNames[index],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  12,
                      (index) {
                    final isBestMonth = hasPositiveSales(monthlySales) &&
                        monthlySales[index] ==
                            monthlySales.reduce(
                                  (a, b) => a > b ? a : b,
                            );

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: monthlySales[index],
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                          color: isBestMonth
                              ? CupertinoColors.systemPurple
                              : CupertinoColors.systemBlue,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ventas mensuales',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemPurple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Mes destacado',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool hasPositiveSales(List<double> sales) {
    return sales.any((value) => value > 0);
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
