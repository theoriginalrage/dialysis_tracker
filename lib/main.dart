import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/setup_screen.dart';
import 'screens/treatments_screen.dart';
import 'camera_smoke_test.dart';
import 'package:flutter/material.dart';

// Entry
void main() => runApp(const DialysisTrackerApp());

class DialysisTrackerApp extends StatelessWidget {
  const DialysisTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _needsOnboarding(),
      builder: (context, snap) {
        // While we’re checking, show an empty scaffold to avoid a flash
        if (!snap.hasData) {
          return const MaterialApp(home: Scaffold(body: SizedBox()));
        }

        return MaterialApp(
          title: 'Dialysis Tracker',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
          ),
          routes: {
            '/home': (_) => const HomeShell(),
          },
          home: snap.data! ? const SetupScreen() : const HomeShell(),
        );
      },
    );
  }
}

Future<bool> _needsOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  // We consider setup done if this flag is true
  return !(prefs.getBool('hasCompletedSetup') ?? false);
}

/// Bottom-nav shell
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// Whenever Setup/Profile saves, we bump this number and pass it down
  /// to TreatmentsPage so it reloads preferences.
  int _refreshToken = 0;

  final List<String> _titles = const ['Treatments', 'Vitals', 'Notes'];

  void _onAdd() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add on ${_titles[_index]} coming soon')),
    );
  }

  Future<void> _openProfile() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );

    if (changed == true) {
      // Something was saved/changed in SetupScreen -> force Treatments to refresh
      setState(() => _refreshToken++);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We build the pages list here so TreatmentsPage gets the latest token.
    final pages = [
      TreatmentsPage(refreshToken: _refreshToken),
      const _PlaceholderPage(icon: Icons.monitor_heart, title: 'Vitals'),
      const _PlaceholderPage(icon: Icons.note_alt, title: 'Notes'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Treatments'),
          NavigationDestination(icon: Icon(Icons.monitor_heart), label: 'Vitals'),
          NavigationDestination(icon: Icon(Icons.note_alt), label: 'Notes'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Temporary placeholders for Vitals / Notes until you wire them up
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  const _PlaceholderPage({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text('$title coming soon'),
        ],
      ),
    );
  }
}

