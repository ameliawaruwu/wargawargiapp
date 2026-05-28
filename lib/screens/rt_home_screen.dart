import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'rt_surat_page.dart';
import 'rt_kas_page.dart';
import 'rt_kritik_page.dart';
import 'beranda_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/custom_bottom_nav.dart';

class RtHomeScreen extends StatefulWidget {
  const RtHomeScreen({super.key});

  @override
  State<RtHomeScreen> createState() => _RtHomeScreenState();
}

class _RtHomeScreenState extends State<RtHomeScreen> {
  int _selectedIndex = 0;
  String _namaWarga = "Pengurus RT";
  String _roleUser = "Pengurus RT";

  @override
  void initState() {
    super.initState();
    _loadSesiLengkap();
  }

  Future<void> _loadSesiLengkap() async {
    final sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _namaWarga = sp.getString('nama_warga') ?? "Pengurus RT";
        _roleUser = sp.getString('role_user') ?? "Pengurus RT";
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  String _getTitle(int index) {
    switch (index) {
      case 1: return 'Kelola Surat';
      case 2: return 'Kelola Iuran Kas';
      case 3: return 'Laporan Masuk';
      default: return 'Dashboard RT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BerandaPage(namaWarga: _namaWarga, roleUser: _roleUser),
      const RtSuratPage(),
      const RtKasPage(),
      const RtKritikPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedIndex == 0 ? null : AppBar(
        centerTitle: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_getTitle(_selectedIndex), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _onItemTapped(0),
        ),
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
