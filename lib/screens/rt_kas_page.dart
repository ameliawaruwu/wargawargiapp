import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';
import '../component/animated_toggle_switch.dart';

class RtKasPage extends StatefulWidget {
  const RtKasPage({super.key});

  @override
  State<RtKasPage> createState() => _RtKasPageState();
}

class _RtKasPageState extends State<RtKasPage> {
  bool _isIuranMode = false; // false = Kas, true = Iuran
  int _transactionSubTab = 0; // 0 = Pending, 1 = Riwayat Lunas
  List<Map<String, dynamic>> _allKasData = [];
  List<Map<String, dynamic>> _masterIuran = []; // ✓ NEW: Master iuran list
  late SharedPreferences _prefs;

  // Shared Preferences Keys
  static const String _tabIndexKey = 'rt_kas_tab_index';
  static const String _lastUpdateKey = 'rt_kas_last_update';

  // Form controllers untuk create kategori
  final _namaIuranController = TextEditingController();
  final _nominalController = TextEditingController();

  // Hapus kategori iuran dari master tabel
  Future<void> _deleteMasterIuran(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DatabaseHelper.instance.deleteMasterIuran(id);
      _loadMasterIuran();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('🗑️ Kategori berhasil dihapus.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      print('❌ Error deleting master iuran: $e');
    }
  }

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
      _transactionSubTab = _prefs.getInt(_tabIndexKey) ?? 0;
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

  // ✓ NEW: Create kategori baru (Kas atau Iuran)
  Future<void> _createMasterIuran(String namaIuran, String nominalWajib, String tipe) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DatabaseHelper.instance.insertMasterIuran({
        'nama_iuran': namaIuran,
        'nominal_wajib': nominalWajib,
        'tipe': tipe,
      });
      
      _loadMasterIuran(); // Reload list
      
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Kategori ${tipe == 'KAS' ? 'Kas' : 'Iuran'} berhasil ditambahkan!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✓ NEW: Show form dialog untuk create kategori iuran / kas
  void _showCreateCategoryDialog(String tipe) {
    _namaIuranController.clear();
    _nominalController.clear();
    final isKas = tipe == 'KAS';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isKas ? Colors.teal.withAlpha(30) : AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isKas ? Icons.monetization_on : Icons.add_circle,
                color: isKas ? Colors.teal : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isKas ? 'Buat Kategori Kas Baru' : 'Buat Kategori Iuran Baru',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKas ? 'Tambahkan kategori kas baru ke sistem:' : 'Tambahkan kategori iuran baru ke sistem:',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _namaIuranController,
                decoration: InputDecoration(
                  labelText: isKas ? 'Nama Kategori Kas' : 'Nama Kategori Iuran',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.category, color: AppColors.secondary),
                  hintText: isKas ? 'Contoh: Kas Sosial RT' : 'Contoh: Iuran Kebersihan',
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
                  hintText: 'Contoh: 20000',
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isKas ? Colors.teal : AppColors.primary).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (isKas ? Colors.teal : AppColors.primary).withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: isKas ? Colors.teal : AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nominal ini akan menjadi default untuk dropdown di halaman warga',
                        style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
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
              
              _createMasterIuran(_namaIuranController.text, _nominalController.text, tipe);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isKas ? Colors.teal : AppColors.primary,
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

  // ✓ NEW: Bottom Sheet Kelola Kategori (Kas & Iuran)
  void _showManageCategoriesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kelola Kategori Kas & Iuran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                
                Expanded(
                  child: _masterIuran.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('Belum ada kategori terdaftar', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _masterIuran.length,
                          itemBuilder: (context, index) {
                            final item = _masterIuran[index];
                            final String tipe = item['tipe'] ?? 'IURAN';
                            final isKas = tipe == 'KAS';
                            
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isKas
                                        ? Colors.teal.withAlpha(20)
                                        : AppColors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isKas ? Icons.monetization_on : Icons.receipt_long,
                                    color: isKas ? Colors.teal : AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  item['nama_iuran'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isKas
                                              ? Colors.teal.withAlpha(30)
                                              : AppColors.primary.withAlpha(30),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isKas ? 'KAS' : 'IURAN',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isKas ? Colors.teal.shade800 : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rp ${item['nominal_wajib']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Hapus Kategori'),
                                        content: Text(
                                            'Hapus kategori "${item['nama_iuran']}"? Warga tidak akan bisa memilih kategori ini lagi.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              await _deleteMasterIuran(item['id']);
                                              setModalState(() {});
                                            },
                                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showCreateCategoryDialog('KAS');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_card, size: 18),
                          label: const Text('Kategori Kas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showCreateCategoryDialog('IURAN');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_box, size: 18),
                          label: const Text('Kategori Iuran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              await DatabaseHelper.instance.updateKasStatus(kas['id'], 'Lunas');
              navigator.pop();
              _refreshKasList();
              messenger.showSnackBar(
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
    // 1. Dapatkan semua nama kategori dengan tipe KAS
    final kasCategories = _masterIuran
        .where((c) => c['tipe'] == 'KAS')
        .map((c) => c['nama_iuran'] as String)
        .toSet();

    final isPending = _transactionSubTab == 0;
    
    List<Map<String, dynamic>> displayedKas = _allKasData.where((k) {
      // Filter status verifikasi (Pending vs Lunas)
      final String status = k['status_verifikasi'] ?? 'Pending';
      if (isPending && status != 'Pending') return false;
      if (!isPending && status != 'Lunas') return false;
      
      // Filter tipe (Kas vs Iuran)
      final String jenis = (k['jenis_iuran'] ?? '').toString();
      final bool isKas = kasCategories.contains(jenis) || jenis.toLowerCase().contains('kas');
      
      if (_isIuranMode) {
        return !isKas; // Mode Iuran: tampilkan selain Kas
      } else {
        return isKas;  // Mode Kas: tampilkan Kas
      }
    }).toList();
 
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshKasList();
          await _loadMasterIuran();
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              elevation: 0,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.category_outlined, color: Colors.white),
                  tooltip: 'Kelola Kategori',
                  onPressed: _showManageCategoriesDialog,
                ),
              ],
            ),
            
            // Switch Button Selector (Kas vs Iuran)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedToggleSwitchKas(
                  isRtMode: _isIuranMode,
                  onToggled: (val) {
                    setState(() {
                      _isIuranMode = val;
                    });
                  },
                  labelWarga: 'Kas Lingkungan',
                  labelRT: 'Iuran Warga',
                  indicatorLabelWarga: 'Kas',
                  indicatorLabelRT: 'Iuran',
                  iconWarga: Icons.monetization_on,
                  iconRT: Icons.receipt_long,
                ),
              ),
            ),

            // Sub-navigation Tabs untuk Transaksi (Pending vs Riwayat)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Pending Approval')),
                        selected: _transactionSubTab == 0,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _transactionSubTab = 0);
                            _saveTabIndex(0);
                          }
                        },
                        selectedColor: AppColors.primary.withAlpha(40),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _transactionSubTab == 0 ? AppColors.primary : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Riwayat Lunas')),
                        selected: _transactionSubTab == 1,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _transactionSubTab = 1);
                            _saveTabIndex(1);
                          }
                        },
                        selectedColor: AppColors.primary.withAlpha(40),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _transactionSubTab == 1 ? AppColors.primary : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content List Transaksi
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: displayedKas.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
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
      
      // ✓ FAB untuk Kelola Kategori
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManageCategoriesDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.category),
        label: const Text('Kelola Kategori'),
        tooltip: 'Kelola Kategori Kas & Iuran',
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

