import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import 'beranda_page.dart'; 
import 'surat_page.dart';
import 'kas_page.dart';
import 'kritik_page.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _namaWarga = "Mitchell Santos";

  @override
  void initState() {
    super.initState();
    _loadSesiWarga();
  }

  Future<void> _loadSesiWarga() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _namaWarga = sp.getString('nama_warga') ?? "Mitchell Santos";
    });
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  void _bukaDialogGantiPassword() {
    final editPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Password Akun'),
        content: TextField(
          controller: editPassCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (editPassCtrl.text.isNotEmpty) {
                await DatabaseHelper.instance.updateData('users', {'password': editPassCtrl.text}, 1);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Password diperbarui!'), backgroundColor: Colors.green));
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BerandaPage(namaWarga: _namaWarga), 
      const SuratPage(),
      const KasPage(),
      const KritikPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        title: const Text('WargaWargi Portal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.lock_reset, color: Colors.white), onPressed: _bukaDialogGantiPassword),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
      
      body: pages[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: const Color(0xFF94A3B8),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.description_rounded), label: 'Surat'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Iuran Kas'),
            BottomNavigationBarItem(icon: Icon(Icons.campaign_rounded), label: 'Kritik'),
          ],
        ),
      ),
    );
  }
}