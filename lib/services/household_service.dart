import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/household.dart';
import '../models/user_model.dart';
import '../config/constants.dart';
import 'dart:math';

class HouseholdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      AppConstants.inviteCodeLength,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<Household> createHousehold({
    required String name,
    required String userId,
  }) async {
    String inviteCode;
    bool codeExists = true;

    // Ensure unique invite code
    do {
      inviteCode = _generateInviteCode();
      final existing = await _firestore
          .collection(AppConstants.householdsCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();
      codeExists = existing.docs.isNotEmpty;
    } while (codeExists);

    final household = Household(
      id: '',
      name: name,
      inviteCode: inviteCode,
      memberIds: [userId],
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    final ref = await _firestore
        .collection(AppConstants.householdsCollection)
        .add(household.toFirestore());

    // Update user's householdId
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'householdId': ref.id});

    final doc = await ref.get();
    return Household.fromFirestore(doc);
  }

  Future<Household> joinHousehold({
    required String inviteCode,
    required String userId,
  }) async {
    final query = await _firestore
        .collection(AppConstants.householdsCollection)
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Ongeldige uitnodigingscode');
    }

    final doc = query.docs.first;
    final household = Household.fromFirestore(doc);

    if (household.memberIds.contains(userId)) {
      // Update user's householdId reference anyway
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'householdId': household.id});
      return household;
    }

    // Add user to household
    await doc.reference.update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    // Update user's householdId
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'householdId': household.id});

    final updatedDoc = await doc.reference.get();
    return Household.fromFirestore(updatedDoc);
  }

  Future<void> leaveHousehold({
    required String householdId,
    required String userId,
  }) async {
    await _firestore
        .collection(AppConstants.householdsCollection)
        .doc(householdId)
        .update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'householdId': null});
  }

  Stream<Household?> householdStream(String householdId) {
    return _firestore
        .collection(AppConstants.householdsCollection)
        .doc(householdId)
        .snapshots()
        .map((doc) => doc.exists ? Household.fromFirestore(doc) : null);
  }

  Future<List<UserModel>> getHouseholdMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];

    final snapshots = await Future.wait(
      memberIds.map((id) => _firestore
          .collection(AppConstants.usersCollection)
          .doc(id)
          .get()),
    );

    return snapshots
        .where((doc) => doc.exists)
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  Future<void> updateHouseholdName({
    required String householdId,
    required String newName,
  }) async {
    await _firestore
        .collection(AppConstants.householdsCollection)
        .doc(householdId)
        .update({'name': newName});
  }

  Future<String> regenerateInviteCode(String householdId) async {
    String inviteCode;
    bool codeExists = true;

    do {
      inviteCode = _generateInviteCode();
      final existing = await _firestore
          .collection(AppConstants.householdsCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();
      codeExists = existing.docs.isNotEmpty;
    } while (codeExists);

    await _firestore
        .collection(AppConstants.householdsCollection)
        .doc(householdId)
        .update({'inviteCode': inviteCode});

    return inviteCode;
  }
}
