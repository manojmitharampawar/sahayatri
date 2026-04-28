import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahayatri/core/auth/auth_service.dart';
import 'package:sahayatri/core/api/api_client.dart';
import 'package:sahayatri/features/yatra_khoj/yatra_khoj_screen.dart';
import 'package:sahayatri/features/samay_suchna/samay_suchna_screen.dart';
import 'package:sahayatri/features/safar_rakshak/safar_rakshak_screen.dart';
import 'package:sahayatri/features/rail_darshan/rail_darshan_screen.dart';
import 'package:sahayatri/features/family/family_group_screen.dart';
import 'package:sahayatri/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SahayatriApp());
}

class SahayatriApp extends StatelessWidget {
  const SahayatriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider<AuthService>(
          create: (ctx) => AuthService(ctx.read<ApiClient>()),
        ),
      ],
      child: MaterialApp(
        title: 'Sahayatri',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const SahayatriHome(),
      ),
    );
  }
}

class SahayatriHome extends StatefulWidget {
  const SahayatriHome({super.key});

  @override
  State<SahayatriHome> createState() => _SahayatriHomeState();
}

class _SahayatriHomeState extends State<SahayatriHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    YatraKhojScreen(),
    SamaySuchnaScreen(),
    SafarRakshakScreen(),
    RailDarshanScreen(),
    FamilyGroupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Colors.teal),
            label: 'Yatra Khoj',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule),
            selectedIcon: Icon(Icons.schedule, color: Colors.teal),
            label: 'Samay Suchna',
          ),
          NavigationDestination(
            icon: Icon(Icons.gps_fixed),
            selectedIcon: Icon(Icons.gps_fixed, color: Colors.teal),
            label: 'Safar Rakshak',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            selectedIcon: Icon(Icons.map, color: Colors.teal),
            label: 'Rail Darshan',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom),
            selectedIcon: Icon(Icons.family_restroom, color: Colors.teal),
            label: 'Family',
          ),
        ],
      ),
    );
  }
}
