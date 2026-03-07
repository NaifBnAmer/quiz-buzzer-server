// ============================================================
//  HostScreen — شاشة المضيف
//  التحديثات: 🥇 بدل الكاس + ترتيب الضاغطين بالوقت + تحكم الصوت
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});
  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    if (game.roomClosed) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: const Center(
          child: Text('انتهت الجلسة', style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('لوحة المضيف', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ── زر الصوت ──
          _SoundToggle(
            enabled : game.soundEnabled,
            onToggle: game.toggleSound,
          ),
          // ── مؤشر الاتصال ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(Icons.circle, size: 10,
                color: game.isConnected ? Colors.greenAccent : Colors.redAccent),
          ),
        ],
      ),
      body: game.roomId == null
          ? _CreateRoomView(onCreate: game.createRoom)
          : _RoomView(game: game),
    );
  }
}

// ── إنشاء الغرفة ──────────────────────────────────────────
class _CreateRoomView extends StatelessWidget {
  final VoidCallback onCreate;
  const _CreateRoomView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.add_circle_outline, size: 80, color: Colors.white24),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE94560),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.play_circle, color: Colors.white),
          label: const Text('إنشاء جلسة جديدة',
              style: TextStyle(color: Colors.white, fontSize: 17)),
          onPressed: onCreate,
        ),
      ]),
    );
  }
}

// ── داخل الغرفة ───────────────────────────────────────────
class _RoomView extends StatelessWidget {
  final GameProvider game;
  const _RoomView({required this.game});

  @override
  Widget build(BuildContext context) {
    final bool roundOpen   = game.buzzerState == BuzzerState.open;
    final bool hasResults  = game.firstPlayer != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // ── كود الغرفة ──
        _RoomCodeCard(roomId: game.roomId!),
        const SizedBox(height: 14),

        // ── بطاقة الأول (بعد انتهاء الجرس) ──
        if (hasResults) ...[
          _FirstCard(first: game.firstPlayer!),
          const SizedBox(height: 14),
        ],

        // ── ترتيب الضاغطين ──
        Expanded(
          child: _RankingList(
            ranking : game.buzzRanking,
            players : game.players,
            hasResults: hasResults,
          ),
        ),
        const SizedBox(height: 14),

        // ── أزرار التحكم ──
        _ControlRow(
          roundOpen : roundOpen,
          hasResults: hasResults,
          onStart   : game.startRound,
          onReset   : game.resetRound,
        ),
      ]),
    );
  }
}

// ── بطاقة كود الغرفة ──────────────────────────────────────
class _RoomCodeCard extends StatelessWidget {
  final String roomId;
  const _RoomCodeCard({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE94560), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('كود الغرفة',
                style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
            Text(roomId,
                style: const TextStyle(
                    color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w900, letterSpacing: 8)),
          ]),
          IconButton(
            icon: const Icon(Icons.copy, color: Color(0xFFE94560)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: roomId));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الكود ✅')));
            },
          ),
        ],
      ),
    );
  }
}

// ── بطاقة الأول 🥇 ────────────────────────────────────────
class _FirstCard extends StatelessWidget {
  final FirstPlayer first;
  const _FirstCard({required this.first});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.18),
            const Color(0xFFFF8C00).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Row(children: [
        // 🥇 بدل الكاس
        const Text('🥇', style: TextStyle(fontSize: 38)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(first.name,
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 20, fontWeight: FontWeight.w900)),
          if (first.responseTimeMs != null)
            Text('⚡ الأول — ${first.responseTimeMs}ms',
                style: const TextStyle(
                    color: Color(0xFFFFD700), fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ── قائمة الترتيب ─────────────────────────────────────────
class _RankingList extends StatelessWidget {
  final List<BuzzRecord> ranking;
  final List<Player>     players;
  final bool             hasResults;
  const _RankingList({
    required this.ranking,
    required this.players,
    required this.hasResults,
  });

  @override
  Widget build(BuildContext context) {
    // قبل النتائج: اعرض قائمة اللاعبين المنضمين
    if (!hasResults) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('اللاعبون (${players.length})',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          Expanded(
            child: players.isEmpty
                ? const Center(
                    child: Text('في انتظار اللاعبين...',
                        style: TextStyle(color: Colors.white24)))
                : ListView.separated(
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _PlayerTile(player: players[i]),
                  ),
          ),
        ],
      );
    }

    // بعد النتائج: الترتيب الكامل بالوقت
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ترتيب جميع الضاغطين بالوقت',
            style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: ranking.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _RankTile(record: ranking[i]),
          ),
        ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player;
  const _PlayerTile({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF0F3460),
          child: Text(player.name[0],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Text(player.name,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ]),
    );
  }
}

class _RankTile extends StatelessWidget {
  final BuzzRecord record;
  const _RankTile({required this.record});

  // ألوان الميداليات
  Color get _badgeColor {
    switch (record.rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return Colors.white30;
    }
  }

  String get _medal {
    switch (record.rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }

  Color get _borderColor {
    switch (record.rank) {
      case 1: return const Color(0xFFFFD700).withOpacity(0.5);
      case 2: return const Color(0xFFC0C0C0).withOpacity(0.3);
      case 3: return const Color(0xFFCD7F32).withOpacity(0.3);
      default: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: record.rank == 1
            ? const Color(0xFFFFD700).withOpacity(0.07)
            : const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(children: [
        // رقم الترتيب
        SizedBox(
          width: 28, height: 28,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _badgeColor.withOpacity(0.2),
            ),
            child: Center(
              child: Text('${record.rank}',
                  style: TextStyle(
                      color: _badgeColor,
                      fontSize: 13, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // الاسم
        Expanded(
          child: Text(record.name,
              style: TextStyle(
                  color: record.rank <= 3 ? _badgeColor : Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ),

        // الوقت
        if (record.responseTimeMs != null)
          Text('${record.responseTimeMs}ms',
              style: TextStyle(
                  color: record.rank <= 3 ? _badgeColor : Colors.white38,
                  fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),

        // الميدالية
        if (_medal.isNotEmpty)
          Text(_medal, style: const TextStyle(fontSize: 18)),
      ]),
    );
  }
}

// ── أزرار التحكم ──────────────────────────────────────────
class _ControlRow extends StatelessWidget {
  final bool roundOpen, hasResults;
  final VoidCallback onStart, onReset;
  const _ControlRow({
    required this.roundOpen, required this.hasResults,
    required this.onStart,   required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // زر فتح / مغلق
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: roundOpen
                ? Colors.orange
                : const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(roundOpen ? Icons.lock : Icons.lock_open, color: Colors.white),
          label: Text(roundOpen ? 'الجرس مفتوح...' : 'فتح الجرس',
              style: const TextStyle(color: Colors.white, fontSize: 15)),
          onPressed: roundOpen ? null : onStart,
        ),
      ),

      if (hasResults) ...[
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3460),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('جولة جديدة',
                style: TextStyle(color: Colors.white, fontSize: 15)),
            onPressed: onReset,
          ),
        ),
      ],
    ]);
  }
}

// ── زر الصوت ──────────────────────────────────────────────
class _SoundToggle extends StatelessWidget {
  final bool enabled;
  final VoidCallback onToggle;
  const _SoundToggle({required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(children: [
          Icon(enabled ? Icons.volume_up : Icons.volume_off,
              size: 16,
              color: enabled ? Colors.white70 : Colors.white24),
          const SizedBox(width: 4),
          Text(enabled ? 'صوت' : 'صامت',
              style: TextStyle(
                  fontSize: 11,
                  color: enabled ? Colors.white70 : Colors.white24)),
        ]),
      ),
    );
  }
}
