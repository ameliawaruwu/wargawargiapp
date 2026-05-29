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
    setState(() {
      _allSuratData = data;
    });
  }

  void _prosesSurat(Map<String, dynamic> surat) {
    final _pdfCtrl = TextEditingController();
    final _notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.65,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Proses Pengajuan Surat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Review detail surat dan upload file PDF untuk menyelesaikan permohonan.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow('Pemohon', surat['nama_pemohon'] ?? '-'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Jenis Surat', surat['jenis_surat'] ?? '-'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Perihal', surat['perihal'] ?? '-'),
                    const SizedBox(height: 22),
                    const Text(
                      'Catatan Proses',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesCtrl,
                      minLines: 4,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan catatan atau instruksi pemrosesan…',
                        filled: true,
                        fillColor: const Color(0xFFF7F9FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Upload File PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 26,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.25),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                          color: const Color(0xFFF7F9FD),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              size: 32,
                              color: AppColors.primary.withOpacity(0.9),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Drag & drop PDF atau klik untuk masukkan nama file',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _pdfCtrl.text.isEmpty
                                  ? 'Belum ada file dipilih'
                                  : _pdfCtrl.text,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _pdfCtrl,
                              decoration: InputDecoration(
                                hintText: 'Masukkan nama file PDF',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.25),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_pdfCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Harap masukkan file PDF'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              await DatabaseHelper.instance.updateSuratStatus(
                                surat['id'],
                                'Selesai',
                                filePdf: _pdfCtrl.text,
                              );
                              Navigator.pop(ctx);
                              _refreshSuratList();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 6,
                              shadowColor: AppColors.secondary.withOpacity(0.3),
                            ),
                            child: const Text(
                              'Tandai Selesai',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentTabIndex == 0
        ? 'Surat Masuk RT'
        : 'Arsip Surat Selesai';
    final subtitle = _currentTabIndex == 0
        ? 'Kelola permohonan warga dengan antarmuka modern.'
        : 'Riwayat pengajuan surat yang telah selesai diproses.';

    final displayedSurat = _allSuratData.where((s) {
      final status = (s['status_surat'] ?? 'Pending').toString();
      return _currentTabIndex == 0 ? status == 'Pending' : status == 'Selesai';
    }).toList();

    final pendingCount = _allSuratData
        .where((s) => (s['status_surat'] ?? 'Pending').toString() == 'Pending')
        .length;
    final processingCount = _allSuratData.where((s) {
      final status = (s['status_surat'] ?? 'Pending').toString().toLowerCase();
      return status == 'diproses' || status == 'proses';
    }).length;
    final doneCount = _allSuratData
        .where((s) => (s['status_surat'] ?? 'Pending').toString() == 'Selesai')
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: SingleChildScrollView(
            key: ValueKey<int>(_currentTabIndex),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(title, subtitle),
                const SizedBox(height: 20),
                _buildSummarySection(pendingCount, processingCount, doneCount),
                const SizedBox(height: 20),
                displayedSurat.isEmpty
                    ? _buildEmptyState()
                    : _buildSuratList(displayedSurat),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 14,
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            label: 'Surat Masuk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.archive_outlined),
            label: 'Selesai',
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF4E6AF0), Color(0xFF6F65FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.grading_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(int pending, int processing, int done) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            'Pending',
            pending,
            const Color(0xFFFFF4E5),
            const Color(0xFFB36B00),
            Icons.access_time,
          ),
          _buildSummaryCard(
            'Diproses',
            processing,
            const Color(0xFFD8E9FF),
            const Color(0xFF2467A9),
            Icons.autorenew,
          ),
          _buildSummaryCard(
            'Selesai',
            done,
            const Color(0xFFDFF4E5),
            const Color(0xFF2C7A3B),
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    int value,
    Color background,
    Color accent,
    IconData icon,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: accent.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuratList(List<Map<String, dynamic>> displayedSurat) {
    return Column(
      children: displayedSurat.map((srt) {
        final status = (srt['status_surat'] ?? 'Pending').toString();
        return _buildSuratCard(srt, status);
      }).toList(),
    );
  }

  Widget _buildSuratCard(Map<String, dynamic> srt, String status) {
    final isSelesai = status == 'Selesai';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    srt['jenis_surat'] ?? 'Surat RT',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    srt['nama_pemohon'] ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  srt['tanggal_aju'] != null
                      ? srt['tanggal_aju']
                            .toString()
                            .substring(0, 10)
                            .split('-')
                            .reversed
                            .join('-')
                      : '-',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              srt['perihal'] ?? '-',
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
            if (!isSelesai) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _prosesSurat(srt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Proses Surat',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.toLowerCase();
    Color background;
    Color textColor;

    if (normalized == 'selesai') {
      background = const Color(0xFFDFF4E5);
      textColor = const Color(0xFF2C7A3B);
    } else if (normalized == 'diproses' || normalized == 'proses') {
      background = const Color(0xFFD8E9FF);
      textColor = const Color(0xFF2467A9);
    } else if (normalized == 'ditolak') {
      background = const Color(0xFFFDE8E8);
      textColor = const Color(0xFFB22222);
    } else {
      background = const Color(0xFFFFF3DB);
      textColor = const Color(0xFFB36B00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = _currentTabIndex == 0
        ? 'Belum Ada Surat Masuk'
        : 'Belum Ada Arsip Surat Selesai';
    final details = _currentTabIndex == 0
        ? 'Semua pengajuan warga sudah diproses.'
        : 'Riwayat selesai akan tampil di sini ketika surat selesai diproses.';
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.insert_drive_file_outlined,
                size: 56,
                color: Color(0xFFB0BEC5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              details,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
