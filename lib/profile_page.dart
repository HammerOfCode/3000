import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.preferences,
    required this.onSaved,
  });

  static const storageKey = 'profile.v1';
  final SharedPreferences preferences;
  final VoidCallback onSaved;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _muscle = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.preferences.getString(ProfilePage.storageKey);
    if (saved == null) return;
    final values = jsonDecode(saved) as Map<String, dynamic>;
    _height.text = values['height'] as String;
    _weight.text = values['weight'] as String;
    _muscle.text = values['muscle'] as String;
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _muscle.dispose();
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _positive(String? value) {
    final number = _number(value ?? '');
    return number != null && number.isFinite && number > 0
        ? null
        : 'Enter a positive number.';
  }

  String? _validateMuscle(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final error = _positive(value);
    if (error != null) return error;
    final weight = _number(_weight.text);
    if (weight != null && _number(value)! > weight) {
      return 'Enter a value at or below your weight.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    var saved = false;
    try {
      saved = await widget.preferences.setString(
        ProfilePage.storageKey,
        jsonEncode({
          'height': _height.text.trim(),
          'weight': _weight.text.trim(),
          'muscle': _muscle.text.trim(),
        }),
      );
    } on Exception {
      // Leave the form editable so the user can retry.
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile. Try again.'),
        ),
      );
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    FormFieldValidator<String> validator,
  ) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your measurements',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Your profile is saved on this device.'),
          const SizedBox(height: 24),
          _field(_height, 'Height (cm)', _positive),
          const SizedBox(height: 16),
          _field(_weight, 'Weight (kg)', _positive),
          const SizedBox(height: 24),
          _field(
            _muscle,
            'Skeletal muscle mass (kg, optional)',
            _validateMuscle,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter a reading from a body composition assessment if you have one. Height and weight alone cannot determine muscle mass.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}
