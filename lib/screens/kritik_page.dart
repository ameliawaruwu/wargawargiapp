import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/preferences_helper.dart';
import 'detail_kritik_page.dart';

class KritikPage extends StatefulWidget {
  const KritikPage({super.key});

  @override
  State<KritikPage> createState() => _KritikPageState();
}

class _KritikPageState extends State<KritikPage> {
  List<Map<String, dynamic>> _dataKritik = [];
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();
  String? _base64BuktiKeluhan;
  String _namaPelapor = 'Warga';

  @override
  void initState() {
    super.initState();
    _loadProfileName();
    _refreshData();
  }

  Future<void> _loadProfileName() async {
    final sesi = await PreferencesHelper.ambilSesiLogin();
    setState(() {
      _namaPelapor = sesi['nama_warga'] ?? 'Warga';
    });
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getKritik();
    setState(() { _dataKritik = data; });
  }

  Future<void> _pilihFotoKerusakan() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() { _base64BuktiKeluhan = base64Encode(bytes); });
    }
  }

  Future<void> _kirimLaporan() async {
    if (_judulCtrl.text.isEmpty || _isiCtrl.text.isEmpty || _base64BuktiKeluhan == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Lengkapi form dan lampiran foto aduan!'), backgroundColor: Colors.orange));
      return;
    }
    final now = DateTime.now();
    final tglFormat = DateFormat('dd/MM/yyyy HH:mm').format(now);
    await DatabaseHelper.instance.insertKritik({
      'nama_pelapor': _namaPelapor,
      'tanggal_lapor': tglFormat,
      'judul_keluhan': _judulCtrl.text,
      'isi_critic': _isiCtrl.text,
      'bukti_keluhan': _base64BuktiKeluhan!,
    });
    _judulCtrl.clear(); _isiCtrl.clear();
    setState(() { _base64BuktiKeluhan = null; });
    _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Laporan berhasil dikirim!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EDFF),
      appBar: AppBar(
        title: const Text('Kritik & Aduan'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: const Color(0xFFF5F3FF),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Text('Laporkan kerusakan fasilitas umum dengan cepat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                    SizedBox(height: 8),
                    Text('Isi form di bawah ini, unggah foto bukti, lalu kirim laporan Anda agar tim RT dapat menindaklanjuti.', style: TextStyle(fontSize: 13, color: Color(0xFF6366F1))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Form Aduan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _judulCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Judul Keluhan Fasilitas',
                        prefixIcon: Icon(Icons.report_problem_outlined, color: Color(0xFF6366F1)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _isiCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Detail Keluhan',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined, color: Color(0xFF6366F1)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Foto Bukti Lapangan', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF4F46E5))),
                    const SizedBox(height: 8),
                    if (_base64BuktiKeluhan != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          base64Decode(_base64BuktiKeluhan!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: const Center(
                          child: Text('Belum ada foto bukti yang dipilih', style: TextStyle(color: Color(0xFF6366F1))),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pilihFotoKerusakan,
                      icon: const Icon(Icons.add_a_photo, color: Color(0xFF6366F1)),
                      label: const Text('Pilih Foto Bukti Lapangan', style: TextStyle(color: Color(0xFF6366F1))),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _kirimLaporan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('KIRIM LAPORAN ADUAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Text('Daftar Aduan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            const SizedBox(height: 12),
            if (_dataKritik.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: const [
                    Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFA78BFA)),
                    SizedBox(height: 12),
                    Text('Belum ada laporan kritik', style: TextStyle(color: Color(0xFF6366F1), fontSize: 14)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dataKritik.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final item = _dataKritik[idx];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailKritikPage(kritik: item),
                        ),
                      ).then((_) => _refreshData());
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: const Color(0xFFF5F3FF),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(
                                      base64Decode(item['bukti_keluhan']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['judul_keluhan'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 6),
                                      Text(item['isi_critic'], style: const TextStyle(fontSize: 13, color: Color(0xFF475569)), maxLines: 3, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Pelapor: ${item['nama_pelapor']}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(item['tanggal_lapor'], style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
