import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';
import 'detail_kritik_page.dart';

class RtKritikPage extends StatefulWidget {
  const RtKritikPage({super.key});

  @override
  State<RtKritikPage> createState() => _RtKritikPageState();
}

class _RtKritikPageState extends State<RtKritikPage> {
  List<Map<String, dynamic>> _allKritikData = [];
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _refreshKritikList();
  }

  Future<void> _refreshKritikList() async {
    final data = await DatabaseHelper.instance.getKritik();
    setState(() { _allKritikData = data; });
  }

  List<Map<String, dynamic>> get _filteredData {
    if (_filterStatus == 'Semua') return _allKritikData;
    return _allKritikData
        .where((k) => (k['status_laporan'] ?? 'Belum ditangani') == _filterStatus)
        .toList();
  }

  void _onMapTap(Offset localPosition, List<_KritikMarker> markers) {
    _KritikMarker? nearest;
    double minDistance = 25.0; // radius toleransi ketuk 25px

    for (var marker in markers) {
      final dist = (marker.position - localPosition).distance;
      if (dist < minDistance) {
        minDistance = dist;
        nearest = marker;
      }
    }

    if (nearest != null) {
      final idStr = nearest.id;
      final match = _allKritikData.firstWhere(
        (k) => k['id'].toString() == idStr,
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 [${match['status_laporan'] ?? 'Pending'}] ${match['judul_keluhan']} (Pelapor: ${match['nama_pelapor']})',
            ),
            action: SnackBarAction(
              label: 'BUKA',
              textColor: Colors.yellow,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailKritikPage(kritik: match),
                  ),
                ).then((_) => _refreshKritikList());
              },
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    await DatabaseHelper.instance.updateKritikStatus(id, newStatus);
    await _refreshKritikList();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Status laporan diperbarui: $newStatus'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAduan = _allKritikData.length;
    final totalBelum = _allKritikData.where((k) => (k['status_laporan'] ?? 'Belum ditangani') == 'Belum ditangani').length;
    final totalProses = _allKritikData.where((k) => k['status_laporan'] == 'Diproses').length;
    final totalSelesai = _allKritikData.where((k) => k['status_laporan'] == 'Selesai').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== STATISTIK RINGKAS ==========
            Row(
              children: [
                _buildStatCard('Total', totalAduan, AppColors.primary),
                const SizedBox(width: 8),
                _buildStatCard('Pending', totalBelum, Colors.orange),
                const SizedBox(width: 8),
                _buildStatCard('Proses', totalProses, Colors.blue),
                const SizedBox(width: 8),
                _buildStatCard('Selesai', totalSelesai, Colors.green),
              ],
            ),
            const SizedBox(height: 20),

            // ========== PETA INTERAKTIF ==========
            _buildSectionHeader(
              icon: Icons.map_outlined,
              title: 'Peta Aduan Fasum Wilayah RT',
              subtitle: 'Ketuk untuk menandai lokasi rusak',
            ),
            const SizedBox(height: 10),
            _buildInteractiveMap(),

            const SizedBox(height: 20),

            // ========== FILTER & DAFTAR ADUAN ==========
            _buildSectionHeader(
              icon: Icons.list_alt_rounded,
              title: 'Daftar Laporan Masuk',
              subtitle: 'Geser kanan → Diproses  |  Geser kiri → Selesai',
            ),
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 12),
            _buildAduanList(),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // STAT CARD
  // ==========================================================================
  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SECTION HEADER
  // ==========================================================================
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // INTERACTIVE MAP (Custom Canvas Art)
  // ==========================================================================
  Widget _buildInteractiveMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        const mapHeight = 260.0;

        // Cari reference center dari laporan pertama yang punya koordinat GPS
        double refLat = -6.914744;
        double refLon = 107.609810;
        for (var item in _allKritikData) {
          final koor = item['lokasi_koordinat'] ?? '';
          if (koor.isNotEmpty && koor != 'Tidak tersedia') {
            final parts = koor.split(',');
            if (parts.length == 2) {
              final lat = double.tryParse(parts[0]);
              final lon = double.tryParse(parts[1]);
              if (lat != null && lon != null) {
                refLat = lat;
                refLon = lon;
                break;
              }
            }
          }
        }

        // Petakan semua aduan ke marker kanvas
        List<_KritikMarker> currentMarkers = [];
        for (var item in _filteredData) {
          final koor = item['lokasi_koordinat'] ?? '';
          if (koor.isNotEmpty && koor != 'Tidak tersedia') {
            final parts = koor.split(',');
            if (parts.length == 2) {
              final lat = double.tryParse(parts[0]);
              final lon = double.tryParse(parts[1]);
              if (lat != null && lon != null) {
                const double gpsScale = 0.000005;
                final centerX = mapWidth / 2;
                final centerY = mapHeight / 2;

                final dx = (lon - refLon) / gpsScale;
                final dy = (refLat - lat) / gpsScale;

                final x = (centerX + dx).clamp(15.0, mapWidth - 15.0);
                final y = (centerY + dy).clamp(15.0, mapHeight - 15.0);

                // Warna pin berdasarkan status
                Color markerColor = Colors.orangeAccent; // Pending / Belum ditangani
                final status = item['status_laporan'] ?? 'Belum ditangani';
                if (status == 'Diproses') {
                  markerColor = Colors.blueAccent;
                } else if (status == 'Selesai') {
                  markerColor = Colors.green;
                }

                currentMarkers.add(
                  _KritikMarker(
                    id: item['id'].toString(),
                    position: Offset(x, y),
                    label: '${item['judul_keluhan']}',
                    color: markerColor,
                  ),
                );
              }
            }
          }
        }

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GestureDetector(
                  onTapDown: (details) => _onMapTap(details.localPosition, currentMarkers),
                  child: SizedBox(
                    width: double.infinity,
                    height: mapHeight,
                    child: CustomPaint(
                      painter: _RTMapCanvasPainter(markers: currentMarkers),
                      child: currentMarkers.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(120),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Belum ada aduan warga dengan GPS koordinat.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentMarkers.length} aduan ber-GPS ditampilkan',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
                // Legenda warna status
                Row(
                  children: [
                    _buildLegendItem('Pending', Colors.orangeAccent),
                    const SizedBox(width: 6),
                    _buildLegendItem('Proses', Colors.blueAccent),
                    const SizedBox(width: 6),
                    _buildLegendItem('Selesai', Colors.green),
                  ],
                )
              ],
            ),
          ],
        );
      }
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ==========================================================================
  // FILTER CHIPS
  // ==========================================================================
  Widget _buildFilterChips() {
    final filters = ['Semua', 'Belum ditangani', 'Diproses', 'Selesai'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterStatus == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.withAlpha(60)),
              ),
              onSelected: (_) {
                setState(() => _filterStatus = f);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================================
  // DAFTAR ADUAN (SWIPE TO ACTION CARDS)
  // ==========================================================================
  Widget _buildAduanList() {
    final data = _filteredData;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                _filterStatus == 'Semua'
                    ? 'Belum ada laporan atau kritik masuk.'
                    : 'Tidak ada laporan dengan status "$_filterStatus".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, idx) {
        final kritik = data[idx];
        return _SwipeActionCard(
          kritik: kritik,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailKritikPage(kritik: kritik),
              ),
            ).then((_) => _refreshKritikList());
          },
          onStatusChanged: _updateStatus,
        );
      },
    );
  }
}

