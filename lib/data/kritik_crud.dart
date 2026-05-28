import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class KritikCRUD {
  // ============================================================================
  // CRUD #1: CREATE - Menyimpan Laporan Kritik & Aduan Fasum ke Database
  // ============================================================================
  /// Menambahkan laporan kritik baru dengan foto bukti (Base64)
  /// 
  /// Parameter:
  /// - [namaPelapor]: Nama warga yang melaporkan
  /// - [judulKeluhan]: Judul/ringkasan keluhan
  /// - [isiCritic]: Deskripsi detail keluhan
  /// - [buktiKeluhan]: Foto lapangan yang dikonversi Base64
  /// 
  /// Return: ID kritik yang baru dibuat (int), atau 0 jika gagal
  static Future<int> buatLaporanKritik({
    required String namaPelapor,
    required String judulKeluhan,
    required String isiCritic,
    required String buktiKeluhan,
  }) async {
    try {
      final data = {
        'nama_pelapor': namaPelapor,
        'judul_keluhan': judulKeluhan,
        'isi_critic': isiCritic,
        'bukti_keluhan': buktiKeluhan,
        'tanggal_lapor': DateTime.now().toIso8601String(),
      };

      final id = await DatabaseHelper.instance.insertKritik(data);
      return id;
    } catch (e) {
      print('❌ Error membuat laporan kritik: $e');
      return 0;
    }
  }

  // ============================================================================
  // CRUD #2: READ - Mengambil Daftar Laporan Kritik & Media Bukti
  // ============================================================================
  /// Mengambil semua laporan kritik dengan media bukti dari database
  /// Data diurutkan dari laporan terbaru (DESC)
  /// 
  /// Return: List berisi Map kritik dengan field:
  /// - id, nama_pelapor, judul_keluhan, isi_critic, bukti_keluhan (Base64), tanggal_lapor
  static Future<List<Map<String, dynamic>>> ambilSemuaKritik() async {
    try {
      final kritikList = await DatabaseHelper.instance.getKritik();
      return kritikList;
    } catch (e) {
      print('❌ Error mengambil laporan kritik: $e');
      return [];
    }
  }

  /// Mengambil laporan kritik berdasarkan ID tertentu (untuk detail view)
  /// 
  /// Return: Map berisi data kritik spesifik atau null jika tidak ditemukan
  static Future<Map<String, dynamic>?> ambilKritikById(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'kritik',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) return maps.first;
      return null;
    } catch (e) {
      print('❌ Error mengambil detail kritik: $e');
      return null;
    }
  }

  /// Mengambil laporan kritik berdasarkan nama pelapor
  /// 
  /// Return: List kritik dari pelapor tertentu
  static Future<List<Map<String, dynamic>>> ambilKritikByNamaPelapor(
      String namaPelapor) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'kritik',
        where: 'nama_pelapor = ?',
        whereArgs: [namaPelapor],
        orderBy: 'id DESC',
      );
      return maps;
    } catch (e) {
      print('❌ Error mengambil kritik by pelapor: $e');
      return [];
    }
  }

  // ============================================================================
  // CRUD TAMBAHAN: UPDATE & DELETE
  // ============================================================================
  /// Mengupdate laporan kritik yang ada
  /// 
  /// Return: Jumlah baris yang berhasil diupdate
  static Future<int> updateLaporanKritik({
    required int id,
    required String judulKeluhan,
    required String isiCritic,
    required String? buktiKeluhan,
  }) async {
    try {
      final data = {
        'judul_keluhan': judulKeluhan,
        'isi_critic': isiCritic,
        if (buktiKeluhan != null) 'bukti_keluhan': buktiKeluhan,
      };

      final result =
          await DatabaseHelper.instance.updateData('kritik', data, id);
      return result;
    } catch (e) {
      print('❌ Error update laporan kritik: $e');
      return 0;
    }
  }

  /// Menghapus laporan kritik berdasarkan ID
  /// 
  /// Return: Jumlah baris yang berhasil dihapus
  static Future<int> hapusLaporanKritik(int id) async {
    try {
      final result = await DatabaseHelper.instance.deleteData('kritik', id);
      return result;
    } catch (e) {
      print('❌ Error hapus laporan kritik: $e');
      return 0;
    }
  }

  // ============================================================================
  // UTILITAS: Filter & Query Spesial
  // ============================================================================
  /// Menghitung total laporan kritik yang masuk
  static Future<int> hitungTotalKritik() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM kritik',
      );
      return result.first['count'] as int;
    } catch (e) {
      print('❌ Error menghitung total kritik: $e');
      return 0;
    }
  }

  /// Mengambil laporan kritik dalam rentang tanggal tertentu
  static Future<List<Map<String, dynamic>>> ambilKritikByTanggal({
    required DateTime tanggalMulai,
    required DateTime tanggalAkhir,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'kritik',
        where:
            'tanggal_lapor BETWEEN ? AND ?',
        whereArgs: [
          tanggalMulai.toIso8601String(),
          tanggalAkhir.toIso8601String(),
        ],
        orderBy: 'tanggal_lapor DESC',
      );
      return maps;
    } catch (e) {
      print('❌ Error mengambil kritik by tanggal: $e');
      return [];
    }
  }
}
