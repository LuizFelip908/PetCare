import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/core/utils/validators.dart';

void main() {
  group('AppValidators', () {
    test('requiredText rejects empty and whitespace strings', () {
      expect(AppValidators.requiredText(null), isNotNull);
      expect(AppValidators.requiredText(''), isNotNull);
      expect(AppValidators.requiredText('   '), isNotNull);
      expect(AppValidators.requiredText('Thor'), isNull);
    });

    test('positiveWeight rejects <= 0 and non-numeric values', () {
      expect(AppValidators.positiveWeight('0'), isNotNull);
      expect(AppValidators.positiveWeight('-2.5'), isNotNull);
      expect(AppValidators.positiveWeight('abc'), isNotNull);
      expect(AppValidators.positiveWeight('250'), isNotNull);
      expect(AppValidators.positiveWeight('12,5'), isNull);
      expect(AppValidators.positiveWeight('4.2'), isNull);
      expect(AppValidators.positiveWeight('', required: false), isNull);
      expect(AppValidators.positiveWeight('', required: true), isNotNull);
    });

    test('validateBirthDate rejects future dates', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final past = DateTime(2021, 5, 10);
      expect(AppValidators.validateBirthDate(tomorrow), isNotNull);
      expect(AppValidators.validateBirthDate(past), isNull);
      expect(AppValidators.validateBirthDate(null), isNull);
    });

    test('validateDateRange rejects end date before start date', () {
      final start = DateTime(2026, 11, 10);
      final before = DateTime(2026, 11, 9);
      final after = DateTime(2026, 11, 15);
      expect(AppValidators.validateDateRange(start, before), isNotNull);
      expect(AppValidators.validateDateRange(start, start), isNull);
      expect(AppValidators.validateDateRange(start, after), isNull);
    });

    test('validateNextDoseDate requires next dose after applied date', () {
      final applied = DateTime(2026, 11, 10);
      expect(AppValidators.validateNextDoseDate(applied, applied), isNotNull);
      expect(
        AppValidators.validateNextDoseDate(
          applied,
          DateTime(2026, 11, 9),
        ),
        isNotNull,
      );
      expect(
        AppValidators.validateNextDoseDate(
          applied,
          DateTime(2027, 11, 10),
        ),
        isNull,
      );
    });

    test('validateMedicationTimes rejects empty schedule list', () {
      expect(AppValidators.validateMedicationTimes([]), isNotNull);
      expect(AppValidators.validateMedicationTimes(['08:00']), isNull);
    });
  });
}

