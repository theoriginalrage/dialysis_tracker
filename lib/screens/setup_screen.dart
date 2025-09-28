import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../state/settings_store.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  WeightUnit _unit = WeightUnit.kg;
  String? _photoPath;
  bool _isValid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_handleFormChange);
    _weightCtrl.addListener(_handleFormChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<SettingsStore>().profile;
      if (profile != null) {
        _nameCtrl.text = profile.name;
        _weightCtrl.text = _formatWeight(profile.startWeight);
        setState(() {
          _unit = profile.unit;
          _photoPath = profile.photoPath;
        });
      }
      _updateValidity();
    });
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_handleFormChange);
    _weightCtrl.removeListener(_handleFormChange);
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _handleFormChange() {
    _updateValidity();
  }

  void _updateValidity() {
    final name = _nameCtrl.text.trim();
    final weightText = _weightCtrl.text.trim();
    final weight = double.tryParse(weightText);
    final valid = name.isNotEmpty && weight != null && weight > 0;
    if (_isValid != valid) {
      setState(() {
        _isValid = valid;
      });
    }
  }

  String _formatWeight(double weight) {
    if (weight % 1 == 0) {
      return weight.toStringAsFixed(0);
    }
    return weight.toString();
  }

  Future<void> _pickPhoto() async {
    final theme = Theme.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _photoPath = picked.path;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _updateValidity();
      return;
    }

    setState(() {
      _saving = true;
    });

    final name = _nameCtrl.text.trim();
    final startWeight = double.parse(_weightCtrl.text.trim());
    final profile = UserProfile(
      name: name,
      photoPath: _photoPath,
      startWeight: startWeight,
      unit: _unit,
    );

    await context.read<SettingsStore>().saveProfile(profile);

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final avatarImage = _photoPath != null ? FileImage(File(_photoPath!)) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: colorScheme.surfaceVariant,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          Material(
                            shape: const CircleBorder(),
                            color: colorScheme.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              color: colorScheme.onPrimary,
                              tooltip: _photoPath == null
                                  ? 'Add photo'
                                  : 'Change photo',
                              onPressed: _pickPhoto,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _pickPhoto,
                        child: Text(_photoPath == null ? 'Add photo' : 'Change photo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightCtrl,
                  decoration: InputDecoration(
                    labelText: 'Starting weight (${_unit.displayLabel}) *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Enter your starting weight';
                    }
                    final weight = double.tryParse(text);
                    if (weight == null || weight <= 0) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('kg'),
                        selected: _unit == WeightUnit.kg,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _unit = WeightUnit.kg;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('lbs'),
                        selected: _unit == WeightUnit.lb,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _unit = WeightUnit.lb;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isValid && !_saving ? _saveAndContinue : null,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save & Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
