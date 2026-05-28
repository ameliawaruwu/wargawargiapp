import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../data/database_helper.dart';
import '../component/custom_bottom_nav.dart';

class KasPage extends StatefulWidget {
  final String namaWarga;
  const KasPage({super.key, required this.namaWarga});

  @override
  State<KasPage> createState() => _KasPageState();
}

class _KasPageState extends State<KasPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  
  String _jenisIuranSelected = 'Iuran Kebersihan';
  String _tipeTransaksi = 'MASUK'; // 'MASUK' = Setoran Warga, 'KELUAR' = Pengeluaran RT
  String _bulanSelected = 'Mei';
  String _filterStatusSelected = 'SEMUA'; // Filter: 'SEMUA', 'MASUK', 'KELUAR'
  
  Uint8List? _imageBytes;
  String? _base64Image;
  bool _isUploading = false;
  List<Map<String, dynamic>> _riwayatKas = [];

  final List<String> _listJenisIuran = ['Iuran Kebersihan', 'Iuran Keamanan', 'Kas Sosial RT', 'Keperluan Infrastruktur'];
  final List<String> _listBulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

  @override
  void initState() {
    super.initState();
    _loadKasPreferences();
    _ambilRiwayatKas();
  }

  Future<void> _loadKasPreferences() async {
    final sp = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _filterStatusSelected = sp.getString('kas_filter_status') ?? _filterStatusSelected;
      _bulanSelected = sp.getString('kas_selected_month') ?? _bulanSelected;
    });
  }

  Future<void> _saveKasPreferences() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('kas_filter_status', _filterStatusSelected);
    await sp.setString('kas_selected_month', _bulanSelected);
  }

  // === READ DATA DARI SQLITE ===
  Future<void> _ambilRiwayatKas() async {
    final data = await DatabaseHelper.instance.getKas();
    setState(() {
      _riwayatKas = data;
    });
  }

  // === INTERAKSI HARDWARE: IMAGE PICKER & BASE64 ENCODING ===
  Future<void> _pilihGambarBukti(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50); // Kompres 50% biar DB ringan

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _base64Image = base64Encode(bytes); // Mengonversi berkas gambar biner ke teks String Base64
      });
    }
  }

  // === ADVANCED CREATE + LOGIKA VALIDATION GANDA ===
  Future<void> _simpanTransaksiKas() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_tipeTransaksi == 'MASUK' && _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Wajib melampirkan foto struk bukti transfer!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isUploading = true; });

    // VALIDASI KOMPLEKS: Cek duplikasi pembayaran di bulan yang sama untuk transaksi MASUK
    if (_tipeTransaksi == 'MASUK') {
      bool sudahBayar = _riwayatKas.any((item) => 
        item['jenis_iuran'] == _jenisIuranSelected && 
        item['bulan_periode'] == _bulanSelected &&
        item['tipe_transaksi'] == 'MASUK'
      );

      if (sudahBayar) {
        setState(() { _isUploading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anda sudah menyetor $_jenisIuranSelected untuk periode bulan $_bulanSelected!'), 
            backgroundColor: Colors.red
          ),
        );
        return;
      }
    }

    // Eksekusi Simpan dengan Rekam Waktu Otomatis (Core Library DateTime Dart)
    await DatabaseHelper.instance.insertKas({
      'nama_warga': widget.namaWarga,
      'jenis_iuran': _jenisIuranSelected,
      'tipe_transaksi': _tipeTransaksi,
      'bulan_periode': _bulanSelected,
      'jumlah_nominal': _nominalController.text,
      'keterangan': _keteranganController.text.isEmpty ? 'Pembayaran $_jenisIuranSelected' : _keteranganController.text,
      'bukti_bayar': _base64Image,
      'status_verifikasi': _tipeTransaksi == 'MASUK' ? 'Pending' : 'Lunas', 
      'tanggal_setor': DateTime.now().toIso8601String(), // Mengamankan format tanggal standar ISO 8601
    });

    // Reset State Form input
    _nominalController.clear();
    _keteranganController.clear();
    setState(() {
      _imageBytes = null;
      _base64Image = null;
      _isUploading = false;
    });

    _ambilRiwayatKas(); // Refresh list data
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Transaksi Kas berhasil dicatat ke sistem!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Formulir Iuran & Kas RT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            
            // AREA KARTU INPUT FORM
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E7EB))),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ChoiceChip Toggle Arus Kas
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Setor Kas (Masuk)')),
                              selected: _tipeTransaksi == 'MASUK',
                              selectedColor: const Color(0xFFDCFCE7),
                              labelStyle: TextStyle(color: _tipeTransaksi == 'MASUK' ? Colors.green[800] : Colors.black, fontWeight: FontWeight.bold),
                              onSelected: (val) { setState(() { _tipeTransaksi = 'MASUK'; }); },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Pengeluaran RT (Keluar)')),
                              selected: _tipeTransaksi == 'KELUAR',
                              selectedColor: const Color(0xFFFEE2E2),
                              labelStyle: TextStyle(color: _tipeTransaksi == 'KELUAR' ? Colors.red[800] : Colors.black, fontWeight: FontWeight.bold),
                              onSelected: (val) { setState(() { _tipeTransaksi = 'KELUAR'; }); },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _jenisIuranSelected,
                        decoration: const InputDecoration(labelText: 'Kategori Kas', border: OutlineInputBorder()),
                        items: _listJenisIuran.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) { setState(() { _jenisIuranSelected = val!; }); },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _bulanSelected,
                        decoration: const InputDecoration(labelText: 'Periode Bulan', border: OutlineInputBorder()),
                        items: _listBulan.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _bulanSelected = val!;
                          });
                          _saveKasPreferences();
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nominalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Jumlah Nominal (Rp)', border: OutlineInputBorder(), prefixText: 'Rp '),
                        validator: (val) => val == null || val.isEmpty ? 'Nominal tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),

                      // Input Media Bukti Transfer (Hanya muncul jika kas MASUK)
                      if (_tipeTransaksi == 'MASUK') ...[
                        const Text('Upload Struk Bukti Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pilihGambarBukti(ImageSource.gallery),
                              icon: const Icon(Icons.image),
                              label: const Text('Galeri'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEEF2FF), foregroundColor: const Color(0xFF4F46E5), elevation: 0),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _pilihGambarBukti(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Kamera'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEEF2FF), foregroundColor: const Color(0xFF4F46E5), elevation: 0),
                            ),
                          ],
                        ),
                        if (_imageBytes != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_imageBytes!, height: 120, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _simpanTransaksiKas,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _isUploading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Catat Transaksi Kas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // === COMPONENT: HEADER LOG & TAB FILTER RESPONSIVE ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Arus Kas Lingkungan RT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: DropdownButton<String>(
                    value: _filterStatusSelected,
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                    items: const [
                      DropdownMenuItem(value: 'SEMUA', child: Text('🔄 Semua')),
                      DropdownMenuItem(value: 'MASUK', child: Text('📥 Masuk')),
                      DropdownMenuItem(value: 'KELUAR', child: Text('📤 Keluar')),
                    ],
                    onChanged: (val) {
                      setState(() { _filterStatusSelected = val!; });
                      _saveKasPreferences();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // AREA RENDER DATA LIST MUTASI TRANSAKSI
            _riwayatKas.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data mutasi kas.', style: TextStyle(color: Colors.grey, fontSize: 12))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _riwayatKas.length,
                    itemBuilder: (context, idx) {
                      final item = _riwayatKas[idx];
                      final isMasuk = item['tipe_transaksi'] == 'MASUK';
                      
                      // LOGIKA FILTER DUA ARAH (CLIENT SIDE REDUCTION)
                      if (_filterStatusSelected == 'MASUK' && !isMasuk) return const SizedBox.shrink();
                      if (_filterStatusSelected == 'KELUAR' && isMasuk) return const SizedBox.shrink();
                      
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))),
                        child: ListTile(
                          leading: !isMasuk
                              ? const CircleAvatar(backgroundColor: Color(0xFFFEE2E2), child: Icon(Icons.arrow_upward, color: Colors.red, size: 20))
                              : item['bukti_bayar'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.memory(base64Decode(item['bukti_bayar']), width: 40, height: 40, fit: BoxFit.cover),
                                    )
                                  : const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.arrow_downward, color: Colors.green, size: 20)),
                          title: Text(item['jenis_iuran'] ?? 'Kas RT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Periode: ${item['bulan_periode']} — Oleh: ${item['nama_warga']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                // Menampilkan Tanggal Konversi Lokal dari ISO String (Ambil 10 Karakter Depan lalu Dibalik)
                                Text(
                                  'Tanggal: ${item['tanggal_setor'] != null ? item['tanggal_setor'].toString().substring(0, 10).split('-').reversed.join('-') : '-'}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isMasuk ? "+" : "-"} Rp ${item['jumlah_nominal']}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: isMasuk ? Colors.green[700] : Colors.red[700], fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: item['status_verifikasi'] == 'Lunas' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['status_verifikasi'] ?? 'Pending',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: item['status_verifikasi'] == 'Lunas' ? Colors.green[800] : Colors.amber[900]),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  )
          ],
        ),
      ),
    );
  }
}