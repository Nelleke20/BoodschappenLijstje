import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/shopping_item.dart';
import '../../utils/category_helper.dart';
import '../../utils/validators.dart';

class AddItemSheet extends StatefulWidget {
  final ShoppingItem? existingItem;
  final void Function({
    required String name,
    required double quantity,
    required String unit,
    required String category,
    String? notes,
  }) onSave;

  const AddItemSheet({
    super.key,
    this.existingItem,
    required this.onSave,
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _selectedUnit = 'stuks';
  String _selectedCategory = 'Overig';

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _quantityController.text = item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString()
          : item.quantity.toString();
      _selectedUnit = item.unit;
      _selectedCategory = item.category;
      _notesController.text = item.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _autoDetectCategory(String name) {
    if (name.isNotEmpty) {
      final detected = CategoryHelper.detectCategory(name);
      setState(() => _selectedCategory = detected);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    widget.onSave(
      name: _nameController.text.trim(),
      quantity: quantity,
      unit: _selectedUnit,
      category: _selectedCategory,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEditing ? 'Product wijzigen' : 'Product toevoegen',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Name field
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'Naam'),
              onChanged: _autoDetectCategory,
              decoration: const InputDecoration(
                labelText: 'Naam',
                hintText: 'bijv. Melk',
                prefixIcon: Icon(Icons.shopping_basket_outlined),
              ),
            ),
            const SizedBox(height: 12),
            // Quantity + unit row
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Hoeveelheid',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Eenheid'),
                    items: AppConstants.units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categorie',
                prefixIcon: Icon(
                  AppTheme.getCategoryIcon(_selectedCategory),
                  color: AppTheme.getCategoryColor(_selectedCategory),
                ),
              ),
              items: AppConstants.categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(
                              AppTheme.getCategoryIcon(c),
                              size: 16,
                              color: AppTheme.getCategoryColor(c),
                            ),
                            const SizedBox(width: 8),
                            Text(c),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            // Notes
            TextFormField(
              controller: _notesController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Notitie (optioneel)',
                hintText: 'bijv. zonder lactose',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? 'Opslaan' : 'Toevoegen'),
            ),
          ],
        ),
      ),
    );
  }
}
