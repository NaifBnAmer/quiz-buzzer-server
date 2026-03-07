// ============================================================
//  GameProvider — إدارة الحالة الكاملة للعبة
//  التحديثات: ترتيب الضاغطين + تحكم الصوت + نصوص مذكر
// ============================================================

import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';

enum BuzzerState { idle, open, won, lost }
enum RoomRole    { none, host, player }

// ── نموذج اللاعب ──────────────────────────────────────────
class Player {
  final String id;
  final String name;
  Player({required this.id, required this.name});
  factory Player.fromMap(Map<String, dynamic> m) =>
      Player(id: m['id'] ?? '', name: m['name'] ?? '');
}

// ── نموذج الفائز (الأول) ─────────────────────────────────
class FirstPlayer {
  final String id;
  final String name;
  final int?   responseTimeMs;
  FirstPlayer({required this.id, required this.name, this.responseTimeMs});
  factory FirstPlayer.fromMap(Map<String, dynamic> m) => FirstPlayer(
        id            : m['id']   ?? '',
        name          : m['name'] ?? '',
        responseTimeMs: m['responseTimeMs'],
      );
}

// ── نموذج سجل الجرس (لكل مشارك) ─────────────────────────
class BuzzRecord {
  final int    rank;
  final String id;
  final String name;
  final int?   responseTimeMs;
  BuzzRecord({
    required this.rank,
    required this.id,
    required this.name,
    this.responseTimeMs,
  });
  factory BuzzRecord.fromMap(Map<String, dynamic> m) => BuzzRecord(
        rank          : m['rank']           ?? 0,
        id            : m['id']             ?? '',
        name          : m['name']           ?? '',
        responseTimeMs: m['responseTimeMs'],
      );
}

// ─────────────────────────────────────────────────────────
class GameProvider extends ChangeNotifier {
  final SocketService _socket = SocketService();

  // بيانات الجلسة
  RoomRole role         = RoomRole.none;
  String?  roomId;
  String?  myPlayerId;
  String?  myPlayerName;
  List<Player> players  = [];

  // حالة الجرس
  BuzzerState     buzzerState    = BuzzerState.idle;
  FirstPlayer?    firstPlayer;          // الأول في الجولة
  List<BuzzRecord> buzzRanking   = [];  // ترتيب جميع الضاغطين

  // إعدادات عامة
  bool isConnected = false;
  bool soundEnabled = true;             // تشغيل/إيقاف الصوت
  String? errorMessage;
  bool roomClosed = false;

  // ── تهيئة وتسجيل أحداث Socket ──────────────────────────
  void initialize() {
    _socket.connect();

    _socket.on('connect', (_) {
      isConnected  = true;
      errorMessage = null;
      notifyListeners();
    });

    _socket.on('disconnect', (_) {
      isConnected = false;
      notifyListeners();
    });

    _socket.on('connect_error', (err) {
      errorMessage = 'فشل الاتصال: $err';
      notifyListeners();
    });

    // تحديث قائمة اللاعبين
    _socket.on('players_update', (data) {
      final List raw = (data as Map)['players'] ?? [];
      players = raw.map((p) => Player.fromMap(Map<String, dynamic>.from(p))).toList();
      notifyListeners();
    });

    // بدء الجولة
    _socket.on('round_started', (_) {
      buzzerState  = BuzzerState.open;
      firstPlayer  = null;
      buzzRanking  = [];
      notifyListeners();
    });

    // إعادة الضبط
    _socket.on('round_reset', (_) {
      buzzerState = BuzzerState.idle;
      firstPlayer = null;
      buzzRanking = [];
      notifyListeners();
    });

    // نتيجة الجرس — تحتوي الأول + الترتيب الكامل
    _socket.on('buzz_result', (data) {
      final map = data as Map;

      // الأول
      firstPlayer = FirstPlayer.fromMap(
          Map<String, dynamic>.from(map['first']));

      // الترتيب الكامل
      final List rawRanking = map['buzzRanking'] ?? [];
      buzzRanking = rawRanking
          .map((r) => BuzzRecord.fromMap(Map<String, dynamic>.from(r)))
          .toList();

      // هل أنا الأول؟
      buzzerState = (firstPlayer?.id == myPlayerId)
          ? BuzzerState.won
          : BuzzerState.lost;

      notifyListeners();
    });

    // إغلاق الغرفة
    _socket.on('room_closed', (_) {
      roomClosed = true;
      notifyListeners();
    });
  }

  // ── إنشاء غرفة ──────────────────────────────────────────
  void createRoom() {
    role = RoomRole.host;
    _socket.emitWithAck('create_room', {}, (res) {
      final r = Map<String, dynamic>.from(res);
      if (r['success'] == true) {
        roomId = r['roomId'];
        notifyListeners();
      }
    });
  }

  // ── الانضمام للغرفة ─────────────────────────────────────
  void joinRoom(String id, String name) {
    role          = RoomRole.player;
    myPlayerName  = name;
    _socket.emitWithAck('join_room', {'roomId': id, 'playerName': name}, (res) {
      final r = Map<String, dynamic>.from(res);
      if (r['success'] == true) {
        roomId       = id;
        myPlayerId   = (r['player'] as Map)['id'];
        errorMessage = null;
      } else {
        errorMessage = r['error'] ?? 'خطأ في الانضمام';
      }
      notifyListeners();
    });
  }

  // ── بدء الجولة ──────────────────────────────────────────
  void startRound() {
    if (roomId == null) return;
    _socket.emit('start_round', {'roomId': roomId});
  }

  // ── إعادة الضبط ─────────────────────────────────────────
  void resetRound() {
    if (roomId == null) return;
    _socket.emit('reset_round', {'roomId': roomId});
  }

  // ── ضغط الجرس ───────────────────────────────────────────
  void buzz() {
    if (roomId == null || buzzerState != BuzzerState.open) return;
    _socket.emit('buzz', {'roomId': roomId, 'playerId': myPlayerId});
  }

  // ── تبديل الصوت ─────────────────────────────────────────
  void toggleSound() {
    soundEnabled = !soundEnabled;
    notifyListeners();
  }

  // ── تنظيف ───────────────────────────────────────────────
  @override
  void dispose() {
    for (final e in ['connect','disconnect','connect_error',
                     'players_update','round_started','round_reset',
                     'buzz_result','room_closed']) {
      _socket.off(e);
    }
    super.dispose();
  }
}
