import 'dart:convert';

import 'package:flutter/material.dart';

enum Equipment {
  dumbbells('Dumbbells'),
  bench('Flat bench'),
  band('Resistance band'),
  cable('Cable station'),
  pulldown('Lat pulldown machine'),
  chestPress('Chest press machine'),
  row('Seated row machine'),
  legPress('Leg press machine'),
  legCurl('Leg curl machine'),
  shoulderPress('Shoulder press machine'),
  pullUpBar('Pull-up bar');

  const Equipment(this.label);
  final String label;
}

class NamedEquipment {
  const NamedEquipment(this.name, this.match);

  factory NamedEquipment.fromStorage(String entry) {
    final values = jsonDecode(entry) as List<dynamic>;
    return NamedEquipment(
      values.first as String,
      Equipment.values.asNameMap()[values.last],
    );
  }

  final String name;
  final Equipment? match;

  String toStorage() => jsonEncode([name, match?.name]);
}

class EquipmentPage extends StatelessWidget {
  const EquipmentPage({
    super.key,
    required this.available,
    required this.onChanged,
    required this.named,
    required this.onNamedChanged,
  });

  final Set<Equipment> available;
  final List<NamedEquipment> named;
  final ValueChanged<List<NamedEquipment>>? onNamedChanged;
  final void Function(Equipment, bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final machines = Equipment.values.skip(3);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          'Your gym equipment',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Check what you can use at your gym. Changes save automatically.',
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onNamedChanged == null
                ? null
                : () => _addEquipment(context),
            icon: const Icon(Icons.add),
            label: const Text('Add equipment'),
          ),
        ),
        for (final item in named)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.name),
            subtitle: Text(item.match?.label ?? 'Inventory only'),
            trailing: IconButton(
              tooltip: 'Remove ${item.name}',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onNamedChanged == null
                  ? null
                  : () => onNamedChanged!(
                      named.where((entry) => entry != item).toList(),
                    ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Free weights & accessories',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final item in Equipment.values.take(3)) _checkbox(item),
        const Divider(height: 24),
        Text(
          'Machines & stations',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final item in machines) _checkbox(item),
      ],
    );
  }

  Future<void> _addEquipment(BuildContext context) async {
    final added = await showDialog<NamedEquipment>(
      context: context,
      builder: (_) => _AddEquipmentDialog(named: named),
    );
    if (context.mounted && added != null) {
      onNamedChanged?.call([...named, added]);
    }
  }

  Widget _checkbox(Equipment item) {
    final change = onChanged;
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(item.label),
      value: available.contains(item),
      onChanged: change == null ? null : (checked) => change(item, checked!),
    );
  }
}

class _AddEquipmentDialog extends StatefulWidget {
  const _AddEquipmentDialog({required this.named});

  final List<NamedEquipment> named;

  @override
  State<_AddEquipmentDialog> createState() => _AddEquipmentDialogState();
}

class _AddEquipmentDialogState extends State<_AddEquipmentDialog> {
  final _form = GlobalKey<FormState>();
  String _name = '';
  Equipment? _match;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add equipment'),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Equipment name'),
              onChanged: (value) => _name = value.trim(),
              validator: (_) {
                if (_name.isEmpty) return 'Enter a name.';
                if (widget.named.any(
                  (item) => item.name.toLowerCase() == _name.toLowerCase(),
                )) {
                  return 'That equipment is already in your list.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Equipment>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Exercise match'),
              items: [
                const DropdownMenuItem(child: Text('Inventory only')),
                for (final option in Equipment.values)
                  DropdownMenuItem(value: option, child: Text(option.label)),
              ],
              hint: const Text('Inventory only'),
              onChanged: (match) => _match = match,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, NamedEquipment(_name, _match));
            }
          },
          child: const Text('Save equipment'),
        ),
      ],
    );
  }
}
