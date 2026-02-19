import 'package:flutter/material.dart';
import 'package:version/models/goal.dart';

class AddEditGoalSheet extends StatefulWidget {
  const AddEditGoalSheet({
    super.key,
    this.initialGoal,
    required this.onSubmit,
  });

  final Goal? initialGoal;
  final Future<void> Function({
    required String name,
    required String category,
    required double targetAmount,
    required double savedAmount,
    String? emoji,
    String? colorTheme,
    DateTime? deadline,
  }) onSubmit;

  @override
  State<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends State<AddEditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _savedAmountController;

  final categories = const [
    'vacation',
    'emergency',
    'electronics',
    'education',
    'health',
    'home',
    'vehicle',
    'other'
  ];
  final emojis = const ['🎯', '🏖️', '🚗', '🎓', '💻', '🏠', '🩺', '🛍️'];
  final colors = const [
    '#F5A623',
    '#27AE60',
    '#3498DB',
    '#9B59B6',
    '#E67E22',
    '#E74C3C',
    '#1ABC9C',
    '#2C3E50'
  ];

  String _selectedCategory = 'other';
  String _selectedEmoji = '🎯';
  String _selectedColor = '#F5A623';
  DateTime? _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialGoal;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _targetAmountController = TextEditingController(
        text: initial?.targetAmount.toStringAsFixed(2) ?? '');
    _savedAmountController = TextEditingController(
        text: initial?.savedAmount.toStringAsFixed(2) ?? '0.00');
    _selectedCategory = initial?.category ?? 'other';
    _selectedEmoji = initial?.emoji ?? '🎯';
    _selectedColor = initial?.colorTheme ?? '#F5A623';
    _deadline = initial?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _savedAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initialGoal == null ? 'New Goal' : 'Edit Goal';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Goal name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a goal name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    return ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: emojis.map((emoji) {
                    return ChoiceChip(
                      label: Text(emoji),
                      selected: _selectedEmoji == emoji,
                      onSelected: (_) => setState(() => _selectedEmoji = emoji),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Target amount'),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _savedAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Already saved'),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null || amount < 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: colors.map((colorHex) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _parseHexColor(colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == colorHex
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Deadline'),
                  subtitle: Text(_deadline == null
                      ? 'No deadline selected'
                      : _deadline!.toIso8601String().split('T').first),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _deadline ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _deadline = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Goal'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        targetAmount: double.parse(_targetAmountController.text.trim()),
        savedAmount: double.parse(_savedAmountController.text.trim()),
        emoji: _selectedEmoji,
        colorTheme: _selectedColor,
        deadline: _deadline,
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: false).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Color _parseHexColor(String hexColor) {
    final clean = hexColor.replaceAll('#', '');
    final value = int.parse(clean, radix: 16);
    return Color(0xFF000000 | value);
  }
}
