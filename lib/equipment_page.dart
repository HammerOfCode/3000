import 'dart:convert';

import 'package:flutter/material.dart';

import 'commons_photos.dart';
import 'machine_detail_page.dart';
import 'machine_media.dart';
import 'repdb_assets.dart';
import 'repdb_image.dart';

enum EquipmentGroup {
  freeWeights('Free weights & accessories'),
  machines('Machines & stations');

  const EquipmentGroup(this.label);
  final String label;
}

enum Equipment {
  dumbbells(
    'Dumbbells',
    group: EquipmentGroup.freeWeights,
    photo: CommonsPhoto.dumbbells,
  ),
  bench(
    'Flat bench',
    group: EquipmentGroup.freeWeights,
    photo: CommonsPhoto.bench,
  ),
  band(
    'Resistance band',
    group: EquipmentGroup.freeWeights,
    photo: CommonsPhoto.band,
  ),
  cable(
    'Cable station',
    aliases: ['cable crossover', 'functional trainer'],
    photo: CommonsPhoto.cableStation,
  ),
  pulldown('Lat pulldown machine', photo: CommonsPhoto.latPulldown),
  chestPress('Chest press machine', photo: CommonsPhoto.chestPress),
  row('Seated row machine'),
  legPress(
    'Leg press machine',
    photo: CommonsPhoto.legPressMachine,
    // TODO: Replace the demo with a licensed model of an actual leg press.
    media: MachineMedia(
      model3dUrl: 'assets/models/leg_press_demo.glb',
      hotspots: [
        MachineHotspot(
          label: 'Foot plate',
          position: '0m 0.98m 0.52m',
          normal: '0m 0m 1m',
          description: 'The foot plate moves with the sled.',
        ),
      ],
    ),
  ),
  legCurl('Leg curl machine', photo: CommonsPhoto.lyingLegCurl),
  shoulderPress('Shoulder press machine', photo: CommonsPhoto.shoulderPress),
  pullUpBar('Pull-up bar', photo: CommonsPhoto.pullUpBar),
  hackSquat('Hack squat machine', photo: CommonsPhoto.hackSquat),
  legExtension('Leg extension machine', photo: CommonsPhoto.legExtension),
  seatedLegCurl('Seated leg curl machine'),
  pecDeck(
    'Pec deck machine',
    aliases: ['chest fly', 'butterfly'],
    photo: CommonsPhoto.pecDeck,
  ),
  assistedPullUp('Assisted pull-up machine', aliases: ['assisted chin-up']),
  abCrunch('Ab crunch machine', aliases: ['abdominal crunch']),
  rearDeltFly('Rear delt fly machine', aliases: ['reverse fly']),
  bicepsCurl('Biceps curl machine', aliases: ['preacher curl']),
  tricepsExtension('Triceps extension machine'),
  smithMachine('Smith machine');

  const Equipment(
    this.label, {
    this.group = EquipmentGroup.machines,
    this.aliases = const [],
    this.photo,
    this.media = const MachineMedia(),
  });
  final String label;
  final EquipmentGroup group;
  final List<String> aliases;
  final CommonsPhoto? photo;
  final MachineMedia media;

  String? get posterUrl =>
      media.posterUrl ?? repDbAsset('equipment', repDbEquipmentImages[name]);

  bool matches(String query) =>
      label.toLowerCase().contains(query) ||
      aliases.any((alias) => alias.contains(query));
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

class EquipmentPage extends StatefulWidget {
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
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  String _query = '';
  bool _myGym = false;

  @override
  Widget build(BuildContext context) {
    final catalog = Equipment.values.where(
      (item) =>
          (!_myGym || widget.available.contains(item)) && item.matches(_query),
    );
    final named = widget.named.where(
      (item) =>
          item.name.toLowerCase().contains(_query) ||
          (item.match?.matches(_query) ?? false),
    );
    final styles = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text('Equipment catalog', style: styles.headlineSmall),
        const SizedBox(height: 8),
        const Text('Check what your gym has to use it in your workouts.'),
        const SizedBox(height: 12),
        TextField(
          onChanged: (text) =>
              setState(() => _query = text.trim().toLowerCase()),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search machines or gear',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: const Text('My gym'),
              selected: _myGym,
              onSelected: (selected) => setState(() => _myGym = selected),
            ),
            OutlinedButton.icon(
              onPressed: widget.onNamedChanged == null ? null : _addEquipment,
              icon: const Icon(Icons.add),
              label: const Text('Add equipment'),
            ),
          ],
        ),
        if (catalog.isEmpty && named.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _query.isEmpty
                  ? 'No saved equipment yet.'
                  : 'No equipment matches your search.',
            ),
          ),
        if (named.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Custom equipment', style: styles.titleMedium),
        ],
        for (final item in named)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.name),
            subtitle: Text(item.match?.label ?? 'Inventory only'),
            trailing: IconButton(
              tooltip: 'Remove ${item.name}',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: widget.onNamedChanged == null
                  ? null
                  : () => widget.onNamedChanged!(
                      widget.named.where((entry) => entry != item).toList(),
                    ),
            ),
          ),
        for (final group in EquipmentGroup.values)
          if (catalog.any((item) => item.group == group)) ...[
            const SizedBox(height: 16),
            Text(group.label, style: styles.titleMedium),
            for (final item in catalog.where((item) => item.group == group))
              _checkbox(item),
          ],
      ],
    );
  }

  Future<void> _addEquipment() async {
    final added = await showDialog<NamedEquipment>(
      context: context,
      builder: (_) => _AddEquipmentDialog(named: widget.named),
    );
    if (mounted && added != null) {
      widget.onNamedChanged?.call([...widget.named, added]);
    }
  }

  Widget _checkbox(Equipment item) {
    final change = widget.onChanged;
    final photo = item.photo;
    final poster = item.posterUrl;
    return Row(
      children: [
        Expanded(
          child: RepDbImageChoice(
            asset: poster,
            builder: (context, bundledPoster) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(item.label),
              secondary: bundledPoster != null
                  ? Image.asset(
                      bundledPoster,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      cacheWidth: 160,
                      excludeFromSemantics: true,
                    )
                  : photo == null
                  ? null
                  : CommonsThumbnail(photo, size: 48),
              value: widget.available.contains(item),
              onChanged: change == null
                  ? null
                  : (checked) => change(item, checked!),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'View ${item.label} details',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MachineDetailPage(equipment: item),
            ),
          ),
        ),
      ],
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
