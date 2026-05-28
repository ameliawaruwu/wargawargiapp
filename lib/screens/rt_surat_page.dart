import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';

class RtSuratPage extends StatefulWidget {
  const RtSuratPage({super.key});

  @override
  State<RtSuratPage> createState() => _RtSuratPageState();
}

class _RtSuratPageState extends State<RtSuratPage> {
  int _currentTabIndex = 0;
  List<Map<String, dynamic>> _allSuratData = [];

  @override
  void initState() {
    super.initState();
    _refreshSuratList();
  }

  Future<void> _refreshSuratList() async {
    final data = await DatabaseHelper.instance.getSurat();
    setState(() { _allSuratData = data; });
  }

  void _prosesSurat(Map<String, dynamic> surat) {
    final _pdfCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Proses Surat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pemohon: ${surat['nama_pemohon']}'),
            const SizedBox(height: 8),
            Text('Jenis: ${surat['jenis_surat']}'),
            const SizedBox(height: 16),
            TextField(
              controller: _pdfCtrl,
              decoration: const InputDecoration(
                labelText: 'Link / Base64 File PDF',
                border: OutlineInputBorder(),
                hintText: 'Simulasi upload soft file PDF'
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_pdfCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap masukkan file PDF'))
                );
                return;
              }
              await DatabaseHelper.instance.updateSuratStatus(surat['id'], 'Selesai', filePdf: _pdfCtrl.text);
              Navigator.pop(ctx);
              _refreshSuratList();
            },
            child: const Text('Tandai Selesai'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentTabIndex == 0 ? 'Surat Masuk RT (Pending)' : 'Arsip Surat Selesai';
    final subtitle = _currentTabIndex == 0
        ? 'Periksa permohonan surat dari warga dan unggah file PDF untuk diproses.'
        : 'Riwayat pengajuan surat yang telah selesai diproses.';

    List<Map<String, dynamic>> displayedSurat = _allSuratData.where((s) {
      String status = s['status_surat'] ?? 'Pending';
      if (_currentTabIndex == 0) return status == 'Pending';
      return status == 'Selesai';
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            displayedSurat.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0), 
                      child: Text(_currentTabIndex == 0 ? 'Tidak ada surat masuk.' : 'Belum ada arsip surat selesai.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))
                    )
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedSurat.length,
                    itemBuilder: (context, idx) {
                      final srt = displayedSurat[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(srt['jenis_surat'] ?? 'Surat RT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Pemohon: ${srt['nama_pemohon'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text('Tanggal: ${srt['tanggal_aju'] != null ? srt['tanggal_aju'].toString().substring(0, 10).split('-').reversed.join('-') : '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text(srt['perihal'] ?? '-', style: const TextStyle(fontSize: 12)),
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
                                      onPressed: () => _prosesSurat(srt),
                                      icon: const Icon(Icons.description, size: 16),
                                      label: const Text('Proses Surat'),
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
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Surat Masuk'),
          BottomNavigationBarItem(icon: Icon(Icons.archive), label: 'Selesai'),
        ],
      ),
    );
  }
}
