
import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed, 
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF6366F1), 
      unselectedItemColor: const Color(0xFF94A3B8), 
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12), 
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_rounded),
          label: 'Surat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Iuran Kas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.campaign_rounded),
          label: 'Kritik',
        ),
      ],
    );
  }
}