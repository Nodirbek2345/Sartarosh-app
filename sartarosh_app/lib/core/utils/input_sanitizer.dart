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

  /// Validate time format (HH:mm)
  static bool isValidTimeFormat(String time) {
    if (time.length != 5) return false;
    final parts = time.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  /// Validate date format (yyyy-MM-dd)
  static bool isValidDateFormat(String date) {
    if (date.length != 10) return false;
    try {
      final parsed = DateTime.parse(date);
      // Ensure it round-trips correctly (catches invalid dates like 2024-02-30)
      final formatted =
          '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      return formatted == date;
    } catch (_) {
      return false;
    }
  }

  /// Validate GPS coordinates
  static bool isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Validate file size (in bytes) — returns true if within limit
  static bool isValidFileSize(int sizeBytes, {int maxMB = 5}) {
    return sizeBytes > 0 && sizeBytes <= maxMB * 1024 * 1024;
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
