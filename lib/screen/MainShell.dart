import 'package:flutter/material.dart';
import 'package:sexpedition_application_1/l10n/app_localizations.dart';
import 'package:sexpedition_application_1/screen/CalendarScreen.dart';
import 'package:sexpedition_application_1/screen/GameScreen.dart';
import 'package:sexpedition_application_1/screen/PartnersScreen.dart';
import 'package:sexpedition_application_1/screen/ProfileScreen.dart';
import 'package:sexpedition_application_1/screen/WishesScreen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = [
      (icon: Icons.calendar_month, label: l.navCalendar),
      (icon: Icons.favorite, label: l.navWishes),
      (icon: Icons.people, label: l.navPartners),
      (icon: Icons.person, label: l.navProfile),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CalendarScreen(),
          WishesScreen(),
          PartnersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 72,
        destinations: tabs
            .map(
              (t) => NavigationDestination(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
        },
        icon: const Icon(Icons.casino),
        label: const Text('Игры'),
      ),
    );
  }
}
