import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _refreshData();
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
    final String tgl = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    await DatabaseHelper.instance.insertKritik({
      'nama_pelapor': 'Mitchell Santos',
      'tanggal_lapor': tgl,
      'judul_keluhan': _judulCtrl.text,
      'isi_critic': _isiCtrl.text,
      'bukti_keluhan': _base64BuktiKeluhan!,
    });
    _judulCtrl.clear(); _isiCtrl.clear();
    setState(() { _base64BuktiKeluhan = null; });
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(controller: _judulCtrl, decoration: const InputDecoration(labelText: 'Judul Keluhan Fasilitas', border: OutlineInputBorder())),
                    const SizedBox(height: 14),
                    TextField(controller: _isiCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi Detail Keluhan', border: OutlineInputBorder())),
                    const SizedBox(height: 14),
                    if (_base64BuktiKeluhan != null) ...[
                      Image.memory(base64Decode(_base64BuktiKeluhan!), height: 100, width: double.infinity, fit: BoxFit.cover),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(onPressed: _pilihFotoKerusakan, icon: const Icon(Icons.add_a_photo), label: const Text('Pilih Foto Bukti Lapangan')),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, height: 44, child: ElevatedButton(onPressed: _kirimLaporan, child: const Text('KIRIM LAPORAN ADUAN')))
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dataKritik.length,
              itemBuilder: (context, idx) => Card(
                child: ListTile(
                  leading: Image.memory(base64Decode(_dataKritik[idx]['bukti_keluhan']), width: 40, height: 40, fit: BoxFit.cover),
                  title: Text(_dataKritik[idx]['judul_keluhan'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text("Tanggal Lap: ${_dataKritik[idx]['tanggal_lapor']}\nIsi: ${_dataKritik[idx]['isi_critic']}", style: const TextStyle(fontSize: 11)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}