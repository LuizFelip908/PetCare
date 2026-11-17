import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/main_shell_screen.dart';
import 'providers/appointment_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/vaccine_provider.dart';
import 'providers/weight_provider.dart';

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => VaccineProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => WeightProvider()),
      ],
      child: MaterialApp(
        title: 'PetCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainShellScreen(),
      ),
    );
  }
}

