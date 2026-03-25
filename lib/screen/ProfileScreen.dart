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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.22),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                  child: Icon(Icons.favorite, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Ваш приватный профиль',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (user != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Email'),
                subtitle: Text(user.email ?? '—'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Имя'),
                subtitle: Text(user.displayName?.isNotEmpty == true ? user.displayName! : '—'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editName(context),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Лицензии визуалов поз'),
              subtitle: const Text('Реестр: docs/kamasutra_assets_licenses.md'),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Лицензии ассетов'),
                    content: const Text(
                      'Полный реестр доступен в файле:\n'
                      'docs/kamasutra_assets_licenses.md',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(),
                        child: const Text('Ок'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
