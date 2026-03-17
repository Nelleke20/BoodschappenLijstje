import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/member_avatar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile section
            if (user != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      MemberAvatar(
                        initials: user.initials,
                        avatarUrl: user.avatarUrl,
                        size: 56,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showEditProfile(context, ref, user.displayName),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // App section
            _SectionLabel(label: 'App'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_outlined),
                    title: const Text('Huishouden'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/household-settings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.list_alt_rounded),
                    title: const Text('Sjablonen'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/templates'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Info section
            _SectionLabel(label: 'Info'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outlined),
                    title: const Text('Over de app'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Account section
            _SectionLabel(label: 'Account'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded,
                    color: AppTheme.errorColor),
                title: const Text(
                  'Uitloggen',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () => _signOut(context, ref),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Fout bij laden')),
      ),
    );
  }

  void _showEditProfile(
      BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naam wijzigen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Naam'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final user =
                    await ref.read(currentUserModelProvider.future);
                if (user != null) {
                  await ref
                      .read(authServiceProvider)
                      .updateUserProfile(
                        userId: user.id,
                        displayName: name,
                      );
                  ref.invalidate(currentUserModelProvider);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Boodschappenlijstje',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.shopping_cart_rounded,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'Een collaborative boodschappenlijstje app voor jullie huishouden.',
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uitloggen?'),
        content: const Text('Weet je zeker dat je wilt uitloggen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Uitloggen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
