import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/template.dart';
import '../models/shopping_item.dart';
import '../config/constants.dart';
class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default templates baked in (no Firestore needed for these)
  static final List<ShoppingTemplate> defaultTemplates = [
    ShoppingTemplate(
      id: 'default_weekboodschappen',
      name: 'Weekboodschappen',
      isDefault: true,
      items: [
        TemplateItem(name: 'Melk', category: 'Zuivel', unit: 'liter'),
        TemplateItem(name: 'Brood', category: 'Brood & Bakkerij'),
        TemplateItem(name: 'Eieren', category: 'Zuivel', unit: 'stuks', quantity: 12),
        TemplateItem(name: 'Boter', category: 'Zuivel'),
        TemplateItem(name: 'Kaas', category: 'Zuivel', unit: 'gram', quantity: 200),
        TemplateItem(name: 'Yoghurt', category: 'Zuivel'),
        TemplateItem(name: 'Fruit', category: 'Groente & Fruit'),
        TemplateItem(name: 'Groenten', category: 'Groente & Fruit'),
        TemplateItem(name: 'Pasta', category: 'Overig'),
        TemplateItem(name: 'Rijst', category: 'Overig', unit: 'kg'),
      ],
    ),
    ShoppingTemplate(
      id: 'default_ontbijt',
      name: 'Ontbijt',
      isDefault: true,
      items: [
        TemplateItem(name: 'Brood', category: 'Brood & Bakkerij'),
        TemplateItem(name: 'Croissants', category: 'Brood & Bakkerij'),
        TemplateItem(name: 'Jam', category: 'Overig'),
        TemplateItem(name: 'Pindakaas', category: 'Overig'),
        TemplateItem(name: 'Hagelslag', category: 'Overig'),
        TemplateItem(name: 'Eieren', category: 'Zuivel', unit: 'stuks', quantity: 6),
        TemplateItem(name: 'Sinaasappelsap', category: 'Dranken', unit: 'liter'),
        TemplateItem(name: 'Koffie', category: 'Dranken'),
        TemplateItem(name: 'Thee', category: 'Dranken'),
      ],
    ),
    ShoppingTemplate(
      id: 'default_bbq',
      name: 'BBQ',
      isDefault: true,
      items: [
        TemplateItem(name: 'Hamburgers', category: 'Vlees & Vis'),
        TemplateItem(name: 'Worstjes', category: 'Vlees & Vis'),
        TemplateItem(name: 'Kippenvleugels', category: 'Vlees & Vis'),
        TemplateItem(name: 'Sla', category: 'Groente & Fruit'),
        TemplateItem(name: 'Tomaten', category: 'Groente & Fruit'),
        TemplateItem(name: 'Uien', category: 'Groente & Fruit'),
        TemplateItem(name: 'Sauzen', category: 'Overig'),
        TemplateItem(name: 'Broodjes', category: 'Brood & Bakkerij'),
        TemplateItem(name: 'Bier', category: 'Dranken', unit: 'blikken', quantity: 6),
        TemplateItem(name: 'Frisdrank', category: 'Dranken', unit: 'liter', quantity: 2),
      ],
    ),
    ShoppingTemplate(
      id: 'default_tussendoortjes',
      name: 'Tussendoortjes',
      isDefault: true,
      items: [
        TemplateItem(name: 'Chips', category: 'Snacks & Snoep', unit: 'zakjes'),
        TemplateItem(name: 'Nootjes', category: 'Snacks & Snoep'),
        TemplateItem(name: 'Koekjes', category: 'Snacks & Snoep'),
        TemplateItem(name: 'Chocolade', category: 'Snacks & Snoep'),
        TemplateItem(name: 'Fruit', category: 'Groente & Fruit'),
        TemplateItem(name: 'Crackers', category: 'Brood & Bakkerij'),
        TemplateItem(name: 'Popcorn', category: 'Snacks & Snoep'),
      ],
    ),
    ShoppingTemplate(
      id: 'default_schoonmaak',
      name: 'Schoonmaak',
      isDefault: true,
      items: [
        TemplateItem(name: 'Allesreiniger', category: 'Huishouden'),
        TemplateItem(name: 'WC-reiniger', category: 'Huishouden'),
        TemplateItem(name: 'Afwasmiddel', category: 'Huishouden'),
        TemplateItem(name: 'Wasmiddel', category: 'Huishouden'),
        TemplateItem(name: 'Schuurspons', category: 'Huishouden', unit: 'stuks', quantity: 3),
        TemplateItem(name: 'Vuilniszakken', category: 'Huishouden'),
        TemplateItem(name: 'Toiletpapier', category: 'Huishouden', unit: 'pakken'),
        TemplateItem(name: 'Keukenpapier', category: 'Huishouden', unit: 'rollen', quantity: 2),
      ],
    ),
  ];

  Future<List<ShoppingTemplate>> getTemplates(String? householdId) async {
    final templates = List<ShoppingTemplate>.from(defaultTemplates);

    if (householdId != null) {
      final snap = await _firestore
          .collection(AppConstants.templatesCollection)
          .where('householdId', isEqualTo: householdId)
          .get();

      final customTemplates = snap.docs
          .map((doc) => ShoppingTemplate.fromFirestore(doc))
          .toList();

      templates.addAll(customTemplates);
    }

    return templates;
  }

  Stream<List<ShoppingTemplate>> customTemplatesStream(String householdId) {
    return _firestore
        .collection(AppConstants.templatesCollection)
        .where('householdId', isEqualTo: householdId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ShoppingTemplate.fromFirestore(doc))
            .toList());
  }

  Future<ShoppingTemplate> saveAsTemplate({
    required String householdId,
    required String name,
    required List<ShoppingItem> items,
    required String createdBy,
  }) async {
    final templateItems = items
        .where((item) => !item.isChecked)
        .map((item) => TemplateItem(
              name: item.name,
              category: item.category,
              quantity: item.quantity,
              unit: item.unit,
            ))
        .toList();

    final template = ShoppingTemplate(
      id: '',
      householdId: householdId,
      name: name,
      items: templateItems,
      isDefault: false,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    final ref = await _firestore
        .collection(AppConstants.templatesCollection)
        .add(template.toFirestore());

    final doc = await ref.get();
    return ShoppingTemplate.fromFirestore(doc);
  }

  Future<void> deleteTemplate(String templateId) async {
    await _firestore
        .collection(AppConstants.templatesCollection)
        .doc(templateId)
        .delete();
  }
}
