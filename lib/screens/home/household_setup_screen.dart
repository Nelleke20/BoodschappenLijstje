import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../utils/validators.dart';

class HouseholdSetupScreen extends ConsumerStatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  ConsumerState<HouseholdSetupScreen> createState() =>
      _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends ConsumerState<HouseholdSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();
  final _householdNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _householdNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    if (!_createFormKey.currentState!.validate()) return;

    final userModel = await ref.read(currentUserModelProvider.future);
    if (userModel == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(householdNotifierProvider.notifier).createHousehold(
            name: _householdNameController.text.trim(),
            userId: userModel.id,
          );
      if (mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aanmaken mislukt: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinHousehold() async {
    if (!_joinFormKey.currentState!.validate()) return;

    final userModel = await ref.read(currentUserModelProvider.future);
    if (userModel == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(householdNotifierProvider.notifier).joinHousehold(
            inviteCode: _inviteCodeController.text.trim(),
            userId: userModel.id,
          );
      if (mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Stel je huishouden in',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maak een nieuw huishouden aan of sluit je aan bij een bestaand huishouden.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Aanmaken'),
                    Tab(text: 'Aansluiten'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Create tab
                    Form(
                      key: _createFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _householdNameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _createHousehold(),
                            validator: (v) =>
                                Validators.required(v, 'Naam huishouden'),
                            decoration: const InputDecoration(
                              labelText: 'Naam van jullie huishouden',
                              hintText: 'bijv. Familie De Vries',
                              prefixIcon: Icon(Icons.home_outlined),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _createHousehold,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Huishouden aanmaken'),
                          ),
                        ],
                      ),
                    ),
                    // Join tab
                    Form(
                      key: _joinFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _inviteCodeController,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _joinHousehold(),
                            maxLength: 6,
                            validator: Validators.inviteCode,
                            decoration: const InputDecoration(
                              labelText: 'Uitnodigingscode',
                              hintText: 'bijv. ABC123',
                              prefixIcon: Icon(Icons.key_outlined),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vraag een huisgenoot om de 6-cijferige uitnodigingscode te delen.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _joinHousehold,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Aansluiten'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Skip option
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Later instellen',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