// ==============================================================================
// SWIPE TO ACTION CARD WIDGET
// ==============================================================================
class _SwipeActionCard extends StatelessWidget {
  final Map<String, dynamic> kritik;
  final void Function(int id, String newStatus) onStatusChanged;
  final VoidCallback onTap;

  const _SwipeActionCard({
    required this.kritik,
    required this.onStatusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusLaporan = kritik['status_laporan'] ?? 'Belum ditangani';
    final koordinat = kritik['lokasi_koordinat'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(kritik['id'] ?? DateTime.now().millisecondsSinceEpoch),
        direction: DismissDirection.horizontal,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade100]),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            children: [
              Icon(Icons.autorenew, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text('Diproses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade100, Colors.green.shade300]),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(width: 10),
              Icon(Icons.check_circle, color: Colors.white, size: 28),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onStatusChanged(kritik['id'], 'Diproses');
          } else {
            onStatusChanged(kritik['id'], 'Selesai');
          }
          return false;
        },
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    if (kritik['bukti_keluhan'] != null)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.secondary.withAlpha(25),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(kritik['bukti_keluhan']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (kritik['bukti_keluhan'] != null) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kritik['judul_keluhan'] ?? 'Tanpa Judul',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kritik['isi_critic'] ?? '-',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // GPS badge
                    if (koordinat.isNotEmpty && koordinat != 'Tidak tersedia')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gps_fixed, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(koordinat, style: TextStyle(fontSize: 9, color: Colors.blue[700], fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                    const Spacer(),
                    _buildStatusBadge(statusLaporan),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pelapor: ${kritik['nama_pelapor'] ?? '-'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        kritik['tanggal_lapor'] ?? '-',
                        style: const TextStyle(fontSize: 10, color: AppColors.secondary),
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData icon;

    switch (status) {
      case 'Selesai':
        bgColor = Colors.green.withAlpha(25);
        textColor = Colors.green[700]!;
        borderColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'Diproses':
        bgColor = Colors.blue.withAlpha(25);
        textColor = Colors.blue[700]!;
        borderColor = Colors.blue;
        icon = Icons.autorenew;
        break;
      default:
        bgColor = Colors.orange.withAlpha(25);
        textColor = Colors.orange[700]!;
        borderColor = Colors.orange;
        icon = Icons.pending_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}

// ==============================================================================
// MODEL: Marker Data
// ==============================================================================
class _KritikMarker {
  final String id;
  final Offset position;
  final String label;
  final Color color;

  _KritikMarker({
    required this.id,
    required this.position,
    required this.label,
    required this.color,
  });
}

// ==============================================================================
// CUSTOM CANVAS ART: Denah Peta Wilayah RT (Same as KritikPage)
// ==============================================================================
class _RTMapCanvasPainter extends CustomPainter {
  final List<_KritikMarker> markers;

  _RTMapCanvasPainter({required this.markers});

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background Rumput ──
    final bgPaint = Paint()..color = const Color(0xFFD4EDDA);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Pola grid tanah ──
    final gridPaint = Paint()
      ..color = const Color(0xFFC2DFC9)
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += 20) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    // ── JALAN UTAMA (horizontal) ──
    final roadPaint = Paint()..color = const Color(0xFF9E9E9E);
    final road1 = Rect.fromLTWH(0, size.height * 0.42, size.width, 22);
    canvas.drawRect(road1, roadPaint);
    final dashPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (double x = 5; x < size.width; x += 18) {
      canvas.drawLine(
        Offset(x, size.height * 0.42 + 11),
        Offset(x + 8, size.height * 0.42 + 11),
        dashPaint,
      );
    }

    // ── JALAN VERTIKAL ──
    final road2 = Rect.fromLTWH(size.width * 0.35, 0, 18, size.height);
    canvas.drawRect(road2, roadPaint);
    for (double y = 5; y < size.height; y += 18) {
      canvas.drawLine(
        Offset(size.width * 0.35 + 9, y),
        Offset(size.width * 0.35 + 9, y + 8),
        dashPaint,
      );
    }

    // ── SUNGAI ──
    final riverPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.82),
        Offset(size.width, size.height * 0.88),
        [const Color(0xFF64B5F6), const Color(0xFF42A5F5)],
      );
    final riverPath = Path()
      ..moveTo(0, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.78, size.width * 0.5, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.92, size.width, size.height * 0.85)
      ..lineTo(size.width, size.height * 0.92)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.99, size.width * 0.5, size.height * 0.93)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.86, 0, size.height * 0.92)
      ..close();
    canvas.drawPath(riverPath, riverPaint);
    _drawLabel(canvas, 'Sungai', Offset(size.width * 0.7, size.height * 0.86), const Color(0xFF1565C0), 9);

    // ── BLOK A ──
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.05, size.height * 0.06, 38, 30), const Color(0xFFEF9A9A), 'R1');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.18, size.height * 0.06, 38, 30), const Color(0xFFEF9A9A), 'R2');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.05, size.height * 0.22, 38, 30), const Color(0xFFEF9A9A), 'R3');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.18, size.height * 0.22, 38, 30), const Color(0xFFEF9A9A), 'R4');
    _drawLabel(canvas, 'Blok A', Offset(size.width * 0.08, size.height * 0.38), const Color(0xFF37474F), 10);

    // ── BLOK B ──
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.55, size.height * 0.06, 38, 30), const Color(0xFF90CAF9), 'R5');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.72, size.height * 0.06, 38, 30), const Color(0xFF90CAF9), 'R6');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.55, size.height * 0.22, 38, 30), const Color(0xFF90CAF9), 'R7');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.72, size.height * 0.22, 38, 30), const Color(0xFF90CAF9), 'R8');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.88, size.height * 0.06, 34, 30), const Color(0xFF90CAF9), 'R9');
    _drawLabel(canvas, 'Blok B', Offset(size.width * 0.62, size.height * 0.38), const Color(0xFF37474F), 10);

    // ── MASJID ──
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.05, size.height * 0.54, 52, 38), const Color(0xFF80CBC4), '🕌');
    _drawLabel(canvas, 'Masjid', Offset(size.width * 0.06, size.height * 0.74), const Color(0xFF00695C), 9);

    // ── TAMAN ──
    final parkPaint = Paint()..color = const Color(0xFF81C784);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.42, size.height * 0.52, 65, 45), const Radius.circular(8)),
      parkPaint,
    );
    final treePaint = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(Offset(size.width * 0.48, size.height * 0.58), 6, treePaint);
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.62), 5, treePaint);
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.68), 7, treePaint);
    _drawLabel(canvas, 'Taman', Offset(size.width * 0.46, size.height * 0.76), const Color(0xFF2E7D32), 9);

    // ── BALAI RT ──
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.72, size.height * 0.54, 55, 36), const Color(0xFFFFCC80), '🏛');
    _drawLabel(canvas, 'Balai RT', Offset(size.width * 0.73, size.height * 0.74), const Color(0xFFE65100), 9);

    // ── JUDUL ──
    final titleBg = Paint()..color = Colors.black.withAlpha(140);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 0, 140, 22), const Radius.circular(0)), titleBg);
    _drawText(canvas, '🗺 PETA WILAYAH RT', const Offset(14, 4), Colors.white, 10, FontWeight.bold);

    // ── KOMPAS ──
    final compassCenter = Offset(size.width - 24, 18);
    canvas.drawCircle(compassCenter, 14, Paint()..color = Colors.white.withAlpha(180));
    canvas.drawCircle(compassCenter, 14, Paint()..color = Colors.black.withAlpha(40)..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawText(canvas, 'U', Offset(compassCenter.dx - 4, compassCenter.dy - 8), Colors.red, 10, FontWeight.bold);

    // ── MARKERS ──
    for (var marker in markers) {
      _drawMarkerPin(canvas, marker, size);
    }
  }

  void _drawBuilding(Canvas canvas, Rect rect, Color color, String label) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect.translate(2, 2), const Radius.circular(4)), Paint()..color = Colors.black.withAlpha(20));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = color);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = Colors.black.withAlpha(30)..style = PaintingStyle.stroke..strokeWidth = 1);
    if (label.length <= 3) {
      _drawText(canvas, label, Offset(rect.center.dx - 8, rect.center.dy - 6), Colors.black.withAlpha(150), 10, FontWeight.w600);
    } else {
      _drawText(canvas, label, Offset(rect.center.dx - 6, rect.center.dy - 8), Colors.black.withAlpha(150), 14, FontWeight.normal);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w700)), textDirection: ui.TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, offset);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, FontWeight weight) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)), textDirection: ui.TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, offset);
  }

  void _drawMarkerPin(Canvas canvas, _KritikMarker marker, Size size) {
    final center = marker.position;
    canvas.drawCircle(Offset(center.dx + 1, center.dy + 2), 10, Paint()..color = Colors.black.withAlpha(40));
    final tailPath = Path()..moveTo(center.dx - 6, center.dy + 5)..lineTo(center.dx, center.dy + 22)..lineTo(center.dx + 6, center.dy + 5)..close();
    canvas.drawPath(tailPath, Paint()..color = marker.color);
    canvas.drawCircle(center, 12, Paint()..color = marker.color);
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);
    final labelDx = (center.dx + 16).clamp(10.0, size.width - 80.0);
    final labelDy = (center.dy - 24).clamp(4.0, size.height - 28.0);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(labelDx - 6, labelDy - 4, 50, 20), const Radius.circular(10)), Paint()..color = Colors.black.withAlpha(170));
    _drawText(canvas, marker.label, Offset(labelDx, labelDy), Colors.white, 10, FontWeight.w600);
  }

  @override
  bool shouldRepaint(covariant _RTMapCanvasPainter oldDelegate) => true;
}
