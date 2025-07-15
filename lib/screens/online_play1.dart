import 'package:dynamochess/utils/api_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class OnlinePlayScreen extends StatefulWidget {
  const OnlinePlayScreen({Key? key}) : super(key: key);

  @override
  _OnlinePlayScreenState createState() => _OnlinePlayScreenState();
}

class _OnlinePlayScreenState extends State<OnlinePlayScreen> {
  late IO.Socket socket;
  String? roomId;
  bool startGame = false;
  String timer1 = '00:00';
  String timer2 = '00:00';
  List<Map<String, dynamic>> players = [];
  String playerNextTurnColor = 'w'; // 'w' or 'b'
  String? playerNextId;
  Map<String, dynamic>? winData;
  String? drawMessage;
  bool drawStatus = false;
  String? threefoldMessage;
  bool threefoldStatus = false;
  bool rematchRequested = false;
  bool takebackRequested = false;
  List<String> moveList = [];
  final TextEditingController messageController = TextEditingController();
  List<Map<String, String>> chatMessages = [];
  bool isMessageDisabled = false;
  bool isPopupDisabled = false;
  bool newGameTriggered = false;
  bool isGameAborted = false;
  bool isRoomLeft = false;
  bool showLeaveConfirmation = false;
  bool showRematchConfirmation = false;
  bool showTakebackConfirmation = false;
  bool showDrawConfirmation = false;
  bool showThreefoldConfirmation = false;
  bool timerIs60 = false;

