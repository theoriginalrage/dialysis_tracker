// lib/screens/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> _ensureMediaPermissions() async {
  // Camera permission
  final cam = await Permission.camera.request();
  // Gallery permission depends on Android version; permission_handler abstracts it
  final photos = await Permission.photos.request(); // maps to READ_MEDIA_IMAGES or READ_EXTERNAL_STORAGE
  return cam.isGranted && photos.isGranted;
}

Future<File?> pickAvatar(BuildContext context) async {
  final granted = await _ensureMediaPermissions();
  if (!granted) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera or Photos permission denied')),
      );
    }
    return null;
  }

  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;

  final picker = ImagePicker();
  final XFile? x = await picker.pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 88,
  );

  if (x == null) return null;
  return File(x.path);
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(); // kg
  final _fluidCtrl = TextEditingController();  // mL

  DateTime? _dob;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30);

  /// Set of selected weekdays (1..7 => Mon..Sun)
  final Set<int> _selectedDays = <int>{};

  bool _loading = true;

  final _dateFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    _nameCtrl.text = prefs.getString('user_name') ?? '';
    _weightCtrl.text = (prefs.getDouble('starting_weight') ?? 0).toStringAsFixed(1);
    final savedMl = prefs.getInt('fluid_limit_ml') ?? 2000;
    _fluidCtrl.text = savedMl.toString();

    final dobStr = prefs.getString('user_dob');
    if (dobStr != null && dobStr.isNotEmpty) {
      try {
        _dob = DateTime.parse(dobStr);
      } catch (_) {}
    }

    // Canonical days list (preferred)
    final list = prefs.getStringList('dialysis_days');
    if (list != null) {
      _selectedDays
        ..clear()
        ..addAll(list.map(int.parse));
    } else {
      // Back-compat: booleans
      if (prefs.getBool('dialysis_mon') ?? false) _selectedDays.add(1);
      if (prefs.getBool('dialysis_tue') ?? false) _selectedDays.add(2);
      if (prefs.getBool('dialysis_wed') ?? false) _selectedDays.add(3);
      if (prefs.getBool('dialysis_thu') ?? false) _selectedDays.add(4);
      if (prefs.getBool('dialysis_fri') ?? false) _selectedDays.add(5);
      if (prefs.getBool('dialysis_sat') ?? false) _selectedDays.add(6);
      if (prefs.getBool('dialysis_sun') ?? false) _selectedDays.add(7);
    }

    // Default if nothing picked yet
    if (_selectedDays.isEmpty) {
      _selectedDays.addAll([1, 3, 5]); // Mon/Wed/Fri
    }

    final startTimeStr = prefs.getString('start_time'); // "HH:mm"
    if (startTimeStr != null) {
      final parts = startTimeStr.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) _startTime = TimeOfDay(hour: h, minute: m);
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final init = _dob ?? DateTime(now.year - 40, now.month, now.day);
    final first = DateTime(now.year - 120, 1, 1);
    final last = DateTime(now.year - 10, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();

    // Parse numbers safely
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    final fluidMl = int.tryParse(_fluidCtrl.text.trim()) ?? 2000;

    await prefs.setString('user_name', _nameCtrl.text.trim());
    await prefs.setDouble('starting_weight', weight);
    await prefs.setInt('fluid_limit_ml', fluidMl);

    if (_dob != null) {
      await prefs.setString('user_dob', _dob!.toIso8601String().split('T').first);
    }

    // Save canonical weekday list
    final list = _selectedDays.toList()..sort();
    await prefs.setStringList('dialysis_days', list.map((e) => e.toString()).toList());

    // Save start time as HH:mm
    final hh = _startTime.hour.toString().padLeft(2, '0');
    final mm = _startTime.minute.toString().padLeft(2, '0');
    await prefs.setString('start_time', '$hh:$mm');

    // Mark onboarding as complete
    await prefs.setBool('hasCompletedSetup', true);

    if (!mounted) return;

    // Tell the previous screen things changed so it can refresh the calendar.
    Navigator.pop(context, true);
  }

  String _weekdayLabel(int w) {
    switch (w) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _fluidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Avatar placeholder (kept simple to avoid extra packages)
          Center(
            child: CircleAvatar(
              radius: 48,
              child: Text(
                (_nameCtrl.text.trim().isEmpty
                        ? '🙂'
                        : _nameCtrl.text.trim().substring(0, 1))
                    .toUpperCase(),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Full name'),
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          const Text('DOB:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _dob == null ? '—' : _dateFmt.format(_dob!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Pick date of birth',
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDob,
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Starting weight (kg)'),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          const Text('Daily fluid limit (mL)'),
          TextField(
            controller: _fluidCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          const Text('Dialysis schedule (days):'),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final w = i + 1; // 1..7
              final selected = _selectedDays.contains(w);
              return FilterChip(
                selected: selected,
                label: Text(_weekdayLabel(w)),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedDays.add(w);
                    } else {
                      _selectedDays.remove(w);
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Start time: ${_startTime.format(context)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Pick start time',
                icon: const Icon(Icons.access_time),
                onPressed: _pickStartTime,
              )
            ],
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saveAndContinue,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Save & continue'),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Note: All data stays on this device.'),
        ],
      ),
    );
  }
}

