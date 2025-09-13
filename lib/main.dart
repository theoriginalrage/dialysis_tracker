import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/session_store.dart';
import 'state/settings_store.dart';
import 'screens/today_screen.dart';
import 'screens/history_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/setup_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionStore()..load()),
        ChangeNotifierProvider(create: (_) => SettingsStore()..load()),
      ],
      child: const DialysisApp(),
    ),
  );
}

class DialysisApp extends StatelessWidget {
  const DialysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dialysis Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _Gate(),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();

    // Wait until shared prefs are loaded
    if (!settings.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // After load: either show setup or main tabs
    return settings.onboarded ? const _Root() : const SetupScreen();
  }
}

class _Root extends StatefulWidget {
  const _Root({super.key});
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  int _idx = 0;

  final _screens = const [
    TodayScreen(),
    HistoryScreen(),
    TrendsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_idx]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'History'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Trends'),
        ],
      ),
    );
  }
}

