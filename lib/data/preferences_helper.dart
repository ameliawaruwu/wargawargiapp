import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _namaWargaKey = 'nama_warga';
  static const String _roleUserKey = 'role_user';
  static const String _kodeWilayahKey = 'kode_wilayah';
  static const String _totalAksesKey = 'total_akses_aplikasi';
  static const String _fiturDarkTemaKey = 'fitur_dark_tema';

  // ============================================================================
  // SHARED PREFERENCES #1: Manajemen Data Sesi Login Warga
  // ============================================================================
  /// Menyimpan data sesi login ke Shared Preferences (6 atribut)
  static Future<bool> simpanSesiLogin({
    required String namaWarga,
    required String roleUser,
    required String kodeWilayah,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_namaWargaKey, namaWarga);
    await prefs.setString(_roleUserKey, roleUser);
    await prefs.setString(_kodeWilayahKey, kodeWilayah);
    await prefs.setInt(_totalAksesKey, 1);
    await prefs.setBool(_fiturDarkTemaKey, false);
    
    return true;
  }

  /// Mengambil data sesi login dari Shared Preferences
  static Future<Map<String, dynamic>> ambilSesiLogin() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'is_logged_in': prefs.getBool(_isLoggedInKey) ?? false,
      'nama_warga': prefs.getString(_namaWargaKey) ?? 'Guest',
      'role_user': prefs.getString(_roleUserKey) ?? 'Warga',
      'kode_wilayah': prefs.getString(_kodeWilayahKey) ?? 'N/A',
      'total_akses': prefs.getInt(_totalAksesKey) ?? 0,
      'dark_tema': prefs.getBool(_fiturDarkTemaKey) ?? false,
    };
  }

  // ============================================================================
  // SHARED PREFERENCES #2: Manajemen Preferensi Pengguna & Aplikasi
  // ============================================================================
  /// Mengupdate status login dan akses aplikasi
  static Future<bool> updateStatusLogin({required bool isLoggedIn}) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  /// Meningkatkan counter akses aplikasi
  static Future<bool> tambahAksesAplikasi() async {
    final prefs = await SharedPreferences.getInstance();
    final totalAkses = prefs.getInt(_totalAksesKey) ?? 0;
    return await prefs.setInt(_totalAksesKey, totalAkses + 1);
  }

  /// Mengganti tema aplikasi (Light/Dark)
  static Future<bool> ubahTemaAplikasi({required bool isDarkMode}) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_fiturDarkTemaKey, isDarkMode);
  }

  /// Mengambil preferensi tema aplikasi
  static Future<bool> ambilTemaAplikasi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fiturDarkTemaKey) ?? false;
  }

  // ============================================================================
  // UTILITAS: Hapus semua data sesi (Logout)
  // ============================================================================
  /// Menghapus semua data sesi login saat logout
  static Future<bool> hapusSesiLogin() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_namaWargaKey);
    await prefs.remove(_roleUserKey);
    await prefs.remove(_kodeWilayahKey);
    await prefs.remove(_totalAksesKey);
    await prefs.remove(_fiturDarkTemaKey);
    
    return true;
  }
}
