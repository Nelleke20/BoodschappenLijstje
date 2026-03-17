import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/household_service.dart';
import '../models/household.dart';
import '../models/user_model.dart';

final householdServiceProvider =
    Provider<HouseholdService>((ref) => HouseholdService());

final householdStreamProvider = StreamProvider.family<Household?, String>(
  (ref, householdId) =>
      ref.watch(householdServiceProvider).householdStream(householdId),
);

final householdMembersProvider =
    FutureProvider.family<List<UserModel>, List<String>>(
  (ref, memberIds) =>
      ref.watch(householdServiceProvider).getHouseholdMembers(memberIds),
);

class HouseholdNotifier extends StateNotifier<AsyncValue<Household?>> {
  final HouseholdService _service;

  HouseholdNotifier(this._service) : super(const AsyncValue.data(null));

  Future<Household> createHousehold({
    required String name,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final household = await _service.createHousehold(
        name: name,
        userId: userId,
      );
      state = AsyncValue.data(household);
      return household;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Household> joinHousehold({
    required String inviteCode,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final household = await _service.joinHousehold(
        inviteCode: inviteCode,
        userId: userId,
      );
      state = AsyncValue.data(household);
      return household;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> leaveHousehold({
    required String householdId,
    required String userId,
  }) async {
    await _service.leaveHousehold(
      householdId: householdId,
      userId: userId,
    );
    state = const AsyncValue.data(null);
  }
}

final householdNotifierProvider =
    StateNotifierProvider<HouseholdNotifier, AsyncValue<Household?>>((ref) {
  return HouseholdNotifier(ref.watch(householdServiceProvider));
});
