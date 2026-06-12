import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
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
  List<Map<String, dynamic>> _masterIuran = []; // ✓ NEW: Master iuran list
  late SharedPreferences _prefs;

  // Shared Preferences Keys
  static const String _tabIndexKey = 'rt_kas_tab_index';
  static const String _lastUpdateKey = 'rt_kas_last_update';

  // Form controllers untuk create kategori
  final _namaIuranController = TextEditingController();
  final _nominalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedTabIndex();
    _loadMasterIuran(); // ✓ NEW: Load master iuran
    _refreshKasList();
  }

  Future<void> _loadSavedTabIndex() async {
    setState(() {
      _currentTabIndex = _prefs.getInt(_tabIndexKey) ?? 0;
    });
  }

  Future<void> _saveTabIndex(int index) async {
    await _prefs.setInt(_tabIndexKey, index);
  }

  Future<void> _updateLastRefreshTime() async {
    await _prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }
// ✓ NEW: Load master iuran dari database
  Future<void> _loadMasterIuran() async {
    try {
      final data = await DatabaseHelper.instance.getMasterIuran();
      if (mounted) {
        setState(() {
          _masterIuran = data;
        });
      }
    } catch (e) {
      print('❌ Error loading master iuran: $e');
    }
  }

  // ✓ NEW: Create kategori iuran baru
  Future<void> _createMasterIuran(String namaIuran, String nominalWajib) async {
    try {
      await DatabaseHelper.instance.insertMasterIuran({
        'nama_iuran': namaIuran,
        'nominal_wajib': nominalWajib,
      });
      
      _loadMasterIuran(); // Reload list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('Kategori iuran berhasil ditambahkan!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✓ NEW: Show form dialog untuk create kategori iuran
  void _showCreateIuranDialog() {
    _namaIuranController.clear();
    _nominalController.clear();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_circle, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Buat Kategori Iuran Baru', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambahkan kategori iuran baru ke sistem:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              
              TextField(
                controller: _namaIuranController,
                decoration: InputDecoration(
                  labelText: 'Nama Kategori Iuran',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.category, color: AppColors.secondary),
                  hintText: 'Contoh: Iuran Listrik',
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal Wajib (Rp)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.secondary),
                  hintText: 'Contoh: 50000',
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Nominal ini akan menjadi default untuk dropdown kategori iuran di halaman warga',
                        style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (_namaIuranController.text.isEmpty || _nominalController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Semua field harus diisi!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              _createMasterIuran(_namaIuranController.text, _nominalController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(Icons.add_circle, size: 18),
            label: const Text('Tambahkan'),
          )
        ],
      ),
    );
  }

  
  Future<void> _refreshKasList() async {
    final data = await DatabaseHelper.instance.getKas();
    await _updateLastRefreshTime();
    setState(() { _allKasData = data; });
  }

  void _shareKasData(Map<String, dynamic> kas) {
    final message = '''
📊 Laporan Pembayaran Kas
━━━━━━━━━━━━━━━━━━━━━━
Jenis Iuran: ${kas['jenis_iuran']}
Jumlah: Rp ${kas['jumlah_nominal']}
Warga: ${kas['nama_warga']}
Periode: ${kas['bulan_periode']}
Tipe: ${kas['tipe_transaksi']}
Status: ${kas['status_verifikasi']}
━━━━━━━━━━━━━━━━━━━━━━
Dibagikan melalui Warga Wargi App
    ''';
    
    Share.share(message, subject: 'Laporan Pembayaran Kas');
  }

  void _approveKas(Map<String, dynamic> kas) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Approve Pembayaran', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfirmasi persetujuan pembayaran kas:', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Nama:', kas['nama_warga'] ?? '-'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Jumlah:', 'Rp ${kas['jumlah_nominal']}', isAmount: true),
                  const SizedBox(height: 8),
                  _buildDetailRow('Iuran:', kas['jenis_iuran']),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Apakah Anda yakin ingin menyetujui pembayaran ini?',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await DatabaseHelper.instance.updateKasStatus(kas['id'], 'Lunas');
              Navigator.pop(ctx);
              _refreshKasList();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        const Text('Pembayaran berhasil disetujui!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Setujui'),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
              color: isAmount ? AppColors.primary : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _currentTabIndex == 0;
    
    List<Map<String, dynamic>> displayedKas = _allKasData.where((k) {
      String status = k['status_verifikasi'] ?? 'Pending';
      if (isPending) return status == 'Pending';
      return status == 'Lunas';
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshKasList,
        child: CustomScrollView(
          slivers: [
            // App Bar dengan gradient
            SliverAppBar(
              elevation: 0,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  isPending ? 'Pending Approval' : 'Riwayat Kas',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                centerTitle: false,
              ),
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: displayedKas.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPending ? Icons.inbox : Icons.history,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isPending ? 'Tidak ada pembayaran menunggu' : 'Riwayat kosong',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isPending ? 'Semua pembayaran telah diproses' : 'Belum ada riwayat pembayaran',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final kas = displayedKas[idx];
                          return _buildKasCard(kas, isPending);
                        },
                        childCount: displayedKas.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) async {
          await _saveTabIndex(index);
          setState(() => _currentTabIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: _currentTabIndex == 0
                  ? BoxDecoration(
                      color: AppColors.secondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: const Icon(Icons.pending_actions),
            ),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: _currentTabIndex == 1
                  ? BoxDecoration(
                      color: AppColors.secondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: const Icon(Icons.history),
            ),
            label: 'Riwayat',
          ),
        ],
      ),
      
      // ✓ NEW: FAB untuk create kategori iuran
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateIuranDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Kategori Iuran'),
        tooltip: 'Tambah Kategori Iuran Baru',
      ),
    );
  }

  Widget _buildKasCard(Map<String, dynamic> kas, bool isPending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => _shareKasData(kas),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isPending ? AppColors.primary : Colors.green,
                    width: 5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan icon dan status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPending
                                ? AppColors.primary.withAlpha(20)
                                : Colors.green.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPending ? Icons.payment : Icons.check_circle,
                            color: isPending ? AppColors.primary : Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kas['jenis_iuran'] ?? 'Kas',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp ${kas['jumlah_nominal']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Lunas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Divider
                    Divider(color: Colors.grey.shade200, height: 1),
                    
                    const SizedBox(height: 12),
                    
                    // Details Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.8,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildDetailItem('👤 Warga', kas['nama_warga'] ?? '-'),
                        _buildDetailItem('📅 Periode', kas['bulan_periode'] ?? '-'),
                        _buildDetailItem('📌 Tipe', kas['tipe_transaksi'] ?? '-'),
                        _buildDetailItem('🔍 Status', kas['status_verifikasi'] ?? 'Pending'),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Action Buttons
                    Row(
                      children: [
                        // Share Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareKasData(kas),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Bagikan', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        // Approve Button (hanya jika pending)
                        if (isPending)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveKas(kas),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Setujui', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _namaIuranController.dispose();
    _nominalController.dispose();
    super.dispose();
  }}

