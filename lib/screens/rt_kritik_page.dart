import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';

class RtKritikPage extends StatefulWidget {
  const RtKritikPage({super.key});

  @override
  State<RtKritikPage> createState() => _RtKritikPageState();
}

class _RtKritikPageState extends State<RtKritikPage> {
  List<Map<String, dynamic>> _allKritikData = [];

  @override
  void initState() {
    super.initState();
    _refreshKritikList();
  }

  Future<void> _refreshKritikList() async {
    final data = await DatabaseHelper.instance.getKritik();
    setState(() { _allKritikData = data; });
  }

  // ✓ ADDED: Handle status change
  Future<void> _updateStatus(int id, String newStatus) async {
    await DatabaseHelper.instance.updateKritikStatus(id, newStatus);
    await _refreshKritikList();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status laporan diperbarui menjadi: $newStatus'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _allKritikData.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0), 
                      child: Text('Belum ada laporan atau kritik masuk.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                    )
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _allKritikData.length,
                    itemBuilder: (context, idx) {
                      final kritik = _allKritikData[idx];
                      final statusLaporan = kritik['status_laporan'] ?? 'Belum ditangani';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✓ HEADER: Judul + Status Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      kritik['judul_keluhan'] ?? 'Tanpa Judul',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // ✓ ADDED: Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusLaporan == 'Selesai' ? Colors.green[100] : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: statusLaporan == 'Selesai' ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                    child: Text(
                                      statusLaporan,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusLaporan == 'Selesai' ? Colors.green[700] : Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // ✓ INFO: Pelapor & Tanggal
                              Text(
                                'Pelapor: ${kritik['nama_pelapor'] ?? '-'}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Tanggal: ${kritik['tanggal_lapor'] != null ? kritik['tanggal_lapor'].toString().substring(0, 10) : '-'}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              
                              // ✓ CONTENT: Isi Kritik
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  kritik['isi_critic'] ?? '-',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // ✓ ADDED: Dropdown Status Update
                              DropdownButton<String>(
                                value: statusLaporan,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Belum ditangani',
                                    child: Text('Belum ditangani'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Selesai',
                                    child: Text('Selesai'),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue != statusLaporan) {
                                    _updateStatus(kritik['id'], newValue);
                                  }
                                },
                                underline: Container(
                                  height: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
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

