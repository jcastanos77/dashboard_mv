import 'dart:ui';
import 'package:dashboard_mvsnacks/features/admin/services_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../admin/events_page.dart';
import '../dashboard/dashboard_page.dart';
import '../events/availability_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {

  int _currentIndex = 0;

  final List<Widget> _pages = const [
    EventsPage(),
    DashboardPage(),
    AvailabilityPage(),
    ServicesPage(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFFF2F2F7),

      body: Stack(
        children: [

          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: SafeArea(
              child: _AppleNavBar(
                currentIndex:
                _currentIndex,
                onTap: (index) {
                  HapticFeedback
                      .lightImpact();

                  setState(() {
                    _currentIndex =
                        index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleNavBar extends StatelessWidget {

  final int currentIndex;
  final Function(int) onTap;

  const _AppleNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 30,
          sigmaY: 30,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [

              _item(
                CupertinoIcons.calendar,
                0,
              ),

              _item(
                CupertinoIcons.chart_bar,
                1,
              ),

              _item(
                CupertinoIcons.calendar_today,
                2,
              ),

              _item(
                CupertinoIcons.gear,
                3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
      IconData icon, int index) {

    final selected =
        currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding:
        const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withOpacity(0.9)
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected
              ? Colors.black
              : Colors.black54,
        ),
      ),
    );
  }
}

