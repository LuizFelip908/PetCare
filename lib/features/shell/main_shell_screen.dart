import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appointment_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vaccine_provider.dart';
import '../agenda/agenda_screen.dart';
import '../health/health_screen.dart';
import '../home/home_screen.dart';
import '../pets/pets_screen.dart';
import '../profile/profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      context.read<SettingsProvider>().load(),
      context.read<PetProvider>().loadPets(),
      context.read<VaccineProvider>().loadAll(),
      context.read<MedicationProvider>().loadAll(),
      context.read<AppointmentProvider>().loadAll(),
    ]);
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateToTab: _navigateToTab),
      PetsScreen(onNavigateToTab: _navigateToTab),
      const AgendaScreen(),
      const HealthScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded),
            label: 'Meus Pets',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Saúde',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

