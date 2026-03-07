// ============================================================
//  HomeScreen — شاشة اختيار الدور
// ============================================================

import 'package:flutter/material.dart';
import 'host_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── أيقونة ──
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE94560), Color(0xFFc0392b)],
                    ),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFFE94560).withOpacity(0.5),
                      blurRadius: 40,
                    )],
                  ),
                  child: const Center(
                    child: Text('🔔', style: TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('جرس المسابقة',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text('QUIZ BUZZER',
                    style: TextStyle(fontSize: 13, color: Colors.white38, letterSpacing: 4)),
                const SizedBox(height: 56),

                // ── زر المضيف ──
                _RoleButton(
                  label   : 'أنا المضيف',
                  sub     : 'Host — أنشئ جلسة جديدة',
                  icon    : '👑',
                  gradient: const [Color(0xFFE94560), Color(0xFFc0392b)],
                  onTap   : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HostScreen())),
                ),
                const SizedBox(height: 16),

                // ── زر اللاعب ──
                _RoleButton(
                  label   : 'أنا لاعب',
                  sub     : 'Player — انضم بكود الغرفة',
                  icon    : '🎮',
                  gradient: const [Color(0xFF0F3460), Color(0xFF0a274d)],
                  border  : true,
                  onTap   : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label, sub, icon;
  final List<Color> gradient;
  final bool border;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label, required this.sub,
    required this.icon,  required this.gradient,
    required this.onTap, this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(18),
          border: border ? Border.all(color: Colors.white12) : null,
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ]),
        ]),
      ),
    );
  }
}
