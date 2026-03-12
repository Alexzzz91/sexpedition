import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            ListTile(
              title: const Text('Email'),
              subtitle: Text(user.email ?? '—'),
            ),
            ListTile(
              title: const Text('Имя'),
              subtitle: Text(user.displayName ?? '—'),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
