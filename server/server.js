/**
 * ============================================================
 *  Quiz Buzzer - Server (Node.js + Express + Socket.IO)
 *  النسخة المحدثة: يسجّل ترتيب جميع الضاغطين بالوقت
 * ============================================================
 */

require("dotenv").config();
const express = require("express");
const http    = require("http");
const { Server } = require("socket.io");

const app    = express();
const server = http.createServer(app);

// ─── إعداد Socket.IO ────────────────────────────────────────
const io = new Server(server, {
  cors: {
    origin: process.env.ORIGIN || "*",
    methods: ["GET", "POST"],
  },
  transports: ["websocket", "polling"],
});

// ─── تخزين الغرف في الذاكرة ─────────────────────────────────
/**
 * هيكل كل غرفة:
 * {
 *   roomId        : string
 *   hostSocketId  : string
 *   players       : Map<socketId, { id, name }>
 *   isBuzzOpen    : boolean
 *   roundStartTime: number | null
 *   buzzRanking   : [ { rank, id, name, responseTimeMs } ]  ← جديد
 * }
 */
const rooms = new Map();

// ─── دوال مساعدة ────────────────────────────────────────────

function generateRoomId() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let id = "";
  for (let i = 0; i < 6; i++)
    id += chars[Math.floor(Math.random() * chars.length)];
  return id;
}

function broadcastPlayers(roomId) {
  const room = rooms.get(roomId);
  if (!room) return;
  io.to(roomId).emit("players_update", {
    players: Array.from(room.players.values()),
  });
}

// ─── منطق Socket.IO ─────────────────────────────────────────
io.on("connection", (socket) => {
  console.log(`[+] اتصال: ${socket.id}`);

  // ── 1) إنشاء غرفة ─────────────────────────────────────────
  socket.on("create_room", (data, callback) => {
    const roomId = generateRoomId();
    rooms.set(roomId, {
      roomId,
      hostSocketId : socket.id,
      players      : new Map(),
      isBuzzOpen   : false,
      roundStartTime: null,
      buzzRanking  : [],          // ← قائمة الترتيب الكاملة
    });
    socket.join(roomId);
    console.log(`[Room] جديدة: ${roomId}`);
    if (callback) callback({ success: true, roomId });
    else socket.emit("room_created", { roomId });
  });

  // ── 2) انضمام لاعب ────────────────────────────────────────
  socket.on("join_room", ({ roomId, playerName }, callback) => {
    const room = rooms.get(roomId);
    if (!room) {
      const err = { success: false, error: "الغرفة غير موجودة" };
      if (callback) callback(err);
      else socket.emit("join_error", err);
      return;
    }
    const player = { id: socket.id, name: playerName || "لاعب" };
    room.players.set(socket.id, player);
    socket.join(roomId);
    socket.data.roomId     = roomId;
    socket.data.playerName = player.name;
    console.log(`[Join] ${player.name} ← ${roomId}`);
    if (callback) callback({ success: true, player });
    else socket.emit("join_success", { player });
    broadcastPlayers(roomId);
  });

  // ── 3) بدء جولة جديدة ────────────────────────────────────
  socket.on("start_round", ({ roomId }) => {
    const room = rooms.get(roomId);
    if (!room || room.hostSocketId !== socket.id) return;

    room.isBuzzOpen    = true;
    room.roundStartTime = Date.now();
    room.buzzRanking   = [];     // ← تصفير الترتيب

    console.log(`[Round] بدء في ${roomId}`);
    io.to(roomId).emit("round_started", { timestamp: room.roundStartTime });
  });

  // ── 4) إعادة ضبط ─────────────────────────────────────────
  socket.on("reset_round", ({ roomId }) => {
    const room = rooms.get(roomId);
    if (!room || room.hostSocketId !== socket.id) return;
    room.isBuzzOpen    = false;
    room.roundStartTime = null;
    room.buzzRanking   = [];
    io.to(roomId).emit("round_reset");
    console.log(`[Reset] ${roomId}`);
  });

  // ── 5) ضغط الجرس ─────────────────────────────────────────
  socket.on("buzz", ({ roomId, playerId }) => {
    const room = rooms.get(roomId);
    // الجرس لازم يكون مفتوح (لكن الآن نسجّل كل الضاغطين بالترتيب)
    if (!room || !room.isBuzzOpen) return;

    const player = room.players.get(playerId || socket.id);
    if (!player) return;

    // تجنب تسجيل نفس اللاعب مرتين في نفس الجولة
    const alreadyBuzzed = room.buzzRanking.some((b) => b.id === player.id);
    if (alreadyBuzzed) return;

    const responseTimeMs = room.roundStartTime
      ? Date.now() - room.roundStartTime
      : null;

    // أضف اللاعب لقائمة الترتيب
    room.buzzRanking.push({
      rank         : room.buzzRanking.length + 1,
      id           : player.id,
      name         : player.name,
      responseTimeMs,
    });

    // أول ضاغط = أغلق الجرس
    if (room.buzzRanking.length === 1) {
      room.isBuzzOpen = false;
      console.log(`[Buzz] الأول: ${player.name} (${responseTimeMs}ms) في ${roomId}`);
    } else {
      console.log(`[Buzz] #${room.buzzRanking.length}: ${player.name} (${responseTimeMs}ms)`);
    }

    // أرسل النتيجة الكاملة لجميع من في الغرفة
    io.to(roomId).emit("buzz_result", {
      first       : room.buzzRanking[0],   // الأول فقط للتمييز
      buzzRanking : room.buzzRanking,       // الترتيب الكامل
    });
  });

  // ── 6) انقطاع الاتصال ────────────────────────────────────
  socket.on("disconnect", () => {
    const roomId = socket.data.roomId;
    if (!roomId) return;
    const room = rooms.get(roomId);
    if (!room) return;

    if (room.hostSocketId === socket.id) {
      io.to(roomId).emit("room_closed", { reason: "أنهى المضيف الجلسة" });
      rooms.delete(roomId);
      console.log(`[Room] حُذفت ${roomId}`);
      return;
    }
    room.players.delete(socket.id);
    console.log(`[-] ${socket.data.playerName} غادر ${roomId}`);
    broadcastPlayers(roomId);
  });
});

// ─── تشغيل ──────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`\n🚀 السيرفر يعمل على: http://localhost:${PORT}\n`);
});
