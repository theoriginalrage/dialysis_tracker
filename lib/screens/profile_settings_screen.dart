import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _photoBytes;
  String _unit = 'kg';
  bool _initialized = false;
  bool _submitted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldsChanged);
    _weightController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldsChanged);
    _weightController.removeListener(_onFieldsChanged);
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final settings = context.read<SettingsStore>();
    _nameController.text = settings.name;
    final weight = settings.startWeight;
    if (weight != null) {
      _weightController.text = _formatWeight(weight);
    }
    _unit = settings.unit;
    _photoBytes = settings.photoBytes;
    _initialized = true;
  }

  String _formatWeight(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  double? get _parsedWeight {
    final raw = _weightController.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  bool get _canSave {
    if (_isSaving) return false;
    final name = _nameController.text.trim();
    final weight = _parsedWeight;
    if (name.isEmpty || weight == null) {
      return false;
    }
    return weight > 0;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick photo')),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _photoBytes = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final weight = _parsedWeight;
    if (weight == null || weight <= 0) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final store = context.read<SettingsStore>();
    try {
      await store.saveProfile(
        name: _nameController.text.trim(),
        startWeight: weight,
        unit: _unit,
        photoBytes: _photoBytes,
      );
      if (!mounted) return;
      if (!widget.isOnboarding) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final title = widget.isOnboarding ? 'Setup' : 'Profile & Settings';
    final buttonLabel = widget.isOnboarding ? 'Save & Continue' : 'Save';
    final avatar = _photoBytes != null ? MemoryImage(_photoBytes!) : null;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: avatar,
                    child: avatar == null
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo),
                        label: const Text('Gallery'),
                      ),
                      if (!kIsWeb)
                        OutlinedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Camera'),
                        ),
                      if (_photoBytes != null)
                        TextButton.icon(
                          onPressed: _isSaving ? null : _removePhoto,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Starting Weight (${_unit.toUpperCase()})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Starting weight is required';
                }
                final parsed = double.tryParse(trimmed);
                if (parsed == null) {
                  return 'Enter a valid number';
                }
                if (parsed <= 0) {
                  return 'Weight must be greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Units', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['kg', 'lbs'].map((unit) {
                return ChoiceChip(
                  label: Text(unit.toUpperCase()),
                  selected: _unit == unit,
                  onSelected: _isSaving
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() {
                              _unit = unit;
                            });
                          }
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: settings.darkMode,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      context.read<SettingsStore>().setDarkMode(value);
                    },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
