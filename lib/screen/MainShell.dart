import 'package:flutter/material.dart';
import 'package:sexpedition_application_1/screen/CalendarScreen.dart';
import 'package:sexpedition_application_1/screen/PartnersScreen.dart';
import 'package:sexpedition_application_1/screen/ProfileScreen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.calendar_month, label: 'Календарь'),
    (icon: Icons.people, label: 'Партнёры'),
    (icon: Icons.person, label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CalendarScreen(),
          PartnersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
