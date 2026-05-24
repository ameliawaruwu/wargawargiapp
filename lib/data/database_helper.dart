import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wargawargiapp_final.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      final path = 'assets/db/$filePath';
      return await openDatabase(path, version: 1, onCreate: _createDB);
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(path, version: 1, onCreate: _createDB);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, nik TEXT UNIQUE, nama TEXT, password TEXT)');
    await db.execute('CREATE TABLE surat (id INTEGER PRIMARY KEY AUTOINCREMENT, jenis_surat TEXT, tujuan_surat TEXT, perihal TEXT)');
    await db.execute('CREATE TABLE kritik (id INTEGER PRIMARY KEY AUTOINCREMENT, nama_pelapor TEXT, tanggal_lapor TEXT, judul_keluhan TEXT, isi_critic TEXT, bukti_keluhan TEXT)');
    await db.execute('CREATE TABLE kas (id INTEGER PRIMARY KEY AUTOINCREMENT, nama_warga TEXT, jenis_iuran TEXT, jumlah_nominal TEXT, bukti_bayar TEXT)');

    // Akun default simulasi pengujian awal ( Mitchell Santos )
    await db.rawInsert("INSERT INTO users(nik, nama, password) VALUES('1234567890123456', 'Mitchell Santos', '1234')");
  }

  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    try { return await db.insert('users', row); } catch (_) { return -1; }
  }

  Future<Map<String, dynamic>?> checkLogin(String nik, String password) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'nik = ? AND password = ?', whereArgs: [nik, password]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> insertSurat(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('surat', row);
  }

  Future<List<Map<String, dynamic>>> getSurat() async {
    final db = await instance.database;
    return await db.query('surat', orderBy: 'id DESC');
  }

  Future<int> insertKritik(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('kritik', row);
  }

  Future<List<Map<String, dynamic>>> getKritik() async {
    final db = await instance.database;
    return await db.query('kritik', orderBy: 'id DESC');
  }

  Future<int> insertKas(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('kas', row);
  }

  Future<List<Map<String, dynamic>>> getKas() async {
    final db = await instance.database;
    return await db.query('kas', orderBy: 'id DESC');
  }

  Future<int> updateData(String table, Map<String, dynamic> row, int id) async {
    final db = await instance.database;
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteData(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}