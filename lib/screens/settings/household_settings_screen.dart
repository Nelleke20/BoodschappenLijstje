import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../widgets/member_avatar.dart';

class HouseholdSettingsScreen extends ConsumerWidget {
  const HouseholdSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Huishouden'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user?.householdId == null) {
            return _buildNoHousehold(context);
          }

          final householdAsync =
              ref.watch(householdStreamProvider(user!.householdId!));

          return householdAsync.when(
            data: (household) {
              if (household == null) return _buildNoHousehold(context);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Household name card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  household.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${household.memberIds.length} leden',
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
                            onPressed: () => _editHouseholdName(
                                context, ref, household.id, household.name),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Invite code card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.key_rounded,
                                  color: AppTheme.accentColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Uitnodigingscode',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  household.inviteCode,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 6,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded),
                                      tooltip: 'Kopieer',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: household.inviteCode));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Code gekopieerd!'),
                                            duration:
                                                Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share_rounded),
                                      tooltip: 'Deel',
                                      onPressed: () {
                                        Share.share(
                                          'Doe mee met ons huishouden in Boodschappenlijstje! Gebruik de code: ${household.inviteCode}',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Deel deze code met huisgenoten om samen boodschappenlijstjes bij te houden.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _regenerateCode(
                                context, ref, household.id),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Nieuwe code genereren'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Members
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'LEDEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    child: _MembersList(
                      memberIds: household.memberIds,
                      currentUserId: user.id,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Leave button
                  OutlinedButton.icon(
                    onPressed: () =>
                        _leaveHousehold(context, ref, user.id, household.id),
                    icon: const Icon(Icons.exit_to_app_rounded,
                        color: AppTheme.errorColor),
                    label: const Text(
                      'Huishouden verlaten',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fout: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Fout bij laden')),
      ),
    );
  }

  Widget _buildNoHousehold(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Geen huishouden',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/household-setup'),
              child: const Text('Huishouden instellen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editHouseholdName(BuildContext context, WidgetRef ref,
      String householdId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naam wijzigen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Naam huishouden'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(householdServiceProvider)
                    .updateHouseholdName(
                      householdId: householdId,
                      newName: controller.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateCode(
      BuildContext context, WidgetRef ref, String householdId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nieuwe code genereren?'),
        content: const Text(
            'De oude code werkt daarna niet meer. Huisgenoten met de oude code kunnen niet meer aansluiten.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Genereren'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(householdServiceProvider)
          .regenerateInviteCode(householdId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nieuwe code gegenereerd!')),
        );
      }
    }
  }

  Future<void> _leaveHousehold(BuildContext context, WidgetRef ref,
      String userId, String householdId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huishouden verlaten?'),
        content: const Text(
            'Je verlaat het huishouden. Je verliest toegang tot alle boodschappenlijstjes.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verlaten'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(householdNotifierProvider.notifier).leaveHousehold(
            householdId: householdId,
            userId: userId,
          );
      ref.invalidate(currentUserModelProvider);
      if (context.mounted) context.pop();
    }
  }
}

class _MembersList extends ConsumerWidget {
  final List<String> memberIds;
  final String currentUserId;

  const _MembersList({
    required this.memberIds,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(householdMembersProvider(memberIds));

    return membersAsync.when(
      data: (members) => Column(
        children: members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isYou = member.id == currentUserId;

          return Column(
            children: [
              if (index > 0) const Divider(height: 1, indent: 56),
              ListTile(
                leading: MemberAvatar(
                  initials: member.initials,
                  avatarUrl: member.avatarUrl,
                  size: 40,
                ),
                title: Text(
                  isYou ? '${member.displayName} (jij)' : member.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(member.email),
              ),
            ],
          );
        }).toList(),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (_, _) => const ListTile(title: Text('Leden laden mislukt')),
    );
  }
}
