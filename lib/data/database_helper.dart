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
      version: 5,  // ✓ UPDATED: Upgrade ke v5 untuk Skema Relasional (FOREIGN KEY) & Asesmen 3 (GPS)
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,  // ✓ ADDED: Handle database upgrade
    );
  }

  // ✓ ADDED: Konfigurasi SQLite untuk mengaktifkan constraint Foreign Key
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    print('🔑 DATABASE: Foreign key constraints enabled');
  }

  // ✓ ADDED: Migration handler untuk upgrade database
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('📊 DATABASE: Upgrading from v$oldVersion to v$newVersion');
    
    if (oldVersion < 2) {
      // Tidak ada action khusus, table sudah ada
      print('✓ Database upgrade v1→v2 completed');
    }
    
    if (oldVersion < 3) {
      // Migrasi dari v2 ke v3: Tambah tabel master iuran
      print('📋 Creating tabel_master_iuran for v3...');
      await db.execute('''
        CREATE TABLE tabel_master_iuran (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_iuran TEXT NOT NULL UNIQUE,
          nominal_wajib TEXT NOT NULL
        )
      ''');
      print('✓ Tabel master iuran created successfully');

      // Tambah kolom GPS koordinat untuk Asesmen 3
      try {
        await db.execute('ALTER TABLE kritik ADD COLUMN lokasi_koordinat TEXT');
        print('✓ Kolom lokasi_koordinat berhasil ditambahkan');
      } catch (e) {
        print('⚠️ Kolom lokasi_koordinat mungkin sudah ada: $e');
      }
    }

    if (oldVersion < 4) {
      // Migrasi dari v3 ke v4: Tambah kolom tipe pada tabel_master_iuran
      print('📋 Adding column tipe to tabel_master_iuran for v4...');
      try {
        await db.execute("ALTER TABLE tabel_master_iuran ADD COLUMN tipe TEXT DEFAULT 'IURAN'");
        // Update kategori default 'Kas Sosial RT' menjadi tipe 'KAS'
        await db.update('tabel_master_iuran', {'tipe': 'KAS'}, where: 'nama_iuran = ?', whereArgs: ['Kas Sosial RT']);
        print('✓ Column tipe added and Kas Sosial RT updated to KAS successfully');
      } catch (e) {
        print('❌ Error migrating to v4: $e');
      }
    }

    if (oldVersion < 5) {
      // Migrasi dari v4 ke v5: Relasi Skema & FK dengan NIK
      print('📋 Migrating database schema from v4 to v5 for relational integrity...');
      try {
        // 1. Rename tabel-tabel lama
        await db.execute('ALTER TABLE tabel_kas RENAME TO old_tabel_kas');
        await db.execute('ALTER TABLE surat RENAME TO old_surat');
        await db.execute('ALTER TABLE kritik RENAME TO old_kritik');
        
        // 2. Buat tabel-tabel baru dengan relational structure dan constraints
        await db.execute('''
          CREATE TABLE tabel_kas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            warga_nik TEXT NOT NULL,
            jenis_iuran TEXT NOT NULL,
            tipe_transaksi TEXT NOT NULL,
            bulan_periode TEXT NOT NULL,
            jumlah_nominal TEXT NOT NULL,
            keterangan TEXT,
            bukti_bayar TEXT,
            status_verifikasi TEXT NOT NULL,
            tanggal_setor TEXT NOT NULL,
            FOREIGN KEY (warga_nik) REFERENCES users(nik) ON UPDATE CASCADE ON DELETE CASCADE,
            FOREIGN KEY (jenis_iuran) REFERENCES tabel_master_iuran(nama_iuran) ON UPDATE CASCADE ON DELETE RESTRICT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE surat (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pemohon_nik TEXT NOT NULL,
            jenis_surat TEXT NOT NULL,
            perihal TEXT NOT NULL,
            tanggal_aju TEXT NOT NULL,
            status_surat TEXT DEFAULT 'Pending',
            file_pdf TEXT,
            FOREIGN KEY (pemohon_nik) REFERENCES users(nik) ON UPDATE CASCADE ON DELETE CASCADE
          )
        ''');
        
        await db.execute('''
          CREATE TABLE kritik (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pelapor_nik TEXT NOT NULL,
            judul_keluhan TEXT NOT NULL,
            isi_critic TEXT NOT NULL,
            bukti_keluhan TEXT,
            tanggal_lapor TEXT NOT NULL,
            status_laporan TEXT DEFAULT 'Belum ditangani',
            lokasi_koordinat TEXT,
            FOREIGN KEY (pelapor_nik) REFERENCES users(nik) ON UPDATE CASCADE ON DELETE CASCADE
          )
        ''');
        
        // 3. Pindahkan data dari tabel lama ke baru dengan lookup nik berdasarkan nama warga
        // Ambil default fallback nik dari tabel users jika relasi nama tidak ketemu
        final List<Map<String, dynamic>> defaultUser = await db.query('users', limit: 1);
        final String fallbackNik = defaultUser.isNotEmpty ? (defaultUser.first['nik'] ?? '1234567890123456') : '1234567890123456';
        
        await db.execute('''
          INSERT INTO tabel_kas (id, warga_nik, jenis_iuran, tipe_transaksi, bulan_periode, jumlah_nominal, keterangan, bukti_bayar, status_verifikasi, tanggal_setor)
          SELECT k.id, COALESCE(u.nik, '$fallbackNik'), k.jenis_iuran, k.tipe_transaksi, k.bulan_periode, k.jumlah_nominal, k.keterangan, k.bukti_bayar, k.status_verifikasi, k.tanggal_setor
          FROM old_tabel_kas k
          LEFT JOIN users u ON k.nama_warga = u.nama
        ''');
        
        await db.execute('''
          INSERT INTO surat (id, pemohon_nik, jenis_surat, perihal, tanggal_aju, status_surat, file_pdf)
          SELECT s.id, COALESCE(u.nik, '$fallbackNik'), s.jenis_surat, s.perihal, s.tanggal_aju, s.status_surat, s.file_pdf
          FROM old_surat s
          LEFT JOIN users u ON s.nama_pemohon = u.nama
        ''');
        
        await db.execute('''
          INSERT INTO kritik (id, pelapor_nik, judul_keluhan, isi_critic, bukti_keluhan, tanggal_lapor, status_laporan, lokasi_koordinat)
          SELECT c.id, COALESCE(u.nik, '$fallbackNik'), c.judul_keluhan, c.isi_critic, c.bukti_keluhan, c.tanggal_lapor, c.status_laporan, c.lokasi_koordinat
          FROM old_kritik c
          LEFT JOIN users u ON c.nama_pelapor = u.nama
        ''');
        
        // 4. Hapus tabel lama
        await db.execute('DROP TABLE old_tabel_kas');
        await db.execute('DROP TABLE old_surat');
        await db.execute('DROP TABLE old_kritik');
        
        print('✓ Database upgrade v4→v5 completed successfully');
      } catch (e) {
        print('❌ Error migrating to v5: $e');
      }
    }
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
        role TEXT NOT NULL,
        warga_phone TEXT,
        warga_alamat TEXT
      )
    ''');

    // 2. Tabel Layanan Persuratan
    await db.execute('''
      CREATE TABLE surat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pemohon_nik TEXT NOT NULL,
        jenis_surat TEXT NOT NULL,
        perihal TEXT NOT NULL,
        tanggal_aju TEXT NOT NULL,
        status_surat TEXT DEFAULT 'Pending',
        file_pdf TEXT,
        FOREIGN KEY (pemohon_nik) REFERENCES users(nik) ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    // 3. TABEL KAS TERBARU
    await db.execute('''
      CREATE TABLE tabel_kas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warga_nik TEXT NOT NULL,
        jenis_iuran TEXT NOT NULL,
        tipe_transaksi TEXT NOT NULL,      -- 'MASUK' atau 'KELUAR'
        bulan_periode TEXT NOT NULL,       -- Periode iuran bulanan
        jumlah_nominal TEXT NOT NULL,      -- Angka nominal uang
        keterangan TEXT,
        bukti_bayar TEXT,                  -- String teks konversi Base64 Gambar Struk
        status_verifikasi TEXT NOT NULL,   -- 'Pending' atau 'Lunas'
        tanggal_setor TEXT NOT NULL,       -- ISO 8601 String Otomatis (DateTime)
        FOREIGN KEY (warga_nik) REFERENCES users(nik) ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (jenis_iuran) REFERENCES tabel_master_iuran(nama_iuran) ON UPDATE CASCADE ON DELETE RESTRICT
      )
    ''');

    // 4. TABEL MASTER IURAN
    await db.execute('''
      CREATE TABLE tabel_master_iuran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_iuran TEXT NOT NULL UNIQUE,
        nominal_wajib TEXT NOT NULL,
        tipe TEXT DEFAULT 'IURAN'
      )
    ''');

    // ✓ SEED: Default master iuran
    await db.insert('tabel_master_iuran', {
      'nama_iuran': 'Iuran Kebersihan',
      'nominal_wajib': '50000',
      'tipe': 'IURAN'
    });
    await db.insert('tabel_master_iuran', {
      'nama_iuran': 'Iuran Keamanan',
      'nominal_wajib': '30000',
      'tipe': 'IURAN'
    });
    await db.insert('tabel_master_iuran', {
      'nama_iuran': 'Kas Sosial RT',
      'nominal_wajib': '20000',
      'tipe': 'KAS'
    });
    await db.insert('tabel_master_iuran', {
      'nama_iuran': 'Keperluan Infrastruktur',
      'nominal_wajib': '75000',
      'tipe': 'IURAN'
    });

    // 5. Tabel Kritik & Aduan Fasum
    await db.execute('''
      CREATE TABLE kritik (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pelapor_nik TEXT NOT NULL,
        judul_keluhan TEXT NOT NULL,
        isi_critic TEXT NOT NULL,
        bukti_keluhan TEXT,                -- Teks Base64 Foto Lapangan
        tanggal_lapor TEXT NOT NULL,
        lokasi_koordinat TEXT,             -- GPS lat,lng dari geolocator
        FOREIGN KEY (pelapor_nik) REFERENCES users(nik) ON UPDATE CASCADE ON DELETE CASCADE
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

  Future<Map<String, dynamic>?> getUserByNik(String nik) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'nik = ?',
      whereArgs: [nik],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<int> updateUserByNik(String nik, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'users',
      row,
      where: 'nik = ?',
      whereArgs: [nik],
    );
  }

  // --- CRUD OPERASI: MODUL LAYANAN SURAT ---
  Future<int> insertSurat(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('surat', row);
  }

  Future<List<Map<String, dynamic>>> getSurat({String? pemohonNik}) async {
    final db = await instance.database;
    if (pemohonNik != null && pemohonNik.isNotEmpty) {
      return await db.rawQuery('''
        SELECT s.*, u.nama AS nama_pemohon 
        FROM surat s 
        JOIN users u ON s.pemohon_nik = u.nik
        WHERE s.pemohon_nik = ?
        ORDER BY s.id DESC
      ''', [pemohonNik]);
    }
    return await db.rawQuery('''
      SELECT s.*, u.nama AS nama_pemohon 
      FROM surat s 
      JOIN users u ON s.pemohon_nik = u.nik
      ORDER BY s.id DESC
    ''');
  }

  Future<int> updateSuratStatus(int id, String status, {String? filePdf}) async {
    final db = await instance.database;
    Map<String, dynamic> updateData = {'status_surat': status};
    if (filePdf != null) {
      updateData['file_pdf'] = filePdf;
    }
    return await db.update(
      'surat',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD OPERASI: MODUL IURAN KAS RT ---
  Future<int> insertKas(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('tabel_kas', row);
  }

  Future<List<Map<String, dynamic>>> getKas({String? wargaNik}) async {
    final db = await instance.database;
    if (wargaNik != null && wargaNik.isNotEmpty) {
      return await db.rawQuery('''
        SELECT k.*, u.nama AS nama_warga 
        FROM tabel_kas k 
        JOIN users u ON k.warga_nik = u.nik
        WHERE k.warga_nik = ?
        ORDER BY k.id DESC
      ''', [wargaNik]);
    }
    return await db.rawQuery('''
      SELECT k.*, u.nama AS nama_warga 
      FROM tabel_kas k 
      JOIN users u ON k.warga_nik = u.nik
      ORDER BY k.id DESC
    ''');
  }

  Future<int> updateKasStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update(
      'tabel_kas',
      {'status_verifikasi': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD OPERASI: MODUL KRITIK & ADUAN ---
  Future<int> insertKritik(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('kritik', row);
  }

  Future<List<Map<String, dynamic>>> getKritik({String? pelaporNik}) async {
    final db = await instance.database;
    if (pelaporNik != null && pelaporNik.isNotEmpty) {
      return await db.rawQuery('''
        SELECT c.*, u.nama AS nama_pelapor 
        FROM kritik c 
        JOIN users u ON c.pelapor_nik = u.nik
        WHERE c.pelapor_nik = ?
        ORDER BY c.id DESC
      ''', [pelaporNik]);
    }
    return await db.rawQuery('''
      SELECT c.*, u.nama AS nama_pelapor 
      FROM kritik c 
      JOIN users u ON c.pelapor_nik = u.nik
      ORDER BY c.id DESC
    ''');
  }

  // ✓ ADDED: Update status laporan kritik
  Future<int> updateKritikStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update(
      'kritik',
      {'status_laporan': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === CRUD OPERASI: MODUL MASTER IURAN (Asesmen 3 - Amelia) ===
  /// Insert kategori iuran baru ke master tabel
  Future<int> insertMasterIuran(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('tabel_master_iuran', row);
  }

  /// Ambil semua kategori iuran dari master tabel
  Future<List<Map<String, dynamic>>> getMasterIuran() async {
    final db = await instance.database;
    return await db.query('tabel_master_iuran', orderBy: 'id ASC');
  }

  /// Ambil satu kategori iuran berdasarkan ID
  Future<Map<String, dynamic>?> getMasterIuranById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'tabel_master_iuran',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Update kategori iuran
  Future<int> updateMasterIuran(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'tabel_master_iuran',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete kategori iuran
  Future<int> deleteMasterIuran(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tabel_master_iuran',
      where: 'id = ?',
      whereArgs: [id],
    );
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
    print('🌱 SEEDING: Memulai seed default users...');
    
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
      print('✓ SEEDED: Warga (Amelia) dengan role: Warga Mandiri');
    } else {
      print('⏭️ SKIP: Warga (Amelia) sudah ada');
    }

    final existingRt = await db.query(
      'users',
      where: 'nik = ?',
      whereArgs: ['3010101010101018'],
    );

    if (existingRt.isEmpty) {
      await insertUser({
        'nik': '3010101010101018',
        'nama': 'Pengurus RT',
        'password': '2001',
        'role': 'Pengurus RT',
      });
      print('✓ SEEDED: RT (Pengurus RT) dengan role: Pengurus RT');
    } else {
      print('⏭️ SKIP: RT (Pengurus RT) sudah ada');
      // Verify role
      final rtUser = existingRt.first;
      print('   Role: ${rtUser['role']}');
    }
    
    await seedDefaultMasterIuran();
    print('✅ SEEDING: Completed');
  }

  /// Seed default master iuran ke database jika kosong.
  Future<void> seedDefaultMasterIuran() async {
    final db = await instance.database;
    
    // Verifikasi apakah tabel_master_iuran ada, jika tidak buat baru
    try {
      await db.rawQuery('SELECT 1 FROM tabel_master_iuran LIMIT 1');
    } catch (e) {
      print('⚠️ Tabel tabel_master_iuran belum terbentuk, membuat tabel sekarang...');
      try {
        await db.execute('''
          CREATE TABLE tabel_master_iuran (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama_iuran TEXT NOT NULL UNIQUE,
            nominal_wajib TEXT NOT NULL,
            tipe TEXT DEFAULT 'IURAN'
          )
        ''');
      } catch (ex) {
        print('❌ Error membuat tabel_master_iuran: $ex');
        return; // Jangan lanjut jika pembuatan tabel gagal
      }
    }
    
    // Verifikasi skema kolom 'tipe' (mencegah error tabel versi lama)
    try {
      await db.rawQuery('SELECT tipe FROM tabel_master_iuran LIMIT 1');
    } catch (e) {
      print('⚠️ Column "tipe" is missing in tabel_master_iuran, adding it now...');
      try {
        await db.execute("ALTER TABLE tabel_master_iuran ADD COLUMN tipe TEXT DEFAULT 'IURAN'");
      } catch (ex) {
        print('❌ Error adding column "tipe": $ex');
      }
    }

    try {
      final existing = await db.query('tabel_master_iuran');
      if (existing.isEmpty) {
        print('🌱 SEEDING: Memulai seed default master iuran...');
        await db.insert('tabel_master_iuran', {
          'nama_iuran': 'Iuran Kebersihan',
          'nominal_wajib': '50000',
          'tipe': 'IURAN'
        });
        await db.insert('tabel_master_iuran', {
          'nama_iuran': 'Iuran Keamanan',
          'nominal_wajib': '30000',
          'tipe': 'IURAN'
        });
        await db.insert('tabel_master_iuran', {
          'nama_iuran': 'Kas Sosial RT',
          'nominal_wajib': '20000',
          'tipe': 'KAS'
        });
        await db.insert('tabel_master_iuran', {
          'nama_iuran': 'Keperluan Infrastruktur',
          'nominal_wajib': '75000',
          'tipe': 'IURAN'
        });
        print('✓ SEEDED: Default master iuran successfully');
      } else {
        print('⏭️ SKIP: Master iuran sudah terisi');
      }
    } catch (e) {
      print('❌ Error querying/seeding tabel_master_iuran: $e');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}