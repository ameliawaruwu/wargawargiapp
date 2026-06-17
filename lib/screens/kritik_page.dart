import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../data/preferences_helper.dart';
import '../theme/app_colors.dart';
import 'detail_kritik_page.dart';

class KritikPage extends StatefulWidget {
  const KritikPage({super.key});

  @override
  State<KritikPage> createState() => _KritikPageState();
}

class _KritikPageState extends State<KritikPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _dataKritik = [];
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();
  String? _base64BuktiKeluhan;
  String _namaPelapor = 'Warga';
  String _markerHint = 'Ketuk area peta untuk menandai lokasi fasilitas rusak.';
  double _refLat = -6.914744; // Default center (Bandung)
  double _refLon = 107.609810;

  // GPS / Geolocator
  String? _koordinatGPS;
  bool _isFetchingGPS = false;

  // Animasi
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _roleUser = 'Warga Mandiri';
  String _nik = '-';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeKritikPage();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeKritikPage() async {
    await _loadKritikSession();
    await _refreshData();
  }

  Future<void> _loadKritikSession() async {
    final sesi = await PreferencesHelper.ambilSesiLogin();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaPelapor = sesi['nama_warga'] ?? 'Warga';
      _roleUser = sesi['role_user'] ?? 'Warga Mandiri';
      _nik = prefs.getString('nik') ?? '-';
    });
    debugPrint('🔍 KritikPage - Nama Pelapor: $_namaPelapor, NIK: $_nik');
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? loggedNik = prefs.getString('nik');
    final String? filterNik = _roleUser == 'Pengurus RT' ? null : (loggedNik ?? _nik);
    debugPrint('🔍 Query Kritik dengan NIK: $filterNik');
    final data = await DatabaseHelper.instance.getKritik(pelaporNik: filterNik);
    debugPrint('📊 Ditemukan ${data.length} data kritik');
    setState(() {
      _dataKritik = data;
    });
  }

  // ==========================================================================
  // GEOLOCATOR: Ambil koordinat GPS otomatis
  // ==========================================================================
  Future<void> _ambilKoordinatGPS() async {
    setState(() => _isFetchingGPS = true);

    try {
      // Cek apakah layanan lokasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Layanan lokasi tidak aktif. Aktifkan GPS!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isFetchingGPS = false);
        return;
      }

      // Cek dan minta permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Izin lokasi ditolak. Izinkan akses GPS!'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isFetchingGPS = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Izin lokasi diblokir permanen. Buka Pengaturan > Izin Aplikasi.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isFetchingGPS = false);
        return;
      }

      // Ambil posisi GPS saat ini
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _refLat = position.latitude;
        _refLon = position.longitude;
        _koordinatGPS =
            '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';
        _isFetchingGPS = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 GPS berhasil: $_koordinatGPS'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Gagal mendapatkan GPS: $e');
      setState(() => _isFetchingGPS = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengambil lokasi GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pilihFotoKerusakan() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64BuktiKeluhan = base64Encode(bytes);
      });
      // Otomatis ambil GPS saat foto dipilih
      _ambilKoordinatGPS();
    }
  }

  Future<void> _ambilFotoKamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64BuktiKeluhan = base64Encode(bytes);
      });
      // Otomatis ambil GPS saat foto diambil dari kamera
      _ambilKoordinatGPS();
    }
  }

  Future<void> _kirimLaporan() async {
    if (_judulCtrl.text.isEmpty ||
        _isiCtrl.text.isEmpty ||
        _base64BuktiKeluhan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Lengkapi form dan lampiran foto aduan!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final nikAkhir = prefs.getString('nik') ?? _nik;
    debugPrint('💾 Menyimpan Kritik dengan NIK: $nikAkhir');
    
    final now = DateTime.now();
    final tglFormat = DateFormat('dd/MM/yyyy HH:mm').format(now);
    await DatabaseHelper.instance.insertKritik({
      'pelapor_nik': nikAkhir,
      'tanggal_lapor': tglFormat,
      'judul_keluhan': _judulCtrl.text,
      'isi_critic': _isiCtrl.text,
      'bukti_keluhan': _base64BuktiKeluhan!,
      'lokasi_koordinat': _koordinatGPS ?? 'Tidak tersedia',
    });
    _judulCtrl.clear();
    _isiCtrl.clear();
    setState(() {
      _base64BuktiKeluhan = null;
      _koordinatGPS = null;
    });
    _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Laporan berhasil dikirim dengan koordinat GPS!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Offset _gpsToOffset(double lat, double lon, double width, double height) {
    const double gpsScale = 0.000005; // 1 pixel = 0.000005 derajat
    final centerX = width / 2;
    final centerY = height / 2;

    final dx = (lon - _refLon) / gpsScale;
    final dy = (_refLat - lat) / gpsScale;

    // Batasi agar tidak melampaui ukuran canvas
    final x = (centerX + dx).clamp(15.0, width - 15.0);
    final y = (centerY + dy).clamp(15.0, height - 15.0);

    return Offset(x, y);
  }

  void _offsetToGps(Offset offset, double width, double height) {
    const double gpsScale = 0.000005;
    final centerX = width / 2;
    final centerY = height / 2;

    final dx = offset.dx - centerX;
    final dy = offset.dy - centerY;

    final lat = _refLat - (dy * gpsScale);
    final lon = _refLon + (dx * gpsScale);

    setState(() {
      _koordinatGPS = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
      _markerHint = 'Titik rusak ditandai pada GPS: $_koordinatGPS';
    });
  }

  void _addMarker(Offset localPosition, double width, double height) {
    _offsetToGps(localPosition, width, height);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📌 Titik rusak ditandai di denah RT & koordinat GPS disimulasikan.',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetMarkers() {
    setState(() {
      _koordinatGPS = null;
      _markerHint = 'Ketuk area peta untuk menandai lokasi fasilitas rusak.';
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== PETA INTERAKTIF CUSTOM CANVAS ART ==========
            _buildSectionHeader(
              icon: Icons.map_outlined,
              title: 'Peta Interaktif Wilayah RT',
              subtitle: 'Ketuk lokasi untuk menandai fasilitas rusak',
            ),
            const SizedBox(height: 10),
            _buildInteractiveMap(),

            const SizedBox(height: 24),

            // ========== FORM ADUAN ==========
            _buildSectionHeader(
              icon: Icons.report_problem_outlined,
              title: 'Form Aduan Fasilitas Umum',
              subtitle: 'Laporkan fasilitas rusak di wilayah RT',
            ),
            const SizedBox(height: 10),
            _buildFormCard(),

            const SizedBox(height: 24),

            // ========== DAFTAR ADUAN (SWIPE CARDS) ==========
            _buildSectionHeader(
              icon: Icons.list_alt_rounded,
              title: 'Daftar Aduan Anda',
              subtitle: 'Pantau status laporan aduan yang Anda kirimkan',
            ),
            const SizedBox(height: 12),
            _buildAduanList(),
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
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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

        List<_KritikMarker> currentMarkers = [];
        if (_koordinatGPS != null && _koordinatGPS != 'Tidak tersedia') {
          final parts = _koordinatGPS!.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0]);
            final lon = double.tryParse(parts[1]);
            if (lat != null && lon != null) {
              final offset = _gpsToOffset(lat, lon, mapWidth, mapHeight);
              currentMarkers.add(
                _KritikMarker(
                  label: 'Titik Kerusakan',
                  position: offset,
                  color: Colors.redAccent,
                ),
              );
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
                  onTapDown: (details) => _addMarker(details.localPosition, mapWidth, mapHeight),
                  child: SizedBox(
                    height: mapHeight,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _RTMapCanvasPainter(markers: currentMarkers),
                      child: currentMarkers.isEmpty
                          ? Center(
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _pulseAnimation.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(120),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _markerHint,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentMarkers.length} titik ditandai',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (currentMarkers.isNotEmpty)
                  TextButton.icon(
                    onPressed: _resetMarkers,
                    icon: const Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Reset Peta',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        );
      }
    );
  }

  // ==========================================================================
  // FORM CARD
  // ==========================================================================
  Widget _buildFormCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _judulCtrl,
              decoration: InputDecoration(
                labelText: 'Judul Keluhan Fasilitas',
                prefixIcon: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.grey.withAlpha(80),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _isiCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Deskripsi Detail Keluhan',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.grey.withAlpha(80),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Foto Bukti Lapangan
            const Text(
              'Foto Bukti Lapangan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (_base64BuktiKeluhan != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      base64Decode(_base64BuktiKeluhan!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _base64BuktiKeluhan = null;
                        _koordinatGPS = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(
                    (0.08 * 255).round(),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.secondary.withAlpha(
                      (0.3 * 255).round(),
                    ),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 36, color: AppColors.secondary),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada foto bukti yang dipilih',
                        style: TextStyle(color: AppColors.secondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Tombol Foto (Gallery + Kamera)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pilihFotoKerusakan,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    label: const Text(
                      'Galeri',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _ambilFotoKamera,
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    label: const Text(
                      'Kamera',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // GPS Koordinat Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _koordinatGPS != null
                    ? Colors.green.withAlpha(20)
                    : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _koordinatGPS != null
                      ? Colors.green.withAlpha(80)
                      : Colors.grey.withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _koordinatGPS != null
                        ? Icons.gps_fixed
                        : Icons.gps_not_fixed,
                    color:
                        _koordinatGPS != null ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _koordinatGPS != null
                              ? 'Koordinat GPS Terdeteksi'
                              : 'GPS belum diambil',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _koordinatGPS != null
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                        if (_koordinatGPS != null)
                          Text(
                            _koordinatGPS!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isFetchingGPS)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: _ambilKoordinatGPS,
                      icon: const Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      tooltip: 'Ambil GPS Sekarang',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _kirimLaporan,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text(
                  'KIRIM LAPORAN ADUAN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // DAFTAR ADUAN (SWIPE TO ACTION CARDS)
  // ==========================================================================
  Widget _buildAduanList() {
    if (_dataKritik.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada laporan aduan',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Laporkan fasilitas rusak melalui form di atas',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _dataKritik.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final item = _dataKritik[idx];
        final statusLaporan = item['status_laporan'] ?? 'Belum ditangani';
        final koordinat = item['lokasi_koordinat'] ?? '';

        return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailKritikPage(kritik: item),
                ),
              ).then((_) => _refreshData());
            },
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail foto bukti
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.secondary.withAlpha(25),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: item['bukti_keluhan'] != null
                              ? Image.memory(
                                  base64Decode(item['bukti_keluhan']),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.secondary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['judul_keluhan'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['isi_critic'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
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
                      // GPS koordinat badge
                      if (koordinat.isNotEmpty &&
                          koordinat != 'Tidak tersedia')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.gps_fixed,
                                size: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'GPS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      // Status badge
                      _buildStatusBadge(statusLaporan),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pelapor: ${item['nama_pelapor']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['tanggal_lapor'] ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondary,
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
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// MODEL: Marker Data
// ==============================================================================
class _KritikMarker {
  final String label;
  final Offset position;
  final Color color;

  _KritikMarker({
    required this.label,
    required this.position,
    required this.color,
  });
}

// ==============================================================================
// CUSTOM CANVAS ART: Denah Peta Wilayah RT (Custom Painter)
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
    // Garis putus-putus jalan
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

    // ── SUNGAI / SALURAN AIR ──
    final riverPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.82),
        Offset(size.width, size.height * 0.88),
        [const Color(0xFF64B5F6), const Color(0xFF42A5F5)],
      );
    final riverPath = Path()
      ..moveTo(0, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.78,
        size.width * 0.5, size.height * 0.86,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.92,
        size.width, size.height * 0.85,
      )
      ..lineTo(size.width, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.99,
        size.width * 0.5, size.height * 0.93,
      )
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.86,
        0, size.height * 0.92,
      )
      ..close();
    canvas.drawPath(riverPath, riverPaint);

    // Label sungai
    _drawLabel(canvas, 'Sungai', Offset(size.width * 0.7, size.height * 0.86),
        const Color(0xFF1565C0), 9);

    // ── BLOK A: Rumah Warga (kiri atas) ──
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.05, size.height * 0.06, 38, 30),
        const Color(0xFFEF9A9A), 'R1');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.18, size.height * 0.06, 38, 30),
        const Color(0xFFEF9A9A), 'R2');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.05, size.height * 0.22, 38, 30),
        const Color(0xFFEF9A9A), 'R3');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.18, size.height * 0.22, 38, 30),
        const Color(0xFFEF9A9A), 'R4');

    // Label Blok A
    _drawLabel(canvas, 'Blok A', Offset(size.width * 0.08, size.height * 0.38),
        const Color(0xFF37474F), 10);

    // ── BLOK B: Rumah Warga (kanan atas) ──
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.55, size.height * 0.06, 38, 30),
        const Color(0xFF90CAF9), 'R5');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.72, size.height * 0.06, 38, 30),
        const Color(0xFF90CAF9), 'R6');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.55, size.height * 0.22, 38, 30),
        const Color(0xFF90CAF9), 'R7');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.72, size.height * 0.22, 38, 30),
        const Color(0xFF90CAF9), 'R8');
    _drawBuilding(canvas, Rect.fromLTWH(size.width * 0.88, size.height * 0.06, 34, 30),
        const Color(0xFF90CAF9), 'R9');

    // Label Blok B
    _drawLabel(canvas, 'Blok B', Offset(size.width * 0.62, size.height * 0.38),
        const Color(0xFF37474F), 10);

    // ── MASJID (kiri bawah) ──
    _drawBuilding(
      canvas,
      Rect.fromLTWH(size.width * 0.05, size.height * 0.54, 52, 38),
      const Color(0xFF80CBC4),
      '🕌',
    );
    _drawLabel(canvas, 'Masjid', Offset(size.width * 0.06, size.height * 0.74),
        const Color(0xFF00695C), 9);

    // ── TAMAN / LAPANGAN (tengah bawah) ──
    final parkPaint = Paint()..color = const Color(0xFF81C784);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.42, size.height * 0.52, 65, 45),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    // Pohon di taman
    final treePaint = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(
      Offset(size.width * 0.48, size.height * 0.58), 6, treePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.62), 5, treePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.68), 7, treePaint,
    );
    _drawLabel(canvas, 'Taman', Offset(size.width * 0.46, size.height * 0.76),
        const Color(0xFF2E7D32), 9);

    // ── BALAI RT (kanan bawah) ──
    _drawBuilding(
      canvas,
      Rect.fromLTWH(size.width * 0.72, size.height * 0.54, 55, 36),
      const Color(0xFFFFCC80),
      '🏛',
    );
    _drawLabel(canvas, 'Balai RT', Offset(size.width * 0.73, size.height * 0.74),
        const Color(0xFFE65100), 9);

    // ── JUDUL PETA ──
    final titleBg = Paint()..color = Colors.black.withAlpha(140);
    final titleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 0, 140, 22),
      const Radius.circular(0),
    );
    canvas.drawRRect(titleRect, titleBg);
    _drawText(canvas, '🗺 PETA WILAYAH RT', const Offset(14, 4),
        Colors.white, 10, FontWeight.bold);

    // ── KOMPAS ──
    final compassCenter = Offset(size.width - 24, 18);
    canvas.drawCircle(compassCenter, 14, Paint()..color = Colors.white.withAlpha(180));
    canvas.drawCircle(compassCenter, 14,
        Paint()..color = Colors.black.withAlpha(40)..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawText(canvas, 'U', Offset(compassCenter.dx - 4, compassCenter.dy - 8),
        Colors.red, 10, FontWeight.bold);

    // ── MARKERS ──
    for (var marker in markers) {
      _drawMarkerPin(canvas, marker, size);
    }
  }

  void _drawBuilding(Canvas canvas, Rect rect, Color color, String label) {
    final buildingPaint = Paint()..color = color;
    final shadowPaint = Paint()..color = Colors.black.withAlpha(20);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(2, 2),
        const Radius.circular(4),
      ),
      shadowPaint,
    );

    // Building
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      buildingPaint,
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..color = Colors.black.withAlpha(30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Label di dalam bangunan
    if (label.length <= 3) {
      _drawText(
        canvas,
        label,
        Offset(rect.center.dx - 8, rect.center.dy - 6),
        Colors.black.withAlpha(150),
        10,
        FontWeight.w600,
      );
    } else {
      _drawText(
        canvas,
        label,
        Offset(rect.center.dx - 6, rect.center.dy - 8),
        Colors.black.withAlpha(150),
        14,
        FontWeight.normal,
      );
    }
  }

  void _drawLabel(
      Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color,
      double fontSize, FontWeight weight) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  void _drawMarkerPin(Canvas canvas, _KritikMarker marker, Size size) {
    final center = marker.position;

    // Pin shadow
    canvas.drawCircle(
      Offset(center.dx + 1, center.dy + 2),
      10,
      Paint()..color = Colors.black.withAlpha(40),
    );

    // Pin tail
    final tailPath = Path()
      ..moveTo(center.dx - 6, center.dy + 5)
      ..lineTo(center.dx, center.dy + 22)
      ..lineTo(center.dx + 6, center.dy + 5)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = marker.color);

    // Pin circle
    canvas.drawCircle(center, 12, Paint()..color = marker.color);
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);

    // Label tooltip
    final labelDx = (center.dx + 16).clamp(10.0, size.width - 80.0);
    final labelDy = (center.dy - 24).clamp(4.0, size.height - 28.0);
    final tooltipBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelDx - 6, labelDy - 4, 50, 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(tooltipBg, Paint()..color = Colors.black.withAlpha(170));
    _drawText(canvas, marker.label, Offset(labelDx, labelDy),
        Colors.white, 10, FontWeight.w600);
  }

  @override
  bool shouldRepaint(covariant _RTMapCanvasPainter oldDelegate) => true;
}
