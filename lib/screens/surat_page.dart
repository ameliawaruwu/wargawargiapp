import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';

class SuratPage extends StatefulWidget {
  const SuratPage({super.key});

  @override
  State<SuratPage> createState() => _SuratPageState();
}

class _SuratPageState extends State<SuratPage> {
  int _currentTabIndex = 0;
  List<Map<String, dynamic>> _allSuratData = [];
  String _namaWarga = '';
  String _roleUser = '';
  String _nik = '-';
  String _phoneWarga = '-';
  String _alamatWarga = '-';

  String _searchQuery = "";
  String _selectedCategory = "SEMUA"; 
  final List<String> _categories = ["SEMUA", "PENDING", "DIPROSES", "DISETUJUI", "DITOLAK"];

  String? _selectedJenisSurat;
  final _perihalCtrl = TextEditingController();

  final _noKkCtrl = TextEditingController();
  final _namaAnggotaCtrl = TextEditingController();
  final _namaUsahaCtrl = TextEditingController();
  final _pekerjaanCtrl = TextEditingController();
  String? _selectedStatusKawin;
  final List<String> _opsiStatusKawin = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];

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
    _loadSuratSession();
  }

  @override
  void dispose() {
    _perihalCtrl.dispose();
    _noKkCtrl.dispose();
    _namaAnggotaCtrl.dispose();
    _namaUsahaCtrl.dispose();
    _pekerjaanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuratSession() async {
    final sp = await SharedPreferences.getInstance();
    final storedNik = sp.getString('nik') ?? '';
    final role = sp.getString('role_user') ?? 'Warga Mandiri';

    if (storedNik.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByNik(storedNik);
      
      if (user != null) {
        setState(() {
          _nik = storedNik;
          _roleUser = role;
          _namaWarga = user['nama'] ?? 'Warga';
          _phoneWarga = user['warga_phone'] ?? '-';
          _alamatWarga = user['warga_alamat'] ?? '-';
          
          if (_roleUser == 'Pengurus RT') {
            _currentTabIndex = 1; 
          }
        });
      }
    }

    await _refreshSuratList();
  }

  Future<void> _refreshSuratList() async {
    final data = await DatabaseHelper.instance.getSurat(
      namaPemohon: _roleUser == 'Pengurus RT' ? null : _namaWarga,
    );
    setState(() {
      _allSuratData = data;
    });
  }

  Future<void> _simpanSuratBaru() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_selectedJenisSurat == null || _perihalCtrl.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('⚠️ Lengkapi seluruh form pengajuan!'), backgroundColor: Colors.orange),
      );
      return;
    }

    String detailTambahan = "";
    if (_selectedJenisSurat!.contains('Kartu Keluarga') || _selectedJenisSurat!.contains('NIK Baru')) {
      if (_noKkCtrl.text.isNotEmpty) detailTambahan += "\n• No. KK: ${_noKkCtrl.text}";
    } else if (_selectedJenisSurat!.contains('Akta Kelahiran') || _selectedJenisSurat!.contains('Akta Kematian')) {
      if (_namaAnggotaCtrl.text.isNotEmpty) detailTambahan += "\n• Nama Anggota: ${_namaAnggotaCtrl.text}";
    } else if (_selectedJenisSurat!.contains('Izin Usaha')) {
      if (_namaUsahaCtrl.text.isNotEmpty) detailTambahan += "\n• Nama Usaha: ${_namaUsahaCtrl.text}";
      if (_pekerjaanCtrl.text.isNotEmpty) detailTambahan += "\n• Pekerjaan: ${_pekerjaanCtrl.text}";
    } else if (_selectedJenisSurat!.contains('Nikah')) {
      if (_selectedStatusKawin != null) detailTambahan += "\n• Status Hubungan: $_selectedStatusKawin";
      if (_pekerjaanCtrl.text.isNotEmpty) detailTambahan += "\n• Pekerjaan: ${_pekerjaanCtrl.text}";
    } else if (_selectedJenisSurat!.contains('SKTM') || _selectedJenisSurat!.contains('SKCK') || _selectedJenisSurat!.contains('Domisili')) {
      if (_pekerjaanCtrl.text.isNotEmpty) detailTambahan += "\n• Pekerjaan Warga: ${_pekerjaanCtrl.text}";
    }

    await DatabaseHelper.instance.insertSurat({
      'nama_pemohon': _namaWarga,
      'jenis_surat': _selectedJenisSurat!,
      'perihal': "${_perihalCtrl.text}$detailTambahan",
      'tanggal_aju': DateTime.now().toString().substring(0, 10),
      'status_surat': 'Pending',
    });

    _perihalCtrl.clear();
    _noKkCtrl.clear();
    _namaAnggotaCtrl.clear();
    _namaUsahaCtrl.clear();
    _pekerjaanCtrl.clear();
    
    setState(() {
      _selectedStatusKawin = null;
      _selectedJenisSurat = null;
      _currentTabIndex = 1;
      _searchQuery = '';
      _selectedCategory = 'SEMUA';
    });

    await _refreshSuratList();
    
    messenger.showSnackBar(
      const SnackBar(content: Text('🚀 Pengajuan surat berhasil dikirim!'), backgroundColor: Colors.green),
    );
  }

  void _prosesSurat(Map<String, dynamic> surat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verifikasi Berkas Surat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Tentukan status validasi berkas dari ${surat['nama_pemohon']}.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await DatabaseHelper.instance.updateSuratStatus(surat['id'], 'Ditolak');
                        navigator.pop();
                        _refreshSuratList();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF5350),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text('TOLAK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await DatabaseHelper.instance.updateSuratStatus(surat['id'], 'Disetujui');
                        navigator.pop();
                        _refreshSuratList();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text('SETUJUI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _cetakPdfSurat(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("KORPS WARGA KABUPATEN BANDUNG", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text("RUKUN TETANGGA 10 / RUKUN WARGA 04", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Kecamatan Bojongsoang, Kabupaten Bandung, Jawa Barat", style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Container(height: 2, color: PdfColors.black),
                      pw.SizedBox(height: 24),
                    ]
                  )
                ),
                pw.Center(
                  child: pw.Text("SURAT KETERANGAN PENGANTAR", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                ),
                pw.Center(
                  child: pw.Text("Nomor: Ref/026/SRT/${data['id']}", style: const pw.TextStyle(fontSize: 11)),
                ),
                pw.SizedBox(height: 32),
                pw.Text("Yang bertanda tangan di bawah ini Ketua Rukun Tetangga 10 RW 04 Kabupaten Bandung, menerangkan bahwa:"),
                pw.SizedBox(height: 16),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [pw.SizedBox(width: 120, child: pw.Text("Nama Pemohon")), pw.Text(": ${data['nama_pemohon']}")]),
                      pw.SizedBox(height: 8),
                      pw.Row(children: [pw.SizedBox(width: 120, child: pw.Text("Jenis Layanan")), pw.Text(": ${data['jenis_surat']}")]),
                      pw.SizedBox(height: 8),
                      pw.Row(children: [pw.SizedBox(width: 120, child: pw.Text("Tanggal Ajuan")), pw.Text(": ${data['tanggal_aju']}")]),
                    ]
                  )
                ),
                pw.SizedBox(height: 20),
                pw.Text("Orang tersebut adalah warga kami berdomisili di lingkungan RT 10 / RW 04. Surat pengantar ini dibuat berdasarkan keperluan:"),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                  child: pw.Text(data['perihal'] ?? '-', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                ),
                pw.SizedBox(height: 16),
                pw.Text("Demikian surat pengantar keterangan digital ini dibuat agar dapat dipergunakan sebagaimana mestinya."),
                pw.SizedBox(height: 50),
                pw.Align(
                  alignment: pw.Alignment.topRight,
                  child: pw.Column(
                    children: [
                      pw.Text("Bandung, ${data['tanggal_aju']}"),
                      pw.Text("Ketua RT 10 / RW 04"),
                      pw.SizedBox(height: 40),
                      pw.Text("PENGURUS RT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("[ TTD Digital Sistem ]", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ]
                  )
                )
              ]
            )
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  bool get _isWargaMandiri => _roleUser == 'Warga Mandiri';

  @override
  Widget build(BuildContext context) {
    Widget currentBodyView;

    if (_currentTabIndex == 0) {
      currentBodyView = _isWargaMandiri ? _buildFormSuratView() : _buildAksesTertutupView();
    } else {
      currentBodyView = _buildListProsesView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: currentBodyView,
      bottomNavigationBar: (_roleUser == 'Pengurus RT'
          ? null
          : Container(
              decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -2))]),
              child: BottomNavigationBar(
                currentIndex: _currentTabIndex,
                selectedItemColor: const Color(0xFF2A3890),
                unselectedItemColor: Colors.grey.shade400,
                backgroundColor: Colors.white,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                onTap: (index) => setState(() => _currentTabIndex = index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.maps_home_work_outlined), activeIcon: Icon(Icons.maps_home_work), label: 'Ajukan Surat'),
                  BottomNavigationBarItem(icon: Icon(Icons.folder_open_outlined), activeIcon: Icon(Icons.folder_shared), label: 'Status & Arsip'),
                ],
              ),
            )),
    );
  }

  Widget _buildFormSuratView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          _buildHeaderSection(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Pilih Jenis Dokumen',
                  subtitle: 'Pilih tipe draft surat resmi.',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedJenisSurat,
                    isExpanded: true,
                    decoration: _fieldDecoration(label: 'Tipe Layanan Surat', icon: Icons.assignment_outlined),
                    hint: const Text('Pilih jenis surat'),
                    items: _opsiSuratHalloWarga.map((jenis) => DropdownMenuItem(value: jenis, child: Text(jenis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedJenisSurat = val),
                  ),
                ),
                _buildSectionCard(
                  title: 'Keperluan / Perihal',
                  subtitle: 'Tulis tujuan pengajuan surat secara ringkas.',
                  child: _buildTextField(controller: _perihalCtrl, label: 'Maksud Pengajuan', hint: 'Contoh: Syarat klaim jaminan kesehatan.', icon: Icons.rate_review_outlined, maxLines: 3),
                ),
                _buildSectionCard(
                  title: 'Identitas Pemohon',
                  subtitle: 'Data profil warga dari sistem.',
                  child: _buildIdentityGrid(),
                ),
                if (_selectedJenisSurat != null) ...[
                  _buildSectionCard(
                    title: 'Lampiran Tambahan',
                    subtitle: 'Data wajib berdasarkan jenis surat.',
                    child: _buildAdditionalDetailField(),
                  ),
                ],
                const SizedBox(height: 12),
                _buildSubmitCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF2A3890)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Persuratan Digital', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Sistem Pengantar Berkas Online Warga', style: TextStyle(fontSize: 13, color: Colors.indigo.shade100)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.send_to_mobile_rounded, color: Colors.white, size: 24),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Akun Pengaju: $_namaWarga ($_roleUser)', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF2A3890), size: 18) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A3890), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: _fieldDecoration(label: label, icon: icon).copyWith(hintText: hint),
    );
  }

  Widget _buildIdentityGrid() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          _buildIdentityRow('NIK Pengaju', _nik, Icons.badge_outlined),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _buildIdentityRow('Nama Lengkap', _namaWarga, Icons.person_outline),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _buildIdentityRow('Alamat Tinggal', _alamatWarga, Icons.location_on_outlined),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _buildIdentityRow('No. WhatsApp', _phoneWarga, Icons.phone_android),
        ],
      ),
    );
  }

  Widget _buildIdentityRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '-', 
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailField() {
    if (_selectedJenisSurat == null) return const SizedBox.shrink();
    if (_selectedJenisSurat!.contains('Nikah')) {
      return Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedStatusKawin,
            isExpanded: true,
            decoration: _fieldDecoration(label: 'Status Perkawinan', icon: Icons.favorite_border),
            hint: const Text('Pilih status'),
            items: _opsiStatusKawin.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
            onChanged: (val) => setState(() => _selectedStatusKawin = val),
          ),
          const SizedBox(height: 16),
          _buildTextField(controller: _pekerjaanCtrl, label: 'Pekerjaan', hint: 'Contoh: Swasta', icon: Icons.work_outline),
        ],
      );
    }
    if (_selectedJenisSurat!.contains('SKTM') || _selectedJenisSurat!.contains('SKCK') || _selectedJenisSurat!.contains('Domisili')) {
      return _buildTextField(controller: _pekerjaanCtrl, label: 'Pekerjaan saat ini', hint: 'Contoh: Wiraswasta', icon: Icons.work_outline);
    }
    if (_selectedJenisSurat!.contains('Kartu Keluarga') || _selectedJenisSurat!.contains('NIK Baru')) {
      return _buildTextField(controller: _noKkCtrl, label: 'Nomor Kartu Keluarga', hint: 'Masukkan 16 digit No. KK', icon: Icons.credit_card_outlined, keyboardType: TextInputType.number);
    }
    if (_selectedJenisSurat!.contains('Akta Kelahiran') || _selectedJenisSurat!.contains('Akta Kematian')) {
      return _buildTextField(controller: _namaAnggotaCtrl, label: 'Nama Lengkap Anggota', hint: 'Nama yang bersangkutan', icon: Icons.people_outline);
    }
    if (_selectedJenisSurat!.contains('Izin Usaha')) {
      return Column(
        children: [
          _buildTextField(controller: _namaUsahaCtrl, label: 'Nama Usaha / Toko', hint: 'Contoh: Warung Sejahtera', icon: Icons.storefront_outlined),
          const SizedBox(height: 16),
          _buildTextField(controller: _pekerjaanCtrl, label: 'Pekerjaan Pemilik', hint: 'Contoh: Wiraswasta', icon: Icons.work_outline),
        ],
      );
    }
    return const Text('Informasi dasar sudah memadai.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13));
  }

  Widget _buildSubmitCard() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _simpanSuratBaru,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A3890), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: const Text('SUBMIT PERMOHONAN RESMI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
      ),
    );
  }

  Widget _buildListProsesView() {
    // 🛠️ PERBAIKAN LOGIKA FILTER: Diperbaiki total agar sinkron dan tampil sempurna
    final filteredData = _allSuratData.where((item) {
      final jenisSurat = (item['jenis_surat'] ?? '').toString().toLowerCase();
      final keperluan = (item['perihal'] ?? '').toString().toLowerCase();
      final statusSurat = (item['status_surat'] ?? 'Pending').toString().toUpperCase();
      
      // 1. Filter Pencarian Teks
      final matchesSearch = jenisSurat.contains(_searchQuery.toLowerCase()) || keperluan.contains(_searchQuery.toLowerCase());
      
      // 2. Filter Kategori Tab Menu Utama
      bool matchesCategory = false;
      if (_selectedCategory == "SEMUA") {
        matchesCategory = true;
      } else if (_selectedCategory == "DISETUJUI") {
        matchesCategory = (statusSurat == "DISETUJUI" || statusSurat == "SELESAI");
      } else {
        matchesCategory = (statusSurat == _selectedCategory);
      }
      
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text("Pelacakan Berkas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: "Cari surat atau keperluan...",
                    hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 38,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2A3890) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? const Color(0xFF2A3890) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filteredData.isEmpty
                  ? _buildEmptyArchiveState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredData.length,
                      itemBuilder: (context, idx) {
                        final srt = filteredData[idx];
                        final status = srt['status_surat'] ?? 'Pending';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A3890),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 14),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (srt['jenis_surat'] ?? 'SURAT PENGANTAR').toString().toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF2A3890), letterSpacing: -0.2),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${srt['tanggal_aju']} • ID: WG-${srt['id']}",
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                _buildStatusBadge(status),
                                const SizedBox(width: 8),

                                // Tampilkan tombol unduh jika status disetujui
                                (status.toString().toLowerCase() == 'disetujui' || status.toString().toLowerCase() == 'selesai')
                                    ? InkWell(
                                        onTap: () => _cetakPdfSurat(srt),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: const BoxDecoration(color: Color(0xFF2A3890), shape: BoxShape.circle),
                                          child: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                                        ),
                                      )
                                    : const SizedBox.shrink(),

                                if (_roleUser == 'Pengurus RT' && status.toString().toLowerCase() == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.gavel_rounded, color: Color(0xFF2A3890), size: 20),
                                    onPressed: () => _prosesSurat(srt),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyArchiveState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text('Dokumen tidak ditemukan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildAksesTertutupView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_person_outlined, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Formulir Warga Ditutup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color background;
    Color textColor;
    final normalized = status.toLowerCase();

    if (normalized == 'disetujui' || normalized == 'selesai') {
      background = const Color(0xFFE0E7FF);
      textColor = const Color(0xFF2A3890);
    } else if (normalized == 'ditolak') {
      background = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
    } else if (normalized == 'diproses') {
      background = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0369A1);
    } else {
      background = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFEF6C00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(
        normalized == 'disetujui' ? 'SELESAI' : status.toUpperCase(), 
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 0.5)
      ),
    );
  }
}