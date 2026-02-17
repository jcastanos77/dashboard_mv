import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/business_helper.dart';

class CalendarPage extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final String businessId;

  const CalendarPage({
    super.key,
    required this.onDateSelected,
    required this.businessId
  });

  @override
  State<CalendarPage> createState() =>
      _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {

    final businessId = widget.businessId;

    return Scaffold(
          appBar: AppBar(
            title: const Text("Calendario"),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .doc(businessId)
                .collection('availability')
                .snapshots(),
            builder: (context, snap) {

              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final availabilityDocs = snap.data!.docs;

              return TableCalendar(
                firstDay: DateTime(2023),
                lastDay: DateTime(2035),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    isSameDay(_selectedDay, day),

                onDaySelected: (selectedDay, focusedDay) {
                  if (!mounted) return;

                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  widget.onDateSelected(selectedDay);
                  Navigator.pop(context);
                },

                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {

                    final dateId =
                    DateFormat('yyyy-MM-dd')
                        .format(day);

                    QueryDocumentSnapshot? availabilityDoc;

                    try {
                      availabilityDoc =
                          availabilityDocs.firstWhere(
                                (doc) => doc.id == dateId,
                          );
                    } catch (e) {
                      availabilityDoc = null;
                    }

                    if (availabilityDoc == null) {
                      return null;
                    }

                    final data =
                    availabilityDoc.data()
                    as Map<String, dynamic>;

                    int totalUsed = 0;

                    data.forEach((key, value) {
                      totalUsed += value as int;
                    });

                    Color color;

                    if (totalUsed >= 3) {
                      color = Colors.red;
                    } else if (totalUsed > 0) {
                      color = Colors.orange;
                    } else {
                      color = Colors.green;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text("${day.day}"),
                    );
                  },
                ),
              );
            },
          ),
        );
  }
}
