import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';
import 'profil_screen.dart';

class BerandaPage extends StatefulWidget {
  final String namaWarga;
  final String roleUser;

  const BerandaPage({
    super.key, 
    required this.namaWarga, 
    required this.roleUser
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _totalSaldo = 0;
  int _totalMasuk = 0;
  int _totalKeluar = 0;
  List<Map<String, dynamic>> _aktivitasTerakhir = [];
  bool _isCalculated = false;
  String _namaWarga = '';
  String _roleUser = '';
  String? _fotoProfilBase64;

  @override
  void initState() {
    super.initState();
    _loadProfileInfo();
    _hitungMekanismeFinansial();
  }

  Future<void> _loadProfileInfo() async {
    final sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _namaWarga = sp.getString('nama_warga') ?? '';
        _roleUser = sp.getString('role_user') ?? '';
        final nik = sp.getString('nik') ?? '';
        _fotoProfilBase64 = sp.getString('foto_profil_$nik');
      });
    }
  }

  Future<void> _hitungMekanismeFinansial() async {
    try {
      final dataKas = await DatabaseHelper.instance.getKas();
      int masuk = 0;
      int keluar = 0;
      
      for (var item in dataKas) {
        int nominal = int.tryParse(item['jumlah_nominal'].toString()) ?? 0;
        if (item['tipe_transaksi'] == 'MASUK') {
          masuk += nominal;
        } else if (item['tipe_transaksi'] == 'KELUAR') {
          keluar += nominal;
        }
      }
      
      if (mounted) {
        setState(() {
          _totalMasuk = masuk;
          _totalKeluar = keluar;
          _totalSaldo = masuk - keluar;
          _aktivitasTerakhir = dataKas.take(3).toList();
          _isCalculated = true;
        });
      }
    } catch (e) {
      debugPrint("Eror kalkulasi kas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _hitungMekanismeFinansial,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HEADER PROFIL ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilScreen())).then((_) => _loadProfileInfo());
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          backgroundImage: _fotoProfilBase64 != null ? MemoryImage(base64Decode(_fotoProfilBase64!)) : null,
                          child: _fotoProfilBase64 == null ? const Icon(Icons.person, color: Colors.white, size: 26) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _namaWarga.isEmpty ? (widget.namaWarga.isEmpty ? "Warga Mandiri" : widget.namaWarga) : _namaWarga,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_roleUser.isEmpty ? widget.roleUser : _roleUser) == "Pengurus RT"
                                  ? AppColors.primary.withOpacity(0.14)
                                  : AppColors.secondary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _roleUser.isEmpty ? (widget.roleUser.isEmpty ? "Warga Mandiri" : widget.roleUser) : _roleUser, 
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                color: (_roleUser.isEmpty ? widget.roleUser : _roleUser) == "Pengurus RT" ? AppColors.primary : AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.notifications_none_rounded, color: AppColors.secondary),
                ],
              ),
              
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_roleUser.isEmpty ? widget.roleUser : _roleUser) == 'Pengurus RT'
                          ? 'Dashboard Pengurus RT'
                          : 'Dashboard Warga Mandiri',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_roleUser.isEmpty ? widget.roleUser : _roleUser) == 'Pengurus RT'
                          ? 'Kelola pengajuan surat, kas RT, dan keluhan warga di lingkungan.'
                          : 'Pantau kas lingkunganmu dan ajukan layanan administrasi secara cepat.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text('Total Saldo Kas: Rp $_totalSaldo', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat("Masuk", _totalMasuk, Icons.arrow_downward, Colors.greenAccent),
                        _buildMiniStat("Keluar", _totalKeluar, Icons.arrow_upward, Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Area prioritas saat ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: 'Iuran RT'),
                        _InfoChip(label: 'Surat Warga'),
                        _InfoChip(label: 'Keluhan & Saran'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDashboardAction(
                    icon: Icons.edit_document,
                    label: 'Dokumen Surat',
                    description: (_roleUser.isEmpty ? widget.roleUser : _roleUser) == 'Pengurus RT'
                        ? 'Surat Masuk RT'
                        : 'Ajukan surat warga',
                  ),
                  _buildDashboardAction(
                    icon: Icons.account_balance_wallet,
                    label: 'Kas Lingkungan',
                    description: 'Pantau saldo dan mutasi kas',
                  ),
                  _buildDashboardAction(
                    icon: Icons.chat_bubble,
                    label: 'Kritik & Saran',
                    description: 'Layanan aduan warga',
                  ),
                  _buildDashboardAction(
                    icon: Icons.person,
                    label: 'Profil',
                    description: 'Data dan foto Anda',
                  ),
                ],
              ),
  
              const SizedBox(height: 24),
              const Text('Aktivitas Terkini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              // === LIST RIWAYAT ===
              _aktivitasTerakhir.isEmpty 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 8),
                      Text('Belum ada data aktivitas kas.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      SizedBox(height: 8),
                      Text('Transaksi masuk dapat berupa iuran RT, sumbangan, atau dana kegiatan masyarakat.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  )
                : Column(
                    children: _aktivitasTerakhir.map((log) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(log['nama_warga'] ?? 'Warga', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            "${log['tipe_transaksi'] == 'MASUK' ? '+' : '-'} Rp ${log['jumlah_nominal']}",
                            style: TextStyle(
                              color: log['tipe_transaksi'] == 'MASUK' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold
                            ),
                          )
                        ],
                      ),
                    )).toList(),
                  )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardAction({required IconData icon, required String label, required String description}) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gunakan menu bawah untuk membuka $label.'), backgroundColor: AppColors.primary),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 72) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int nilai, IconData icon, Color warna) {
    return Row(
      children: [
        Icon(icon, color: warna, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text('Rp $nilai', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}