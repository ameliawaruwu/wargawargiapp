import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QRIS Generator Component (Dynamic Preview)
/// 
/// Komponen ini menampilkan QR Code yang berubah dinamis sesuai:
/// - Kategori iuran (jenis_iuran)
/// - Nominal rupiah (jumlah_nominal)
/// - Nama warga (nama_warga)
/// - Periode (bulan_periode)
/// 
/// Data akan di-encode dalam format JSON untuk QR Code yang mudah diparsing
class QrisGeneratorWidget extends StatelessWidget {
  final String namaWarga;
  final String jenisIuran;
  final String nominalRupiah;
  final String bulanPeriode;
  final double? qrSize;

  const QrisGeneratorWidget({
    super.key,
    required this.namaWarga,
    required this.jenisIuran,
    required this.nominalRupiah,
    required this.bulanPeriode,
    this.qrSize = 220,
  });

  /// Generate QR Code data dari parameter-parameter transaksi
  /// Format: JSON untuk mudah di-parse oleh aplikasi penerima
  String _generateQrData() {
    // Bersihkan nominal dari format currency (hapus Rp, titik, koma)
    String cleanNominal = nominalRupiah
        .replaceAll(RegExp(r'[^\d]'), '') // Hapus semua non-digit
        .replaceAll('.', '') // Hapus pemisah ribuan
        .trim();

    // Jika masih ada koma di depan, asumsikan sudah bersih
    if (cleanNominal.isEmpty) {
      cleanNominal = nominalRupiah.replaceAll(RegExp(r'[^\d]'), '');
    }

    // Format data transaksi dalam JSON untuk QR Code
    final qrData = {
      'app': 'WargaWargi',
      'tipe': 'PEMBAYARAN_IURAN',
      'warga': namaWarga,
      'iuran': jenisIuran,
      'nominal': cleanNominal, // Dalam Rupiah
      'periode': bulanPeriode,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Convert to JSON string
    final jsonString = _simpleJsonEncode(qrData);
    return jsonString;
  }

  /// Helper function untuk encode JSON manual (simple)
  String _simpleJsonEncode(Map<String, dynamic> data) {
    final entries = data.entries
        .map((e) => '"${e.key}":"${e.value.toString().replaceAll('"', '\\"')}"')
        .join(',');
    return '{$entries}';
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _generateQrData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.qr_code_2, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview QRIS Dinamis',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'Scan untuk verifikasi pembayaran',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Code Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: qrSize,
              errorCorrectionLevel: QrErrorCorrectLevel.H, // High error correction
              backgroundColor: Colors.white,
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black87,
              ),
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Detail transaksi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('👤 Warga:', namaWarga),
                _buildDetailRow('💳 Iuran:', jenisIuran),
                _buildDetailRow('💰 Nominal:', 'Rp $nominalRupiah'),
                _buildDetailRow('📅 Periode:', bulanPeriode),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR Code akan berubah otomatis sesuai data yang Anda masukkan',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade900,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
