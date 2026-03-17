import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/template_service.dart';
import '../models/template.dart';
import '../models/shopping_item.dart';

final templateServiceProvider =
    Provider<TemplateService>((ref) => TemplateService());

final customTemplatesProvider =
    StreamProvider.family<List<ShoppingTemplate>, String>(
  (ref, householdId) =>
      ref.watch(templateServiceProvider).customTemplatesStream(householdId),
);

final allTemplatesProvider =
    FutureProvider.family<List<ShoppingTemplate>, String?>(
  (ref, householdId) =>
      ref.watch(templateServiceProvider).getTemplates(householdId),
);

class TemplateNotifier extends StateNotifier<AsyncValue<void>> {
  final TemplateService _service;

  TemplateNotifier(this._service) : super(const AsyncValue.data(null));

  Future<ShoppingTemplate> saveAsTemplate({
    required String householdId,
    required String name,
    required List<ShoppingItem> items,
    required String createdBy,
  }) async {
    return _service.saveAsTemplate(
      householdId: householdId,
      name: name,
      items: items,
      createdBy: createdBy,
    );
  }

  Future<void> deleteTemplate(String templateId) async {
    await _service.deleteTemplate(templateId);
  }
}

final templateNotifierProvider =
    StateNotifierProvider<TemplateNotifier, AsyncValue<void>>((ref) {
  return TemplateNotifier(ref.watch(templateServiceProvider));
});
