import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';

class SuratPage extends StatefulWidget {
  const SuratPage({super.key});

  @override
  State<SuratPage> createState() => _SuratPageState();
}

class _SuratPageState extends State<SuratPage> {
  int _currentTabIndex = 0;
  List<Map<String, dynamic>> _allSuratData = [];
  bool _isProfilLengkap = false;
  String _namaWarga = '';
  
  final _phoneCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _rtRwCtrl = TextEditingController();

  String? _selectedJenisSurat;
  final _perihalCtrl = TextEditingController();

  final _noKkCtrl = TextEditingController();
  final _namaAnggotaCtrl = TextEditingController();
  final _namaUsahaCtrl = TextEditingController();

  final List<String> _opsiSuratHalloWarga = [
    'Pengantar Perubahan Kartu Keluarga (KK)',
    'Surat Pengantar Akta Kelahiran',
    'Surat Pengantar Akta Kematian',
    'Surat Pengantar Nikah',
    'Surat Pengantar Pembuatan NIK Baru',
    'Surat Pengantar Pindah Domisili',
    'Surat Pengantar SKCK',
    'Surat Keterangan Domisili',
    'Surat Keterangan Izin Usaha',
    'Surat Keterangan Tidak Mampu (SKTM)',
    'Surat Izin Keramaian'
  ];

  @override
  void initState() {
    super.initState();
    _cekStatusProfilWarga();
    _refreshSuratList();
  }

  Future<void> _cekStatusProfilWarga() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _namaWarga = sp.getString('nama_warga') ?? 'Warga';
      String? phone = sp.getString('warga_phone');
      String? alamat = sp.getString('warga_alamat');
      _isProfilLengkap = (phone != null && phone.isNotEmpty) && (alamat != null && alamat.isNotEmpty);
      if (_isProfilLengkap) {
        _phoneCtrl.text = phone!;
        _alamatCtrl.text = alamat!;
        _rtRwCtrl.text = sp.getString('warga_rtrw') ?? 'RT 10 / RW 04';
      }
    });
  }

  Future<void> _simpanProfilWarga() async {
    if (_phoneCtrl.text.isEmpty || _alamatCtrl.text.isEmpty || _rtRwCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Lengkapi biodata profil dahulu!'), backgroundColor: Colors.orange));
      return;
    }
    final sp = await SharedPreferences.getInstance();
    await sp.setString('warga_phone', _phoneCtrl.text);
    await sp.setString('warga_alamat', _alamatCtrl.text);
    await sp.setString('warga_rtrw', _rtRwCtrl.text);
    setState(() { _isProfilLengkap = true; });
  }

  Future<void> _refreshSuratList() async {
    final data = await DatabaseHelper.instance.getSurat();
    setState(() { _allSuratData = data; });
  }

  Future<void> _simpanSuratBaru() async {
    if (_selectedJenisSurat == null || _perihalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Lengkapi seluruh form pengajuan!'), backgroundColor: Colors.orange));
      return;
    }

    String detailTambahan = "";
    if (_selectedJenisSurat!.contains('Kartu Keluarga') || _selectedJenisSurat!.contains('NIK Baru')) {
      detailTambahan = "\n(No. KK: ${_noKkCtrl.text})";
    } else if (_selectedJenisSurat!.contains('Akta Kelahiran') || _selectedJenisSurat!.contains('Akta Kematian')) {
      detailTambahan = "\n(Nama Anggota: ${_namaAnggotaCtrl.text})";
    } else if (_selectedJenisSurat!.contains('Izin Usaha')) {
      detailTambahan = "\n(Nama Usaha: ${_namaUsahaCtrl.text})";
    }
    
    await DatabaseHelper.instance.insertSurat({
      'jenis_surat': _selectedJenisSurat!,
      'tujuan_surat': '-',
      'perihal': "${_perihalCtrl.text}$detailTambahan",
    });
    
    _perihalCtrl.clear(); _noKkCtrl.clear(); _namaAnggotaCtrl.clear(); _namaUsahaCtrl.clear();
    _selectedJenisSurat = null;
    _refreshSuratList();
    setState(() { _currentTabIndex = 1; });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBodyView;
    if (!_isProfilLengkap) {
      currentBodyView = _buildProfilView();
    } else {
      if (_currentTabIndex == 0) currentBodyView = _buildFormSuratView();
      else if (_currentTabIndex == 1) currentBodyView = _buildListProsesView();
      else currentBodyView = const Center(child: Text('Arsip dokumen selesai kosong.'));
    }

    return Scaffold(
      body: currentBodyView,
      bottomNavigationBar: !_isProfilLengkap ? null : BottomNavigationBar(
        currentIndex: _currentTabIndex,
        selectedItemColor: const Color(0xFF6366F1),
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Ajukan Surat'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_late), label: 'Sedang Diproses'),
        ],
      ),
    );
  }

  Widget _buildProfilView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text('Lengkapi Profil Sebelum Mengajukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'No. WhatsApp', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _rtRwCtrl, decoration: const InputDecoration(labelText: 'RT / RW', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _alamatCtrl, decoration: const InputDecoration(labelText: 'Alamat Rumah KTP', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: _simpanProfilWarga, child: const Text('AKTIFKAN LAYANAN SURAT')))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSuratView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajukan Surat Digital', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedJenisSurat,
                hint: const Text('Pilih Jenis Surat'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _opsiSuratHalloWarga.map((jenis) => DropdownMenuItem(value: jenis, child: Text(jenis, style: const TextStyle(fontSize: 11)))).toList(),
                onChanged: (val) => setState(() => _selectedJenisSurat = val),
              ),
              const SizedBox(height: 16),

              if (_selectedJenisSurat != null) ...[
                if (_selectedJenisSurat!.contains('Kartu Keluarga') || _selectedJenisSurat!.contains('NIK Baru')) ...[
                  TextField(controller: _noKkCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nomor Kartu Keluarga (KK)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                ] else if (_selectedJenisSurat!.contains('Akta Kelahiran') || _selectedJenisSurat!.contains('Akta Kematian')) ...[
                  TextField(controller: _namaAnggotaCtrl, decoration: const InputDecoration(labelText: 'Nama Anggota Keluarga Terkait', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                ] else if (_selectedJenisSurat!.contains('Izin Usaha')) ...[
                  TextField(controller: _namaUsahaCtrl, decoration: const InputDecoration(labelText: 'Nama Jenis Usaha / Toko', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                ],
              ],

              TextField(controller: _perihalCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Perihal / Alasan Utama Pengajuan', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: _simpanSuratBaru, child: const Text('KIRIM PERMOHONAN')))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListProsesView() {
    return _allSuratData.isEmpty
        ? const Center(child: Text('Belum ada surat aktif.'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _allSuratData.length,
            itemBuilder: (context, idx) {
              final srt = _allSuratData[idx];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.hourglass_bottom, color: Colors.orange),
                  title: Text(srt['jenis_surat'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text("Keterangan:\n${srt['perihal']}", style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => DatabaseHelper.instance.deleteData('surat', srt['id']).then((_) => _refreshSuratList())),
                ),
              );
            },
          );
  }
}