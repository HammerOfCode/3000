import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'commons_photos.dart';
import 'equipment_page.dart';
import 'profile_page.dart';
import 'workout_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GymReadyApp(preferences: await SharedPreferences.getInstance()));
}

class GymReadyApp extends StatelessWidget {
  const GymReadyApp({super.key, required this.preferences});
  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xff374448),
      primary: const Color(0xff303b3e),
      surface: const Color(0xfff7f7f4),
    );
    return MaterialApp(
      title: '3000',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colors,
        scaffoldBackgroundColor: colors.surface,
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _LoginPage(preferences: preferences),
    );
  }
}

class _LoginPage extends StatefulWidget {
  const _LoginPage({required this.preferences});
  final SharedPreferences preferences;

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  void _signIn() {
    if (_id.text.trim() != 'user' || _password.text != 'user') {
      setState(() => _error = 'Use the demo ID and password.');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _GymHome(preferences: widget.preferences),
      ),
    );
  }

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '3000',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Plan a workout around the equipment you have.'),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _id,
                      decoration: const InputDecoration(labelText: 'User ID'),
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      onFieldSubmitted: (_) => _signIn(),
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          error,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _signIn,
                      child: const Text('Sign in'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Demo ID and password are both user.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GymHome extends StatefulWidget {
  const _GymHome({required this.preferences});
  final SharedPreferences preferences;

  @override
  State<_GymHome> createState() => _GymHomeState();
}

class _GymHomeState extends State<_GymHome> {
  late int _selected = widget.preferences.containsKey(ProfilePage.storageKey)
      ? 0
      : 2;

  static const _equipmentKey = 'equipment.v1';
  static const _namedKey = 'equipment.named.v1';
  late List<NamedEquipment> _namedEquipment =
      (widget.preferences.getStringList(_namedKey) ?? [])
          .map(NamedEquipment.fromStorage)
          .toList();
  late Set<Equipment> _equipment = Equipment.values
      .where(
        (item) => (widget.preferences.getStringList(_equipmentKey) ?? [])
            .contains(item.name),
      )
      .toSet();
  bool _savingEquipment = false;

  Future<void> _setAvailable(Equipment item, bool checked) async {
    final next = {..._equipment};
    if (checked) {
      next.add(item);
    } else {
      next.remove(item);
    }
    await _saveEquipment(
      _equipmentKey,
      next.map((entry) => entry.name).toList(),
      () => _equipment = next,
    );
  }

  Future<void> _setNamed(List<NamedEquipment> next) => _saveEquipment(
    _namedKey,
    next.map((item) => item.toStorage()).toList(),
    () => _namedEquipment = next,
  );

  Future<void> _saveEquipment(
    String key,
    List<String> entries,
    VoidCallback onSaved,
  ) async {
    setState(() => _savingEquipment = true);
    var saved = false;
    try {
      saved = await widget.preferences.setStringList(key, entries);
    } on Exception {
      // Preserve the previous selection and let the user retry.
    }
    if (!mounted) return;
    setState(() {
      _savingEquipment = false;
      if (saved) onSaved();
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your equipment. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3000'),
        actions: [
          IconButton(
            tooltip: 'Photo credits',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PhotoCreditsPage()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selected,
        children: [
          WorkoutPage(
            available: {
              ..._equipment,
              ..._namedEquipment.map((item) => item.match).nonNulls,
            },
          ),
          EquipmentPage(
            available: _equipment,
            named: _namedEquipment,
            onNamedChanged: _savingEquipment ? null : _setNamed,
            onChanged: _savingEquipment ? null : _setAvailable,
          ),
          ProfilePage(
            preferences: widget.preferences,
            onSaved: () => setState(() => _selected = 0),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Equipment',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
