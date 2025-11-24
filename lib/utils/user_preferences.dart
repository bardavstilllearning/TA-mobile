import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  // Keys
  static const String _keyUserId = 'user_id';
  static const String _keyCurrency = 'preferred_currency';
  static const String _keyTimezone = 'preferred_timezone';

  // ✅ DEFAULT VALUES
  static const String DEFAULT_CURRENCY = 'IDR';
  static const String DEFAULT_TIMEZONE = 'Asia/Jakarta';

  // Get User ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Set User ID
  static Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);

    // ✅ FIX: Set default preferences untuk user baru
    if (!prefs.containsKey(_keyCurrency)) {
      await prefs.setString(_keyCurrency, DEFAULT_CURRENCY);
      print('✅ Set default currency for new user: $DEFAULT_CURRENCY');
    }

    if (!prefs.containsKey(_keyTimezone)) {
      await prefs.setString(_keyTimezone, DEFAULT_TIMEZONE);
      print('✅ Set default timezone for new user: $DEFAULT_TIMEZONE');
    }
  }

  // ✅ Currency Methods - Always return IDR if not set
  static Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
    print('💰 Set currency: $currency');
  }

  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString(_keyCurrency);

    // ✅ FIX: Jika null atau kosong, set default dan return
    if (currency == null || currency.isEmpty) {
      await prefs.setString(_keyCurrency, DEFAULT_CURRENCY);
      print('💰 Using default currency: $DEFAULT_CURRENCY');
      return DEFAULT_CURRENCY;
    }

    print('💰 Get currency: $currency');
    return currency;
  }

  // ✅ Timezone Methods - Always return WIB if not set
  static Future<void> setTimezone(String timezone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTimezone, timezone);
    print('⏰ Set timezone: $timezone');
  }

  static Future<String> getTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    final timezone = prefs.getString(_keyTimezone);

    // ✅ FIX: Jika null atau kosong, set default dan return
    if (timezone == null || timezone.isEmpty) {
      await prefs.setString(_keyTimezone, DEFAULT_TIMEZONE);
      print('⏰ Using default timezone: $DEFAULT_TIMEZONE');
      return DEFAULT_TIMEZONE;
    }

    print('⏰ Get timezone: $timezone');
    return timezone;
  }

  // ✅ Set Both (for API sync)
  static Future<void> setPreferences({
    String? currency,
    String? timezone,
  }) async {
    if (currency != null) await setCurrency(currency);
    if (timezone != null) await setTimezone(timezone);
  }

  // ✅ Initialize defaults on first launch
  static Future<void> initializeDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    // Set default currency if not exists
    if (!prefs.containsKey(_keyCurrency)) {
      await prefs.setString(_keyCurrency, DEFAULT_CURRENCY);
      print('✅ Initialized default currency: $DEFAULT_CURRENCY');
    }

    // Set default timezone if not exists
    if (!prefs.containsKey(_keyTimezone)) {
      await prefs.setString(_keyTimezone, DEFAULT_TIMEZONE);
      print('✅ Initialized default timezone: $DEFAULT_TIMEZONE');
    }
  }

  // ✅ Clear all preferences
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrency);
    await prefs.remove(_keyTimezone);
    print('🗑️ Cleared preferences');
  }

  // ✅ NEW: Force reset to defaults (useful for new users)
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, DEFAULT_CURRENCY);
    await prefs.setString(_keyTimezone, DEFAULT_TIMEZONE);
    print('🔄 Reset to defaults: $DEFAULT_CURRENCY, $DEFAULT_TIMEZONE');
  }
}
