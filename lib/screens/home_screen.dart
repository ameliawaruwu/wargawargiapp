import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/custom_bottom_nav.dart';
import 'beranda_page.dart';
import 'surat_page.dart';
import 'kas_page.dart';
import 'kritik_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _namaWarga = "Warga Mandiri";
  String _roleUser = "Warga Mandiri";

  @override
  void initState() {
    super.initState();
    _loadSesiLengkap();
  }

  Future<void> _loadSesiLengkap() async {
    final sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _namaWarga = sp.getString('nama_warga') ?? "Warga Mandiri";
        _roleUser = sp.getString('role_user') ?? "Warga Mandiri";
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BerandaPage(namaWarga: _namaWarga, roleUser: _roleUser), 
      const SuratPage(),
      KasPage(namaWarga: _namaWarga), 
      const KritikPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}