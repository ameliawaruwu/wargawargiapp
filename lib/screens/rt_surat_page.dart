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
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allSuratData = [];

  List<String> get _filterOptions =>
      _currentTabIndex == 0
          ? ['Semua', 'Pending', 'Diproses']
          : ['Semua', 'Disetujui', 'Ditolak'];

  bool _isInMasuk(String status) {
    final s = status.toLowerCase();
    return s == 'pending' || s == 'diproses';
  }

  bool _isInArsip(String status) {
    final s = status.toLowerCase();
    return s == 'disetujui' || s == 'ditolak';
  }

  List<Map<String, dynamic>> get _baseList =>
      _allSuratData.where((s) {
        final st = (s['status_surat'] ?? 'Pending').toString();
        return _currentTabIndex == 0 ? _isInMasuk(st) : _isInArsip(st);
      }).toList();

  int _countByFilter(String filter) {
    if (filter == 'Semua') return _baseList.length;
    return _baseList.where((s) {
      final st = (s['status_surat'] ?? '').toString().toLowerCase();
      return st == filter.toLowerCase();
    }).length;
  }

  List<Map<String, dynamic>> get displayedSurat {
    var list = _selectedFilter == 'Semua'
        ? _baseList
        : _baseList.where((s) {
            final st = (s['status_surat'] ?? '').toString().toLowerCase();
            return st == _selectedFilter.toLowerCase();
          }).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        return (s['jenis_surat'] ?? '').toString().toLowerCase().contains(q) ||
            (s['nama_pemohon'] ?? '').toString().toLowerCase().contains(q) ||
            (s['perihal'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _refreshSuratList();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshSuratList() async {
    final data = await DatabaseHelper.instance.getSurat();
    setState(() => _allSuratData = data);
  }

  void _onTabChanged(int index) => setState(() {
        _currentTabIndex = index;
        _selectedFilter = 'Semua';
        _searchQuery = '';
        _searchCtrl.clear();
      });

  // ── Dialog konfirmasi tolak ───────────────────────────────────────────
  Future<void> _konfirmasiTolak(Map<String, dynamic> srt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: Color(0xFFB22222),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tolak Surat Ini?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Surat "${srt['jenis_surat'] ?? 'ini'}" atas nama '
              '${srt['nama_pemohon'] ?? '-'} akan ditolak dan '
              'dipindahkan ke Arsip. Tindakan ini tidak dapat dibatalkan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tolak',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.updateSuratStatus(srt['id'], 'Ditolak');
      await _refreshSuratList();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Surat telah ditolak'),
            backgroundColor: Color(0xFFB22222),
          ),
        );
      }
    }
  }

  // ── Bottom sheet: proses surat ────────────────────────────────────────
  void _prosesSurat(Map<String, dynamic> surat) {
    final pdfCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.65,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: sc,
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
                  controller: notesCtrl,
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
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 26, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                      width: 1.5,
                    ),
                    color: const Color(0xFFF7F9FD),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        size: 32,
                        color: AppColors.primary.withOpacity(0.9),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Masukkan nama file PDF di bawah ini',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: pdfCtrl,
                        builder: (_, val, __) => Text(
                          val.text.isEmpty ? 'Belum ada file dipilih' : val.text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: val.text.isEmpty
                                ? AppColors.textSecondary
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pdfCtrl,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama file PDF',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ],
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
                              color: AppColors.primary.withOpacity(0.25)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
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
                          if (pdfCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Harap masukkan nama file PDF'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          await DatabaseHelper.instance.updateSuratStatus(
                            surat['id'],
                            'Disetujui',
                            filePdf: pdfCtrl.text.trim(),
                          );
                          Navigator.pop(ctx);
                          _refreshSuratList();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          elevation: 6,
                          shadowColor:
                              AppColors.secondary.withOpacity(0.3),
                        ),
                        child: const Text(
                          'Tandai Disetujui',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final title =
        _currentTabIndex == 0 ? 'Surat Masuk RT' : 'Arsip Surat';
    final subtitle = _currentTabIndex == 0
        ? 'Kelola permohonan warga — pending & sedang diproses.'
        : 'Riwayat surat yang sudah disetujui atau ditolak.';

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
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterChips(),
                const SizedBox(height: 16),
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
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 14,
        onTap: _onTabChanged,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined), label: 'Surat Masuk'),
          BottomNavigationBarItem(
              icon: Icon(Icons.archive_outlined), label: 'Arsip'),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchCtrl,
        style:
            const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari surat atau keperluan...',
          hintStyle:
              TextStyle(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon:
              Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(Icons.close,
                      color: Colors.grey.shade400, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // ── Filter chips kotak ────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = _filterOptions[i];
          final isSelected = _selectedFilter == option;
          final count = _countByFilter(option);

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1B3A6B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B3A6B)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.22)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 12))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1)),
                const SizedBox(height: 10),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.6)),
              ],
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.grading_outlined,
                color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }

  Widget _buildSuratList(List<Map<String, dynamic>> list) {
    return Column(
      children: list.map((srt) {
        final status = (srt['status_surat'] ?? 'Pending').toString();
        return _buildSuratCard(srt, status);
      }).toList(),
    );
  }

  Widget _buildSuratCard(Map<String, dynamic> srt, String status) {
    final st = status.toLowerCase();
    final isArchived = st == 'disetujui' || st == 'ditolak';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10))
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
                        color: AppColors.textPrimary),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(srt['nama_pemohon'] ?? '-',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 16, color: AppColors.textSecondary),
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
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ]),
            const SizedBox(height: 14),
            Text(srt['perihal'] ?? '-',
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.textPrimary)),
            // File PDF — hanya tampil jika Disetujui
            if (st == 'disetujui' &&
                (srt['file_pdf'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.picture_as_pdf,
                    size: 16, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(srt['file_pdf'],
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600))),
              ]),
            ],
            // Tombol aksi — hanya di Surat Masuk
            if (!isArchived) ...[
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    // ✅ Panggil dialog konfirmasi dulu
                    onPressed: () => _konfirmasiTolak(srt),
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Tolak',
                        style:
                            TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _prosesSurat(srt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    child: const Text('Proses',
                        style:
                            TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final n = status.toLowerCase();
    Color bg, fg;
    if (n == 'disetujui') {
      bg = const Color(0xFFDFF4E5);
      fg = const Color(0xFF2C7A3B);
    } else if (n == 'diproses') {
      bg = const Color(0xFFD8E9FF);
      fg = const Color(0xFF2467A9);
    } else if (n == 'ditolak') {
      bg = const Color(0xFFFDE8E8);
      fg = const Color(0xFFB22222);
    } else {
      bg = const Color(0xFFFFF3DB);
      fg = const Color(0xFFB36B00);
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(18)),
      child: Text(status,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    final message = isSearching
        ? 'Hasil Tidak Ditemukan'
        : (_selectedFilter != 'Semua'
            ? 'Tidak Ada Surat "$_selectedFilter"'
            : (_currentTabIndex == 0
                ? 'Tidak Ada Pekerjaan Aktif'
                : 'Belum Ada Arsip'));
    final details = isSearching
        ? 'Tidak ditemukan surat untuk "$_searchQuery".'
        : (_selectedFilter != 'Semua'
            ? 'Tidak ada surat berstatus $_selectedFilter saat ini.'
            : (_currentTabIndex == 0
                ? 'Semua surat sudah disetujui atau ditolak.'
                : 'Surat yang disetujui/ditolak akan muncul di sini.'));

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(children: [
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
                    offset: const Offset(0, 12))
              ],
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_outlined
                  : Icons.insert_drive_file_outlined,
              size: 56,
              color: const Color(0xFFB0BEC5),
            ),
          ),
          const SizedBox(height: 24),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(details,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6)),
        ]),
      ),
    );
  }
}