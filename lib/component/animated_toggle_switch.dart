import 'package:flutter/material.dart';

/// Custom Animated Toggle Switch Widget (Asesmen 3 - Custom Widget Requirement)
/// 
/// Widget ini mengimplementasikan toggle switch yang smooth dan responsif menggunakan:
/// - GestureDetector untuk interaksi touch
/// - AnimatedContainer untuk animasi smooth
/// - AnimatedAlign untuk pergerakan smooth indikator
/// 
/// Fitur:
/// - Background berubah warna sesuai state
/// - Indikator bergerak dengan smooth
/// - Callback onToggled untuk notify parent widget
class AnimatedToggleSwitchKas extends StatefulWidget {
  final bool isRtMode;
  final ValueChanged<bool> onToggled;
  final String labelWarga;
  final String labelRT;

  const AnimatedToggleSwitchKas({
    super.key,
    required this.isRtMode,
    required this.onToggled,
    this.labelWarga = 'Mode Iuran Warga',
    this.labelRT = 'Mode Kas RT',
  });

  @override
  State<AnimatedToggleSwitchKas> createState() =>
      _AnimatedToggleSwitchKasState();
}

class _AnimatedToggleSwitchKasState extends State<AnimatedToggleSwitchKas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    // Set initial animation state berdasarkan isRtMode
    if (widget.isRtMode) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedToggleSwitchKas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRtMode != widget.isRtMode) {
      if (widget.isRtMode) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    widget.onToggled(!widget.isRtMode);
    if (widget.isRtMode) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _handleToggle,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              children: [
                // Background dengan animasi warna
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: widget.isRtMode
                        ? const Color(0xFF2E7D32).withAlpha(20) // Hijau muda
                        : const Color(0xFF1976D2).withAlpha(20), // Biru muda
                    border: Border.all(
                      color: widget.isRtMode
                          ? const Color(0xFF2E7D32) // Hijau untuk RT
                          : const Color(0xFF1976D2), // Biru untuk Warga
                      width: 2,
                    ),
                  ),
                ),

                // Sliding indicator dengan animasi
                Align(
                  alignment: Alignment(
                    _slideAnimation.value * 2 - 1,
                    0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      width: MediaQuery.of(context).size.width * 0.35,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: widget.isRtMode
                            ? const Color(0xFF2E7D32) // Hijau untuk RT
                            : const Color(0xFF1976D2), // Biru untuk Warga
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isRtMode
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF1976D2))
                                .withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isRtMode ? Icons.home_work : Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.isRtMode
                                    ? 'RT'
                                    : 'Warga',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Label text di setiap sisi
                Positioned.fill(
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Center(
                            child: Opacity(
                              opacity: widget.isRtMode ? 0.5 : 1.0,
                              child: Text(
                                widget.labelWarga,
                                style: TextStyle(
                                  color: const Color(0xFF1976D2),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Opacity(
                              opacity: !widget.isRtMode ? 0.5 : 1.0,
                              child: Text(
                                widget.labelRT,
                                style: TextStyle(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
