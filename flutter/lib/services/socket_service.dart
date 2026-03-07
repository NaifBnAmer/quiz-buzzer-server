// ============================================================
//  SocketService — خدمة Socket.IO (Singleton)
//  + تشغيل صوت الجرس عبر Web Audio API على الويب
// ============================================================

import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ✅ لازم تكون هنا — خارج الكلاس تماماً
@JS('playBuzzSound')
external void _playBuzzSoundJS();

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  static const String serverUrl = 'http://192.168.1.100:3000';

  IO.Socket get socket {
    _socket ??= _initSocket();
    return _socket!;
  }

  IO.Socket _initSocket() {
    return IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );
  }

  void connect() {
    if (!socket.connected) socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  bool get isConnected => socket.connected;

  void emit(String event, dynamic data) => socket.emit(event, data);

  void emitWithAck(String event, dynamic data, Function(dynamic) cb) {
    socket.emitWithAck(event, data, ack: cb);
  }

  void on(String event, Function(dynamic) h) => socket.on(event, h);
  void off(String event) => socket.off(event);

  void playBuzz() {
    if (!kIsWeb) return;
    try {
      _playBuzzSoundJS();
    } catch (_) {}
  }
}
