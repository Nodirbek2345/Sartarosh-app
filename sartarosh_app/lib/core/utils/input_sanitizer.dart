/// Input sanitization and validation utilities for Sartarosh app security.
class InputSanitizer {
  /// Sanitize general text input - strips dangerous characters
  static String sanitizeText(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[<>{}]'), ''); // Remove brackets
  }

  /// Sanitize and validate phone number
  static String sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+\s\-()]'), '').trim();
  }

  /// Validate phone number format (UZ: 9 digits minimum)
  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 9 && digits.length <= 13;
  }

  /// Validate name (2-50 chars, no special symbols)
  static bool isValidName(String name) {
    if (name.trim().isEmpty || name.trim().length < 2 || name.length > 50) {
      return false;
    }
    return RegExp(
      r"^[a-zA-Zа-яА-ЯёЁ\u0400-\u04FF\s'\-\.]+$",
    ).hasMatch(name.trim());
  }

  /// Validate price (positive integer, reasonable range)
  static bool isValidPrice(String priceStr) {
    final price = int.tryParse(
      priceStr.replaceAll('.', '').replaceAll(' ', ''),
    );
    return price != null && price > 0 && price <= 10000000; // Max 10M so'm
  }

  /// Sanitize for Firestore document fields
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String) {
        return MapEntry(key, sanitizeText(value));
      }
      return MapEntry(key, value);
    });
  }

  /// Rate limiter check - returns true if action is allowed
  static DateTime? _lastAction;
  static bool canPerformAction({
    Duration cooldown = const Duration(seconds: 3),
  }) {
    final now = DateTime.now();
    if (_lastAction != null && now.difference(_lastAction!) < cooldown) {
      return false;
    }
    _lastAction = now;
    return true;
  }
}
