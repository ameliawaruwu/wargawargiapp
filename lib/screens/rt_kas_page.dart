import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';

class RtKasPage extends StatefulWidget {
  const RtKasPage({super.key});

  @override
  State<RtKasPage> createState() => _RtKasPageState();
}

class _RtKasPageState extends State<RtKasPage> {
  int _currentTabIndex = 0;
  List<Map<String, dynamic>> _allKasData = [];

  @override
  void initState() {
    super.initState();
    _refreshKasList();
  }

  Future<void> _refreshKasList() async {
    final data = await DatabaseHelper.instance.getKas();
    setState(() { _allKasData = data; });
  }

  void _approveKas(Map<String, dynamic> kas) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Pembayaran'),
        content: Text('Apakah Anda yakin ingin menyetujui pembayaran kas dari ${kas['nama_warga']} sebesar Rp ${kas['jumlah_nominal']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await DatabaseHelper.instance.updateKasStatus(kas['id'], 'Lunas');
              Navigator.pop(ctx);
              _refreshKasList();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pembayaran berhasil disetujui'))
              );
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Setujui'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentTabIndex == 0 ? 'Menunggu Approval (Pending)' : 'Riwayat Kas (Lunas)';
    
    List<Map<String, dynamic>> displayedKas = _allKasData.where((k) {
      String status = k['status_verifikasi'] ?? 'Pending';
      if (_currentTabIndex == 0) return status == 'Pending';
      return status == 'Lunas';
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            displayedKas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0), 
                      child: Text('Tidak ada data.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))
                    )
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedKas.length,
                    itemBuilder: (context, idx) {
                      final kas = displayedKas[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text("${kas['jenis_iuran']} - Rp ${kas['jumlah_nominal']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Warga: ${kas['nama_warga'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text('Periode: ${kas['bulan_periode'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  Text("Tipe: ${kas['tipe_transaksi']}", style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: _currentTabIndex == 1 ? const Icon(Icons.check_circle, color: Colors.green) : null,
                            ),
                            if (_currentTabIndex == 0) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _approveKas(kas),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Setujui Pembayaran'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ]
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        selectedItemColor: AppColors.secondary,
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Pending'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}
