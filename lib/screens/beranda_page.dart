import 'package:flutter/material.dart';
import '../data/database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _hitungMekanismeFinansial();
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
      backgroundColor: const Color(0xFFF8FAFC),
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
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF6366F1),
                        child: Icon(Icons.person, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.namaWarga.isEmpty ? "Warga Mandiri" : widget.namaWarga,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.roleUser == "Pengurus RT" ? Colors.orange[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.roleUser.isEmpty ? "Warga Mandiri" : widget.roleUser, 
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                color: widget.roleUser == "Pengurus RT" ? Colors.orange[700] : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
                ],
              ),
              
              const SizedBox(height: 24),

              // === CARD KAS UNGU ===
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Saldo Kas Lingkungan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('Rp $_totalSaldo', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat("Masuk", _totalMasuk, Icons.arrow_downward, Colors.greenAccent),
                        _buildMiniStat("Keluar", _totalKeluar, Icons.arrow_upward, Colors.redAccent),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('Aktivitas Terkini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),

              // === LIST RIWAYAT ===
              _aktivitasTerakhir.isEmpty 
                ? const Text("Belum ada data aktivitas kas.", style: TextStyle(color: Colors.grey, fontSize: 13)) 
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