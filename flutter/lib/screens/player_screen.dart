// ============================================================
//  PlayerScreen — شاشة اللاعب
//  التحديثات: ترتيب الضاغطين + 🥇 + صوت + نصوص مذكر
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  late AnimationController _anim;
  late Animation<double>    _scale;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.87).animate(_anim);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    // إذا انضم بنجاح → شاشة الجرس
    if (game.roomId != null && game.role == RoomRole.player) {
      return _BuzzerScreen(game: game, anim: _anim, scale: _scale);
    }

    // شاشة الانضمام
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('انضم كلاعب',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎮', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 32),

            _buildInput(
              controller: _nameCtrl,
              label: 'اسمك',
              hint: 'أدخل اسمك',
              icon: Icons.person,
            ),
            const SizedBox(height: 14),

            _buildInput(
              controller: _roomCtrl,
              label: 'كود الغرفة',
              hint: 'أدخل الكود من المضيف',
              icon: Icons.tag,
              upper: true,
            ),

            if (game.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(game.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  final room = _roomCtrl.text.trim().toUpperCase();
                  if (name.isEmpty || room.isEmpty) return;
                  game.joinRoom(room, name);
                },
                child: const Text('انضم الآن',
                    style: TextStyle(color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label, required String hint,
    required IconData icon, bool upper = false,
  }) {
    return TextField(
      controller: controller,
      textCapitalization:
          upper ? TextCapitalization.characters : TextCapitalization.none,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white38),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white24),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE94560))),
        filled: true,
        fillColor: const Color(0xFF16213E),
      ),
    );
  }
}

// ── شاشة الجرس ────────────────────────────────────────────
class _BuzzerScreen extends StatelessWidget {
  final GameProvider          game;
  final AnimationController   anim;
  final Animation<double>     scale;
  const _BuzzerScreen({required this.game, required this.anim, required this.scale});

  // لون الجرس حسب الحالة
  LinearGradient get _btnGradient {
    switch (game.buzzerState) {
      case BuzzerState.open:
        return const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2e7d32)]);
      case BuzzerState.won:
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFe6a800)]);
      case BuzzerState.lost:
        return const LinearGradient(colors: [Color(0xFF2a2a3e), Color(0xFF1a1a2e)]);
      case BuzzerState.idle:
        return const LinearGradient(colors: [Color(0xFF252538), Color(0xFF1a1a2e)]);
    }
  }

  List<BoxShadow> get _btnShadow {
    switch (game.buzzerState) {
      case BuzzerState.open:
        return [BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.55), blurRadius: 50, spreadRadius: 10)];
      case BuzzerState.won:
        return [BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 50, spreadRadius: 10)];
      default:
        return [BoxShadow(color: Colors.black38, blurRadius: 20)];
    }
  }

  String get _statusText {
    switch (game.buzzerState) {
      case BuzzerState.open: return 'اضغط الآن! ⚡';
      case BuzzerState.won:  return '🥇 أنت الأول!';  // مذكر
      case BuzzerState.lost:
        return 'سبقك ${game.firstPlayer?.name ?? "لاعب آخر"}';  // مذكر
      case BuzzerState.idle: return 'انتظر إشارة البدء...';
    }
  }

  Color get _statusColor {
    switch (game.buzzerState) {
      case BuzzerState.open: return const Color(0xFF4CAF50);
      case BuzzerState.won:  return const Color(0xFFFFD700);
      case BuzzerState.lost: return Colors.redAccent.withOpacity(0.85);
      case BuzzerState.idle: return Colors.white24;
    }
  }

  bool get _canBuzz => game.buzzerState == BuzzerState.open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text('غرفة: ${game.roomId}',
            style: const TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        actions: [
          // ── زر الصوت ──
          GestureDetector(
            onTap: game.toggleSound,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(children: [
                Icon(game.soundEnabled ? Icons.volume_up : Icons.volume_off,
                    size: 15,
                    color: game.soundEnabled ? Colors.white60 : Colors.white24),
                const SizedBox(width: 4),
                Text(game.soundEnabled ? 'صوت' : 'صامت',
                    style: TextStyle(
                        fontSize: 11,
                        color: game.soundEnabled ? Colors.white60 : Colors.white24)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [

        // ── قسم الجرس ──
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // اسم اللاعب
              Text(game.myPlayerName ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 15)),
              const SizedBox(height: 6),

              // رسالة الحالة
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(_statusText,
                    key: ValueKey(game.buzzerState),
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),

              // زمن الاستجابة (إذا كان الأول)
              if (game.buzzerState == BuzzerState.won &&
                  game.firstPlayer?.responseTimeMs != null) ...[
                const SizedBox(height: 4),
                Text('⚡ ${game.firstPlayer!.responseTimeMs}ms',
                    style: const TextStyle(
                        color: Color(0xFFFFD700), fontSize: 14)),
              ],

              const SizedBox(height: 40),

              // ── زر الجرس ──
              GestureDetector(
                onTapDown : _canBuzz ? (_) => anim.forward()  : null,
                onTapUp   : _canBuzz ? (_) { anim.reverse(); game.buzz(); } : null,
                onTapCancel: _canBuzz ? () => anim.reverse()  : null,
                child: ScaleTransition(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape    : BoxShape.circle,
                      gradient : _btnGradient,
                      boxShadow: _btnShadow,
                    ),
                    child: const Center(
                      child: Text('🔔', style: TextStyle(fontSize: 82)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              if (_canBuzz)
                const Text('← اضغط الجرس بأسرع ما يمكن!',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        ),

        // ── ترتيب الضاغطين ──
        if (game.buzzRanking.isNotEmpty)
          Expanded(
            flex: 2,
            child: _BuzzRankingPanel(
              ranking   : game.buzzRanking,
              myPlayerId: game.myPlayerId,
            ),
          ),

      ]),
    );
  }
}

// ── لوحة الترتيب ──────────────────────────────────────────
class _BuzzRankingPanel extends StatelessWidget {
  final List<BuzzRecord> ranking;
  final String?          myPlayerId;
  const _BuzzRankingPanel({required this.ranking, this.myPlayerId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ترتيب الضاغطين بالوقت',
              style: TextStyle(
                  color: Colors.white38, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: ranking.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (_, i) {
                final r     = ranking[i];
                final isMe  = r.id == myPlayerId;
                final medal = ['🥇','🥈','🥉'];
                final Color nameColor = isMe
                    ? Colors.white
                    : (r.rank == 1
                        ? const Color(0xFFFFD700)
                        : r.rank == 2
                            ? const Color(0xFFC0C0C0)
                            : r.rank == 3
                                ? const Color(0xFFCD7F32)
                                : Colors.white54);

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: isMe
                      ? BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8))
                      : null,
                  child: Row(children: [
                    // رقم
                    SizedBox(
                      width: 28,
                      child: Text(
                          r.rank <= 3 ? medal[r.rank - 1] : '${r.rank}',
                          style: TextStyle(
                              fontSize: r.rank <= 3 ? 16 : 12,
                              color: Colors.white38)),
                    ),
                    // اسم
                    Expanded(
                      child: Text(
                          isMe ? 'أنت (${r.name})' : r.name,
                          style: TextStyle(
                              color     : nameColor,
                              fontSize  : 13,
                              fontWeight: isMe
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                    // وقت
                    if (r.responseTimeMs != null)
                      Text('${r.responseTimeMs}ms',
                          style: TextStyle(
                              color   : nameColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
