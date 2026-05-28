import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wargawargi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Memicu onCreate jika file database belum terbentuk di device
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB,
    );
  }

  // === STRUKTUR TABEL BARU SINKRON ASESMEN 2 ===
  Future _createDB(Database db, int version) async {
    // 1. Tabel Akun Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nik TEXT NOT NULL UNIQUE,
        nama TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // 2. Tabel Layanan Persuratan (Anggota 1)
    await db.execute('''
      CREATE TABLE surat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pemohon TEXT NOT NULL,
        jenis_surat TEXT NOT NULL,
        perihal TEXT NOT NULL,
        tanggal_aju TEXT NOT NULL
      )
    ''');

    // 3. TABEL KAS TERBARU — KOMPLEKS MULTI-STATUS (Amelia)
    await db.execute('''
      CREATE TABLE tabel_kas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_warga TEXT NOT NULL,
        jenis_iuran TEXT NOT NULL,
        tipe_transaksi TEXT NOT NULL,      -- 'MASUK' atau 'KELUAR'
        bulan_periode TEXT NOT NULL,       -- Periode iuran bulanan
        jumlah_nominal TEXT NOT NULL,      -- Angka nominal uang
        keterangan TEXT,
        bukti_bayar TEXT,                  -- String teks konversi Base64 Gambar Struk
        status_verifikasi TEXT NOT NULL,   -- 'Pending' atau 'Lunas'
        tanggal_setor TEXT NOT NULL        -- ISO 8601 String Otomatis (DateTime)
      )
    ''');

    // 4. Tabel Kritik & Aduan Fasum (Anggota 3)
    await db.execute('''
      CREATE TABLE kritik (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pelapor TEXT NOT NULL,
        judul_keluhan TEXT NOT NULL,
        isi_critic TEXT NOT NULL,
        bukti_keluhan TEXT,                -- Teks Base64 Foto Lapangan
        tanggal_lapor TEXT NOT NULL
      )
    ''');
  }

  
  // CRUD AUTH
  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row);
  }

  Future<Map<String, dynamic>?> checkLogin(String nik, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'nik = ? AND password = ?',
      whereArgs: [nik, password],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // --- CRUD OPERASI: MODUL LAYANAN SURAT ---
  Future<int> insertSurat(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('surat', row);
  }

  Future<List<Map<String, dynamic>>> getSurat() async {
    final db = await instance.database;
    return await db.query('surat', orderBy: 'id DESC');
  }

  // --- CRUD OPERASI: MODUL IURAN KAS RT ---
  Future<int> insertKas(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('tabel_kas', row);
  }

  Future<List<Map<String, dynamic>>> getKas() async {
    final db = await instance.database;
    return await db.query('tabel_kas', orderBy: 'id DESC');
  }

  // --- CRUD OPERASI: MODUL KRITIK & ADUAN ---
  Future<int> insertKritik(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('kritik', row);
  }

  Future<List<Map<String, dynamic>>> getKritik() async {
    final db = await instance.database;
    return await db.query('kritik', orderBy: 'id DESC');
  }

  // --- ARSITEKTUR UPDATE & DELETE GLOBAL ---
  Future<int> updateData(String table, Map<String, dynamic> row, int id) async {
    final db = await instance.database;
    return await db.update(
      table, 
      row, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  Future<int> deleteData(String table, int id) async {
    final db = await instance.database;
    return await db.delete(
      table, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  /// Seed default user ke database jika belum ada.
  Future<void> seedDefaultUser() async {
    final db = await instance.database;
    final existing = await db.query(
      'users',
      where: 'nik = ?',
      whereArgs: ['3210101010101013'],
    );

    if (existing.isEmpty) {
      await insertUser({
        'nik': '3210101010101013',
        'nama': 'Amelia',
        'password': 'amel',
        'role': 'Warga Mandiri',
      });
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}