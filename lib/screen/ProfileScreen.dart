import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/l10n/app_localizations.dart';
import 'package:sexpedition_application_1/screen/KinkQuizScreen.dart';
import 'package:sexpedition_application_1/screen/PartnersScreen.dart';
import 'package:sexpedition_application_1/services/locale_controller.dart';
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
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
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.25,
                  ),
                  child: Icon(Icons.favorite, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user?.displayName?.isNotEmpty == true
                        ? user!.displayName!
                        : 'Ваш приватный профиль',
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
                subtitle: Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName!
                      : '—',
                ),
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
              leading: const Icon(Icons.language),
              title: Text(l.language),
              subtitle: Text(
                LocaleController.instance.locale == null
                    ? l.languageSystem
                    : supportedAppLanguageNames[LocaleController
                              .instance
                              .locale!
                              .languageCode] ??
                          LocaleController.instance.locale!.languageCode,
              ),
              onTap: () => _showLanguageSheet(context),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.psychology_alt_outlined),
              title: Text(l.kinkQuizTitle),
              subtitle: Text(l.kinkQuizSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const KinkQuizScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people),
              title: Text(l.navPartners),
              subtitle: const Text('Подключения и приглашения партнёров'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PartnersScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
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

  Future<void> _showLanguageSheet(BuildContext context) async {
    final l = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final selectedCode = LocaleController.instance.locale?.languageCode;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(l.languageSystem),
                leading: Icon(
                  selectedCode == null
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                ),
                onTap: () async {
                  await LocaleController.instance.setLocale(null);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              for (final locale in supportedAppLocales)
                ListTile(
                  title: Text(
                    supportedAppLanguageNames[locale.languageCode] ??
                        locale.languageCode,
                  ),
                  leading: Icon(
                    selectedCode == locale.languageCode
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                  ),
                  onTap: () async {
                    await LocaleController.instance.setLocale(locale);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }
}
