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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(kritik['judul_keluhan'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Pelapor: ${kritik['nama_pelapor'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text('Tanggal: ${kritik['tanggal_lapor'] != null ? kritik['tanggal_lapor'].toString().substring(0, 10) : '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text(kritik['isi_critic'] ?? '-', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          isThreeLine: true,
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
