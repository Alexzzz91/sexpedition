import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PartnersRepository _partnersRepo = PartnersRepository();

  Future<void> _editName(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать имя'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      await _partnersRepo.updateMyDisplayName(controller.text);
      if (mounted) setState(() {});
    }
  }

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
              subtitle: Text(user.displayName?.isNotEmpty == true ? user.displayName! : '—'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editName(context),
              ),
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
