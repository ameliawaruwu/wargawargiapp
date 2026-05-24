import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/database_helper.dart';

class KasPage extends StatefulWidget {
  const KasPage({super.key});

  @override
  State<KasPage> createState() => _KasPageState();
}

class _KasPageState extends State<KasPage> {
  List<Map<String, dynamic>> _dataKas = [];
  String? _selectedPaketKas;
  String? _base64BuktiGambar;

  final List<Map<String, String>> _paketIuranRT = [
    {'keterangan': 'Iuran Kebersihan Lingkungan Bulanan', 'nominal': '10000'},
    {'keterangan': 'Iuran Keamanan & Ronda Siskamling', 'nominal': '20000'},
    {'keterangan': 'Iuran Kas Sosial RT', 'nominal': '15000'},
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getKas();
    setState(() { _dataKas = data; });
  }

  Future<void> _pilihBuktiDariPerangkat() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() { _base64BuktiGambar = base64Encode(bytes); });
    }
  }

  Future<void> _kirimSetoranKas() async {
    if (_selectedPaketKas == null || _base64BuktiGambar == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Lengkapi form dan unggah struk asli!'), backgroundColor: Colors.orange));
      return;
    }
    final paket = _paketIuranRT.firstWhere((e) => e['keterangan'] == _selectedPaketKas);
    await DatabaseHelper.instance.insertKas({
      'nama_warga': 'Mitchell Santos',
      'jenis_iuran': paket['keterangan'],
      'jumlah_nominal': paket['nominal'],
      'bukti_bayar': _base64BuktiGambar!,
    });
    setState(() { _selectedPaketKas = null; _base64BuktiGambar = null; });
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('SCAN GATEWAY QRIS RT 10', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6366F1))),
                    const SizedBox(height: 10),
                    Image.network('https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=WargaWargi', width: 110, height: 110),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedPaketKas,
                      hint: const Text('Pilih Paket Iuran'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _paketIuranRT.map((p) => DropdownMenuItem(value: p['keterangan'], child: Text("${p['keterangan']} (Rp ${p['nominal']})", style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (val) => setState(() => _selectedPaketKas = val),
                    ),
                    const SizedBox(height: 16),
                    if (_base64BuktiGambar != null) ...[
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(_base64BuktiGambar!), height: 120, width: double.infinity, fit: BoxFit.cover)),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(onPressed: _pilihBuktiDariPerangkat, icon: const Icon(Icons.add_photo_alternate_rounded), label: const Text('Pilih Foto Struk Asli Perangkat')),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: _kirimSetoranKas, child: const Text('PROSES SETOR KAS')))
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dataKas.length,
              itemBuilder: (context, idx) => Card(
                child: ListTile(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.memory(base64Decode(_dataKas[idx]['bukti_bayar']), width: 45, height: 45, fit: BoxFit.cover)),
                  title: Text(_dataKas[idx]['jenis_iuran'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  subtitle: const Text('Status: Success', style: TextStyle(fontSize: 11, color: Colors.green)),
                  trailing: Text("Rp ${_dataKas[idx]['jumlah_nominal']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}