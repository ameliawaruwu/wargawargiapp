import 'package:flutter/material.dart';

class BerandaPage extends StatelessWidget {
  final String namaWarga;
  const BerandaPage({super.key, required this.namaWarga});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEEF2FF),
                child: Text(namaWarga.isNotEmpty ? namaWarga.substring(0, 1) : "M", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(namaWarga, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const Text('Warga Tetap RT 10', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87))
            ],
          ),
          const SizedBox(height: 24),
          
          // KARTU SALDO GRADIENT (Sesuai Referensi Gambar)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Saldo Kas RT 10', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                const Text('Rp 72.829,62', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _IconMenuAksi(icon: Icons.add, label: 'Add saving'),
                    _IconMenuAksi(icon: Icons.arrow_upward, label: 'Withdraw'),
                    _IconMenuAksi(icon: Icons.arrow_downward, label: 'Top up'),
                    _IconMenuAksi(icon: Icons.swap_horiz, label: 'Exchange'),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Recent transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: CircleAvatar(backgroundColor: Color(0xFFF3F4F6), child: Icon(Icons.swap_horiz, color: Colors.black87)),
              title: Text('Iuran Kebersihan Bulanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('2026-05-24', style: TextStyle(fontSize: 11, color: Colors.grey)),
              trailing: Text('+Rp 10.000', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
        ],
      ),
    );
  }
}

class _IconMenuAksi extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconMenuAksi({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 20, backgroundColor: Colors.white.withOpacity(0.2), child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}