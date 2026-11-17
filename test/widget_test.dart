import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:petcare/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR', null);
  });

  testWidgets('PetCareApp renders 5 bottom navigation tabs', (tester) async {
    await tester.pumpWidget(const PetCareApp());
    await tester.pumpAndSettle();

    final navBar = find.byType(NavigationBar);
    expect(navBar, findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Início')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Meus Pets')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Agenda')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Saúde')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Perfil')), findsOneWidget);

    await tester.tap(find.descendant(of: navBar, matching: find.text('Meus Pets')));
    await tester.pumpAndSettle();
    expect(find.text('Novo Pet'), findsWidgets);

    await tester.tap(find.descendant(of: navBar, matching: find.text('Perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Perfil e Configurações'), findsOneWidget);
  });
}
