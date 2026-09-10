import 'package:flutter_test/flutter_test.dart';
import 'package:index_care_app/core/utils/account_deletion_helper.dart';
import 'package:index_care_app/core/utils/validators.dart';
import 'package:index_care_app/core/widgets/dynamic_phone_field.dart';

void main() {
  group('Dynamic Phone Validation Tests', () {
    test('Validates required phone number', () {
      expect(Validators.validatePhone(null), 'Phone number is required');
      expect(Validators.validatePhone(''), 'Phone number is required');
      expect(Validators.validatePhone('   '), 'Phone number is required');
    });

    test('Validates 10-digit Indian phone numbers (+91)', () {
      expect(Validators.validatePhone('9876543210', '+91'), isNull);
      expect(Validators.validatePhone('987654321', '+91'), 'Please enter a valid 10-digit phone number');
      expect(Validators.validatePhone('98765432101', '+91'), 'Please enter a valid 10-digit phone number');
      expect(Validators.validatePhone('abcdefghij', '+91'), 'Please enter a valid 10-digit phone number');
    });

    test('Maintains backwards compatibility with default parameter', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('987654321'), 'Please enter a valid 10-digit phone number');
    });

    test('Validates international phone numbers', () {
      // US (+1)
      expect(Validators.validatePhone('2025550123', '+1'), isNull);
      // UK (+44)
      expect(Validators.validatePhone('7911123456', '+44'), isNull);
      // UAE (+971)
      expect(Validators.validatePhone('501234567', '+971'), isNull);
      // Too short
      expect(Validators.validatePhone('12345', '+1'), 'Please enter a valid phone number');
      // Too long (>15)
      expect(Validators.validatePhone('1234567890123456', '+1'), 'Please enter a valid phone number');
    });
  });

  group('AccountDeletionHelper Tests', () {
    test('Builds URL with index_care app parameter', () {
      final url = AccountDeletionHelper.buildDeletionUrl();
      expect(url, contains('app=index_care'));
      expect(url, contains('https://indexinformatics.in/account_deletion.php'));
    });

    test('Builds URL with 10-digit phone number', () {
      final url = AccountDeletionHelper.buildDeletionUrl(phone: '9876543210');
      expect(url, contains('app=index_care'));
      expect(url, contains('phone=9876543210'));
    });

    test('Sanitizes +91 country prefix for web deletion form', () {
      final url = AccountDeletionHelper.buildDeletionUrl(phone: '+919876543210');
      expect(url, contains('app=index_care'));
      expect(url, contains('phone=9876543210'));
    });

    test('Leaves non-Indian numbers cleanly formatted', () {
      final url = AccountDeletionHelper.buildDeletionUrl(phone: '+12025550123');
      expect(url, contains('app=index_care'));
      expect(url, contains('phone=12025550123'));
    });
  });

  group('DynamicPhoneField Country Model Tests', () {
    test('Finds India as default country for +91', () {
      final country = DynamicPhoneField.getCountryByDialCode('+91');
      expect(country.name, 'India');
      expect(country.dialCode, '+91');
      expect(country.maxLength, 10);
      expect(country.flag, '🇮🇳');
    });

    test('Finds other countries correctly', () {
      final us = DynamicPhoneField.getCountryByDialCode('+1');
      expect(us.code, 'US');
      expect(us.flag, '🇺🇸');

      final uae = DynamicPhoneField.getCountryByDialCode('+971');
      expect(uae.name, 'United Arab Emirates');
      expect(uae.flag, '🇦🇪');
    });

    test('Falls back to default country if unknown dial code provided', () {
      final fallback = DynamicPhoneField.getCountryByDialCode('+99999');
      expect(fallback.dialCode, '+91');
    });
  });
}