  String? userId;
  String? userName;
  String? userProfileImage;
  double? userRating;
  String? countryIcon;

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      if (userId != null) {
        _connectSocket();
      } else {
        Get.snackbar("Error", "User not logged in");
        Get.offAllNamed('/login');
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      userName = prefs.getString('name');
      userProfileImage = prefs.getString('profileImageUrl');
      userRating = prefs.getDouble('rating');
      countryIcon = prefs.getString('countryIcon');
    });
  }

  void _connectSocket() {
    socket = IO.io(ApiList.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to Socket.IO');
      _joinRoom();
    });

    socket.onDisconnect((_) => print('Disconnected from Socket.IO'));
    socket.onConnectError((err) => print('Connection Error: $err'));
    socket.onError((err) => print('Socket Error: $err'));

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    socket.on('roomJoined', (data) {
      setState(() {
        roomId = data['roomId'];
      });
    });

    socket.on('createPosition', (data) {
      setState(() {
        startGame = true;
        isPopupDisabled = true;
      });
      // Handle initial board setup here
    });

    socket.on('receive_boardData', (data) {
      // Update board state from server
      setState(() {
        isGameAborted = false;
        isRoomLeft = false;
        winData = null;
        drawMessage = null;
        drawStatus = false;
        threefoldMessage = null;
        takebackRequested = false;
        rematchRequested = false;
      });
    });

    socket.on('updatedRoom', (data) {
      setState(() {
        roomId = data['_id'];
        players = List<Map<String, dynamic>>.from(data['players']);
        moveList = List<String>.from(data['moveList'] ?? []);
        timer1 = _convertSecondsToMinutes(data['timer1'] ?? 0);
        timer2 = _convertSecondsToMinutes(data['timer2'] ?? 0);
      });
    });

    socket.on('startGame', (data) {
      setState(() {
        startGame = data['start'];
        isPopupDisabled = true;
      });
    });

    socket.on('timer1', (data) {
      setState(() {
        timer1 = data;
      });
    });

    socket.on('timer2', (data) {
      setState(() {
        timer2 = data;
      });
    });

    socket.on('nextPlayerTurn', (data) {
      setState(() {
        playerNextTurnColor = data['playerColour'];
        playerNextId = data['playerId'];
      });
    });

    socket.on('playerWon', (data) {
      setState(() {
        winData = data;
      });
    });

    socket.on('abort', (data) {
      setState(() {
        isGameAborted = true;
      });
    });

    socket.on('roomLeftPlayerId', (data) {
      setState(() {
        isRoomLeft = true;
      });
    });

    // Add other event listeners as needed
  }

  String _convertSecondsToMinutes(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _joinRoom() {
    if (userId == null) return;

    socket.emit('joinRoom', {
      "playerId": userId,
      "name": userName,
      "coin": 200, // Assuming fixed coin value
      "profileImageUrl": userProfileImage ?? "",
      "playerStatus": "Ready",
      "joinId": "randomMultiplayer",
      "timer": "600", // 10 minutes
      "countryicon": countryIcon,
    });
  }

  void _sendMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (roomId == null || userId == null) return;

    socket.emit('move', {
      'roomId': roomId,
      'playerId': userId,
      'oldX': fromRow,
      'oldY': fromCol,
      'newX': toRow,
      'newY': toCol,
      'colour': playerNextTurnColor,
      'currentTimer': playerNextId == userId ? timer1 : timer2,
    });
  }

  void requestDraw() {
    if (roomId == null || userId == null) return;
    socket.emit('Draw', {
      'roomId': roomId,
      'playerId': userId,
    });
  }

  void handleRematch() {
    if (roomId == null || userId == null) return;
    socket.emit('rematchRequest', {
      'roomId': roomId,
      'playerId': userId,
    });
  }

  void handleLeaveRoom() {
    if (roomId == null || userId == null) return;
    socket.emit('leaveRoom', {
      'roomId': roomId,
      'playerId': userId,
    });
    Get.back();
  }

  @override
  void dispose() {
    socket.disconnect();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMyTurn = playerNextId == userId;
    final currentPlayerColor =
        players.isNotEmpty && players.any((p) => p['playerId'] == userId)
            ? players.firstWhere((p) => p['playerId'] == userId)['colour']
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Chess'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => setState(() => showLeaveConfirmation = true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top player info
          _buildPlayerInfo(
            players.isNotEmpty && players.length > 1 ? players[0] : null,
            timer1,
            playerNextId == players[0]['playerId'],
          ),

          // Chess board
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                  ),
                  itemBuilder: (context, index) {
                    // Build your chess board squares here
                    return Container(
                      decoration: BoxDecoration(
                        color: (index ~/ 10 + index % 10) % 2 == 0
                            ? Colors.brown[200]
                            : Colors.brown[400],
                      ),
                      child: Center(
                          // Render chess pieces here
                          ),
                    );
                  },
                  itemCount: 100,
                ),
              ),
            ),
          ),

          // Bottom player info
          _buildPlayerInfo(
            players.isNotEmpty && players.length > 1 ? players[1] : null,
            timer2,
            playerNextId == players[1]['playerId'],
          ),

          // Game controls
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => requestDraw(),
                  child: const Text('Offer Draw'),
                ),
                ElevatedButton(
                  onPressed: () => handleRematch(),
                  child: const Text('Rematch'),
                ),
              ],
            ),
          ),

          // Chat section
          _buildChatSection(),

          // Confirmation dialogs
          if (showLeaveConfirmation)
            _buildConfirmationDialog(
              'Leave Game?',
              'Are you sure you want to leave the game?',
              handleLeaveRoom,
              () => setState(() => showLeaveConfirmation = false),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(
      Map<String, dynamic>? player, String timer, bool isActive) {
    if (player == null) {
      return const ListTile(
        title: Text('Waiting for opponent...'),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(player['profileImageUrl'] ?? ''),
        child:
            player['profileImageUrl'] == null ? const Icon(Icons.person) : null,
      ),
      title: Text(player['name'] ?? 'Anonymous'),
      subtitle: Text('Rating: ${player['Rating']?.toStringAsFixed(1) ?? '0'}'),
      trailing: Text(
        timer,
        style: TextStyle(
          fontSize: 20,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final msg = chatMessages[index];
                final isMe = msg['playerId'] == userId;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['message']!),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  enabled: !isMessageDisabled,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (messageController.text.trim().isNotEmpty) {
                    socket.emit('send_message', {
                      'roomId': roomId,
                      'playerId': userId,
                      'message': messageController.text.trim(),
                    });
                    messageController.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationDialog(
    String title,
    String message,
    VoidCallback onConfirm,
    VoidCallback onCancel,
  ) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
