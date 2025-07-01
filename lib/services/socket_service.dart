import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;

  void connect(String userId) {
    _socket = IO.io('http://your_server_ip_or_url', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      print("Connected to server");
      _socket.emit("notifications", {"userId": userId});
    });

    _socket.onDisconnect((_) => debugPrint("Disconnected"));
  }

  void joinRoom(
      String playerId, String name, int coin, String profileUrl, int timer) {
    _socket.emit("joinRoom", {
      "playerId": playerId,
      "name": name,
      "coin": coin,
      "profileImageUrl": profileUrl,
      "timer": timer,
    });
  }

  void sendMove(String roomId, Map<String, dynamic> moveData) {
    _socket.emit("boardUpdate", {
      "roomId": roomId,
      "boardData": moveData["boardData"],
      "playerId": moveData["playerId"],
      "move": moveData["move"]
    });
  }

  void onBoardUpdate(Function(dynamic) callback) {
    _socket.on("receive_boardData", callback);
  }

  void onGameStart(Function(dynamic) callback) {
    _socket.on("startGame", callback);
  }

  void onPlayerTurn(Function(dynamic) callback) {
    _socket.on("nextPlayerTurn", callback);
  }

  void onTimerUpdate(Function(String, String) callback) {
    _socket.on("timer1", (t) => callback("timer1", t));
    _socket.on("timer2", (t) => callback("timer2", t));
  }

  void onGameOver(Function(dynamic) callback) {
    _socket.on("gameOver", callback);
  }

  void onDrawOffer(Function(dynamic) callback) {
    _socket.on("DrawMessage", callback);
  }

  void acceptDraw(String roomId) {
    _socket.emit("DrawStatus", {"roomId": roomId, "DrawStatus": true});
  }

  void disconnect() {
    _socket.disconnect();
  }
}
