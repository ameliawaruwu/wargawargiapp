import 'database_helper.dart';

class SuratCrud {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 1. Tambah Pengajuan Surat Baru (Untuk sisi Warga)
  Future<int> tambahSurat({
    required String namaPemohon,
    required String jenisSurat,
    required String perihal,
    String? filePdf,
  }) async {
    final Map<String, dynamic> dataSurat = {
      'nama_pemohon': namaPemohon,
      'jenis_surat': jenisSurat,
      'perihal': perihal,
      'tanggal_aju': DateTime.now().toString().substring(0, 10), // Format: YYYY-MM-DD
      'status_surat': 'Pending', // Otomatis diset awal sebagai Pending
      'file_pdf': filePdf,
    };
    return await _dbHelper.insertSurat(dataSurat);
  }

  // 2. Ambil Riwayat Surat Khusus Warga Tertentu (Untuk sisi Warga)
  Future<List<Map<String, dynamic>>> ambilSuratWarga(String namaPemohon) async {
    return await _dbHelper.getSurat(namaPemohon: namaPemohon);
  }

  // 3. Ambil Semua Surat Tanpa Filter (Untuk sisi Pengurus RT)
  Future<List<Map<String, dynamic>>> ambilSemuaSurat() async {
    return await _dbHelper.getSurat();
  }

  // 4. Update Status Verifikasi Surat (Untuk sisi Pengurus RT)
  Future<int> ubahStatusSurat(int id, String statusBaru, {String? filePdf}) async {
    // statusBaru diisi: 'Disetujui' atau 'Ditolak' sesuai aksi Pak RT
    return await _dbHelper.updateSuratStatus(id, statusBaru, filePdf: filePdf);
  }

  // 5. Hapus Pengajuan Surat (Opsional, menggunakan fungsi global database_helper)
  Future<int> hapusSurat(int id) async {
    return await _dbHelper.deleteData('surat', id);
  }
}