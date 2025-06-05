import 'package:dynamochess/models/user_details.dart';
import 'package:dynamochess/screens/chesspiece.dart';
import 'package:dynamochess/utils/api_list.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart'; // For playing sounds
import 'package:shared_preferences/shared_preferences.dart'; // For accessing SharedPreferences

// --- Mock UserDetail (updated to accept real data) ---

void toastInfo(String message) {
  // Replace with your actual toast/snackbar implementation
  print('Toast: $message');
  // Example using ScaffoldMessenger (requires a BuildContext)
  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
// -----------------------------------------------------------------------------

class ChessBoardScreen extends StatefulWidget {
  const ChessBoardScreen({super.key});

  @override
  _ChessBoardScreenState createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  static const int boardSize = 10;
  List<List<ChessPiece?>> board =
      List.generate(boardSize, (i) => List.filled(boardSize, null));
  PieceColor currentPlayer = PieceColor.white;
  Position? selectedPosition;
  List<Position> possibleMoves = [];
  String gameStatus = 'White\'s turn';

  // --- Socket.IO related state ---
  IO.Socket? socket;
  String? roomId;
  bool startGame = false;
  String timer1 = '00:00';
  String timer2 = '00:00';
  List<Map<String, dynamic>> players = [];
  String playerNextTurnColor = ''; // 'w' or 'b'
  String playerNextId = '';
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
  bool isPopupDisabled = false; // For the "Please wait for opponent" popup
  bool newGameTriggered = false;
  bool isGameAborted = false;
  bool isRoomLeft = false;
  bool showLeaveConfirmation = false;
  bool showRematchConfirmation = false;
  bool showTakebackConfirmation = false;
  bool showDrawConfirmation = false;
  bool showThreefoldConfirmation = false;
  bool timerIs60 = false; // To trigger sound at 59 seconds

  // Real UserDetail will be loaded here
  UserDetail? _currentUserDetail;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      if (_currentUserDetail != null) {
        _initializeBoard();
        _connectSocket();
        setState(() {
          gameStatus = 'Initializing game...';
        });
      } else {
        setState(() {
          gameStatus = 'Please log in to play';
        });
      }
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    messageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Loads user data from SharedPreferences
  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserDetail = UserDetail.fromSharedPreferences(prefs);
      // Ensure user ID is available before trying to join a room
      if (_currentUserDetail?.id.isEmpty ?? true) {
        toastInfo("User not logged in. Please log in to play online.");
        // Consider navigating to login screen here
      }
    });
  }

  // Converts total seconds into a formatted minute:second string
  String _convertSecondsToMinutes(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    String formattedSeconds = seconds < 10 ? '0$seconds' : '$seconds';
    return '$minutes:$formattedSeconds';
  }

  void _connectSocket() {
    // Replace with your actual backend URL
    socket = IO.io(ApiList.baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'reconnection': true,
      'timeout': 20000,
    });

    socket?.connect();

    socket?.onConnect((_) {
      print('Connected to Socket.IO');
      if (_currentUserDetail != null && _currentUserDetail!.id.isNotEmpty) {
        _joinRoom();
      }
    });

    socket?.onDisconnect((_) => print('Disconnected from Socket.IO'));
    socket?.onConnectError((err) => print('Connection Error: $err'));
    socket?.onError((err) => print('Socket Error: $err.toString()'));

    _setupSocketListeners();
  }

  // Sets up listeners for various Socket.IO events
  void _setupSocketListeners() {
    socket?.on('roomJoined', (data) {
      setState(() {
        roomId = data['roomId'];
        print('Room Joined: $roomId');
      });
    });

    socket?.on('createPosition', (data) {
      final List<dynamic> initialBoard = data['createPosition'];
      // final String opponentPlayerId = data['positions'][0]['playerId']; // This is not directly used for board setup here

      setState(() {
        startGame = true;
        isPopupDisabled = true; // Hide "Please wait" popup
        // Set the current player ID based on who is 'w' or 'b'
        // This logic needs to match the backend's assignment of 'w' and 'b'
        if (players.isNotEmpty && _currentUserDetail != null) {
          final currentPlayerColor = players.firstWhere(
              (p) => p['playerId'] == _currentUserDetail!.id,
              orElse: () => {'colour': 'w'})['colour'];

          // The backend sends the board from white's perspective.
          // If current user is black, reverse the board for display.
          if (currentPlayerColor == 'b') {
            board = _convertBackendBoard(initialBoard, reverse: true);
          } else {
            board = _convertBackendBoard(initialBoard, reverse: false);
          }
        }
        playerNextId =
            players.isNotEmpty ? players[0]['playerId'] : ''; // White starts
        playerNextTurnColor = 'w';
      });
    });

    socket?.on('receive_boardData', (data) {
      final List<dynamic> newPositionData = data['data']['newPosition'];
      // final String receivedPlayerId = data['playerId']; // Not directly used for board update
      // final String receivedPlayerColor = data['playerColour']; // Not directly used for board update

      setState(() {
        isGameAborted = false;
        isRoomLeft = false;
        winData = null;
        drawMessage = null;
        drawStatus = false;
        threefoldMessage = null;
        takebackRequested = false;
        rematchRequested = false;

        // Determine if the board needs to be reversed for the current user
        if (players.isNotEmpty && _currentUserDetail != null) {
          final currentPlayerColor = players.firstWhere(
              (p) => p['playerId'] == _currentUserDetail!.id,
              orElse: () => {'colour': 'w'})['colour'];

          if (currentPlayerColor == 'b') {
            board = _convertBackendBoard(newPositionData, reverse: true);
          } else {
            board = _convertBackendBoard(newPositionData, reverse: false);
          }
        }
      });
    });

    socket?.on('updatedRoom', (data) {
      print('Updated Room: $data');
      setState(() {
        roomId = data['_id'];
        players = List<Map<String, dynamic>>.from(data['players']);
        moveList = List<String>.from(data['moveList'] ?? []);
        timer1 = _convertSecondsToMinutes(data['timer1'] ?? 0);
        timer2 = _convertSecondsToMinutes(data['timer2'] ?? 0);

        // Update board if allBoardData is available and not empty
        if (data['allBoardData'] != null && data['allBoardData'].isNotEmpty) {
          final List<dynamic> latestBoardData =
              data['allBoardData'].last['newPosition'];
          if (players.isNotEmpty && _currentUserDetail != null) {
            final currentPlayerColor = players.firstWhere(
                (p) => p['playerId'] == _currentUserDetail!.id,
                orElse: () => {'colour': 'w'})['colour'];

            if (currentPlayerColor == 'b') {
              board = _convertBackendBoard(latestBoardData, reverse: true);
            } else {
              board = _convertBackendBoard(latestBoardData, reverse: false);
            }
          }
        }
      });
    });

    socket?.on('startGame', (data) {
      setState(() {
        startGame = data['start'];
        isPopupDisabled = true; // Hide "Please wait" popup
      });
    });

    socket?.on('timer1', (data) {
      setState(() {
        timer1 = data;
      });
    });

    socket?.on('timer2', (data) {
      setState(() {
        timer2 = data;
      });
    });

    socket?.on('nextPlayerTurn', (data) {
      setState(() {
        playerNextTurnColor = data['playerColour'];
        playerNextId = data['playerId'];
        gameStatus =
            '${playerNextTurnColor == 'w' ? 'White' : 'Black'}\'s turn';
      });
    });

    socket?.on('playerWon', (data) {
      setState(() {
        winData = data;
        gameStatus = data['playerId'] == _currentUserDetail?.id
            ? 'You Win!'
            : 'You Lose!';
        _playGameEndSound(winData?['playerId'] == _currentUserDetail?.id);
      });
    });

    socket?.on('abort', (data) {
      setState(() {
        isGameAborted = true;
        gameStatus = 'Game Aborted!';
      });
    });

    socket?.on('checkMate', (data) {
      setState(() {
        gameStatus = 'Checkmate!';
        _playGameEndSound(winData?['playerId'] == _currentUserDetail?.id);
      });
    });

    socket?.on('roomLeftPlayerId', (data) {
      setState(() {
        isRoomLeft = true;
        gameStatus = 'Opponent Left!';
      });
    });

    socket?.on('DrawMessage', (data) {
      setState(() {
        drawMessage = data['message'];
        showDrawConfirmation = true;
      });
    });

    socket?.on('DrawStatus', (data) {
      setState(() {
        drawStatus = data['DrawStatus'];
        if (drawStatus) {
          gameStatus = 'Game Drawn!';
          _playGameEndSound(null); // Play draw sound
        }
        showDrawConfirmation = false;
      });
    });

    socket?.on('ThreeFold', (data) {
      setState(() {
        threefoldMessage = data['message'];
        showThreefoldConfirmation = true;
      });
    });

    socket?.on('threefoldStatus', (data) {
      setState(() {
        threefoldStatus = data['threefoldStatus'];
        if (threefoldStatus) {
          gameStatus = 'Game Drawn by Threefold Repetition!';
          _playGameEndSound(null);
        }
        showThreefoldConfirmation = false;
      });
    });

    socket?.on('rematch', (data) {
      setState(() {
        rematchRequested = data;
        showRematchConfirmation = true;
      });
    });

    socket?.on('rematchResponse', (data) {
      setState(() {
        rematchRequested = false;
        showRematchConfirmation = false;
        if (data != false) {
          newGameTriggered = true;
          // In a real app, you'd navigate to the new room,
          // for this example, we'll just reload the board.
          _resetGame(); // Simulate new game
          _joinRoom(); // Join the new room
        }
      });
    });

    socket?.on('turnBack', (data) {
      setState(() {
        takebackRequested = data;
        showTakebackConfirmation = true;
      });
    });

    socket?.on('turnBackStatus', (data) {
      setState(() {
        takebackRequested = false;
        showTakebackConfirmation = false;
        if (data['turnBackStatus'] == true) {
          // Backend should send the updated board after takeback
          // For now, we'll just acknowledge
          print('Takeback accepted!');
        }
      });
    });

    socket?.on('timerIs60', (data) {
      setState(() {
        timerIs60 = data['successfully'];
        if (timerIs60 && data['playerId'] == _currentUserDetail?.id) {
          _audioPlayer
              .play(AssetSource('sound/sort3.mp3')); // Play timer warning sound
        }
      });
    });

    socket?.on('receive_message', (data) {
      setState(() {
        chatMessages.add({
          'playerId': data['playerId'],
          'message': data['message'],
        });
      });
    });

    socket?.on('castlingStatus', (data) {
      // Handle castling status if needed for UI, not directly used in this board logic
      print('Castling Status: ${data['status']} for ${data['playerColour']}');
    });

    socket?.on('allBoardData', (data) {
      // This event provides the full history of board states
      // Useful for move navigation, but `receive_boardData` handles current state
      print('Received all board data history.');
    });

    socket?.on('errorOccured', (data) {
      toastInfo('Error: $data');
    });
  }

  // Helper to convert backend board (List<List<String>>) to Flutter board (List<List<ChessPiece?>>)
  List<List<ChessPiece?>> _convertBackendBoard(List<dynamic> backendBoard,
      {bool reverse = false}) {
    List<List<ChessPiece?>> newBoard =
        List.generate(boardSize, (i) => List.filled(boardSize, null));

    List<dynamic> effectiveBoard =
        reverse ? backendBoard.reversed.toList() : backendBoard;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final pieceString = effectiveBoard[r][c] as String;
        if (pieceString.isNotEmpty) {
          newBoard[r][c] = _getPieceFromSymbol(pieceString);
        }
      }
    }
    return newBoard;
  }

  // Helper to get ChessPiece from backend symbol string
  ChessPiece? _getPieceFromSymbol(String symbol) {
    if (symbol.isEmpty) return null;

    final PieceColor color =
        symbol[0] == 'w' ? PieceColor.white : PieceColor.black;
    final String typeChar = symbol[1];

    PieceType? type;
    switch (typeChar) {
      case 'p':
        type = PieceType.pawn;
        break;
      case 'r':
        type = PieceType.rook;
        break;
      case 'n':
        type = PieceType.knight;
        break;
      case 'b':
        type = PieceType.bishop;
        break;
      case 'q':
        type = PieceType.queen;
        break;
      case 'k':
        type = PieceType.king;
        break;
      case 'm': // Assuming 'm' is for missile
        type = PieceType.missile;
        break;
    }
    return type != null ? ChessPiece(color, type) : null;
  }

  // Joins a room on the backend
  void _joinRoom() {
    // Ensure user data is loaded before attempting to join
    if (_currentUserDetail == null || _currentUserDetail!.id.isEmpty) {
      toastInfo("User data not loaded. Cannot join room.");
      return;
    }

    final String currentUrl = Uri.base.toString();
    final bool isTournament = currentUrl.contains("tournament:");
    final String? uniqueID =
        isTournament ? currentUrl.split("tournament:")[1].split('/')[0] : null;
    final String currentRoomId =
        uniqueID ?? 'randomMultiplayer'; // Default to random
    const String currentTime = '600'; // Default time for now

    if (_currentUserDetail!.dynamoCoin > 200) {
      final Map<String, dynamic> joinRoomData = {
        "playerId": _currentUserDetail!.id,
        "name": _currentUserDetail!.name,
        "coin": 200, // Assuming a fixed coin value for joining
        "profileImageUrl": "null", // Placeholder
        "playerStatus": "Good", // Placeholder
        "joinId": currentRoomId,
        "timer": currentTime,
        "countryicon": _currentUserDetail!.countryIcon,
        "colour": players.isNotEmpty &&
                players.any((p) => p['playerId'] == _currentUserDetail!.id)
            ? players.firstWhere(
                (p) => p['playerId'] == _currentUserDetail!.id)['colour']
            : null, // Let backend assign color if not rejoining
      };

      if (isTournament) {
        socket?.emit('joinRoomViaTournament', joinRoomData);
      } else if (currentRoomId == "randomMultiplayer") {
        socket?.emit('joinRoom', joinRoomData);
      } else {
        socket?.emit('joinById', joinRoomData);
      }
    } else {
      toastInfo("Minimum point 2000 is not available");
      // Navigate away or show error
    }
  }

  void _initializeBoard() {
    // Clear the board
    board = List.generate(boardSize, (i) => List.filled(boardSize, null));

    // Pawns (two rows for each side in 10x10)
    for (int i = 0; i < boardSize; i++) {
      board[1][i] = ChessPiece(PieceColor.black, PieceType.pawn);
      board[boardSize - 2][i] = ChessPiece(PieceColor.white, PieceType.pawn);
    }

    // Custom back row with Missiles at positions 3 and 7
    final blackPiecesOrder = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.missile,
      PieceType.queen,
      PieceType.king,
      PieceType.missile,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook
    ];

    final whitePiecesOrder = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.missile,
      PieceType.king,
      PieceType.queen,
      PieceType.missile,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook
    ];

    // Black pieces (top row)
    for (int i = 0; i < boardSize; i++) {
      board[0][i] = ChessPiece(PieceColor.black, blackPiecesOrder[i]);
    }

    // White pieces (bottom row)
    for (int i = 0; i < boardSize; i++) {
      board[boardSize - 1][i] =
          ChessPiece(PieceColor.white, whitePiecesOrder[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the current player's color for UI display
    final currentPlayerIsWhite = players.isNotEmpty &&
        players.any((p) =>
            p['playerId'] == _currentUserDetail?.id && p['colour'] == 'w');

    // Determine whose timer to display at the top/bottom based on current player
    String topTimer = currentPlayerIsWhite ? timer2 : timer1;
    String bottomTimer = currentPlayerIsWhite ? timer1 : timer2;

    // Determine player info for top and bottom display
    Map<String, dynamic>? topPlayer;
    Map<String, dynamic>? bottomPlayer;

    if (players.length == 2) {
      if (currentPlayerIsWhite) {
        topPlayer =
            players.firstWhere((p) => p['colour'] == 'b', orElse: () => {});
        bottomPlayer =
            players.firstWhere((p) => p['colour'] == 'w', orElse: () => {});
      } else {
        topPlayer =
            players.firstWhere((p) => p['colour'] == 'w', orElse: () => {});
        bottomPlayer =
            players.firstWhere((p) => p['colour'] == 'b', orElse: () => {});
      }
    } else if (players.length == 1) {
      // If only one player, assume they are the current user and display them at the bottom
      bottomPlayer = players[0];
      topPlayer = {'name': 'Waiting...', 'countryicon': null, 'Rating': 0.0};
    } else {
      topPlayer = {'name': 'Waiting...', 'countryicon': null, 'Rating': 0.0};
      bottomPlayer = {'name': 'Waiting...', 'countryicon': null, 'Rating': 0.0};
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Play'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: Text(gameStatus)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Added SingleChildScrollView here
        child: Column(
          children: [
            // Top Player Info & Timer
            _buildPlayerInfo(
                topPlayer, topTimer, playerNextId == topPlayer['playerId']),

            // The board itself is already within an Expanded, so it will fill available space
            // within the scrollable area.
            LayoutBuilder(
              builder: (context, constraints) {
                final boardDimension =
                    constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight;

                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: boardDimension,
                        height: boardDimension,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: boardSize,
                          ),
                          itemCount: boardSize * boardSize,
                          itemBuilder: (context, index) {
                            final row = index ~/ boardSize;
                            final col = index % boardSize;
                            final piece = board[row][col];
                            final isSelected = selectedPosition?.row == row &&
                                selectedPosition?.col == col;
                            final isPossibleMove = possibleMoves
                                .any((pos) => pos.row == row && pos.col == col);

                            return GestureDetector(
                              onTap: () => _handleTap(row, col),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getSquareColor(
                                      row, col, isSelected, isPossibleMove),
                                  border: Border.all(
                                      color: Colors.black54, width: 0.5),
                                ),
                                child: Center(
                                  child: piece != null
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              _getPieceImageAsset(piece),
                                              width: 30,
                                              height: 30,
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // "Please wait for opponent" popup
                      if (!startGame && !isPopupDisabled)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            players.length < 2
                                ? 'Please Wait for an Opponent'
                                : 'Please wait for your paired opponent \nfor this Round to join the board',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Bottom Player Info & Timer
            _buildPlayerInfo(bottomPlayer, bottomTimer,
                playerNextId == bottomPlayer['playerId']),

            // Game Control Buttons
            // _buildGameControls(),

            // Chat Section
            // _buildChatSection(),

            // Confirmation Popups
            _buildConfirmationDialog(
              context,
              showLeaveConfirmation,
              'Do you want to Leave Game?',
              () => handleLeaveRoom(),
              () => setState(() => showLeaveConfirmation = false),
            ),
            _buildConfirmationDialog(
              context,
              showDrawConfirmation,
              drawMessage ?? 'Your opponent offers a draw',
              () => HandleDraw(),
              () => CancelDraw(),
            ),
            _buildConfirmationDialog(
              context,
              showRematchConfirmation,
              'Do you wanna play game',
              () => HandleRematchAccept(),
              () => CancelRematch(),
            ),
            _buildConfirmationDialog(
              context,
              showTakebackConfirmation,
              'Your opponent proposes a takeback',
              () => HandleTackbackAccept(),
              () => CancelTackback(),
            ),
            _buildConfirmationDialog(
              context,
              showThreefoldConfirmation,
              threefoldMessage ?? 'Your opponent offers a Threefold Draw',
              () => Handlethreefold(),
              () => setState(() => showThreefoldConfirmation = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(
      Map<String, dynamic>? player, String timer, bool isCurrentTurn) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                color: isCurrentTurn ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                player?['name'] ?? 'Anonymous',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (player?['countryicon'] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.network(
                    player!['countryicon'],
                    width: 30,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.flag), // Fallback
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Rating: ${player?['Rating']?.toStringAsFixed(2) ?? '0'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          Text(
            timer,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGameControls() {
    bool isGameEnded = isGameAborted ||
        isRoomLeft ||
        winData != null ||
        drawStatus ||
        threefoldStatus;
    bool isTournament = false; // You'd get this from your navigation logic
    bool isAbortDisabled = moveList.length > 1 || isGameEnded || isTournament;
    bool isDrawDisabled = moveList.isEmpty || isGameEnded || isTournament;
    bool isLeaveDisabled = moveList.isEmpty || isGameEnded;
    bool isTakebackDisabled = moveList.isEmpty || isGameEnded;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: isAbortDisabled ? null : () => abortGame(),
                child: const Text('Abort'),
              ),
              ElevatedButton(
                onPressed: isDrawDisabled ? null : () => requestDraw(),
                child: const Text('Draw'),
              ),
              ElevatedButton(
                onPressed: isLeaveDisabled
                    ? null
                    : () => setState(() => showLeaveConfirmation = true),
                child: const Text('Resign'),
              ),
              ElevatedButton(
                onPressed: isTakebackDisabled ? null : () => HandleTackback(),
                child: const Text('Takeback'),
              ),
            ],
          ),
          if (isGameEnded)
            Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  winData != null
                      ? (winData?['playerId'] == _currentUserDetail?.id
                          ? 'You Win!'
                          : 'You Lose!')
                      : (drawStatus || threefoldStatus
                          ? 'Game Drawn!'
                          : 'Game Aborted!'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => HandleRematch(),
                  child: const Text('Rematch'),
                ),
                ElevatedButton(
                  onPressed: () => {},
                  //  NewGame(),
                  child: const Text('New Opponent'),
                ),
                // If it's a tournament, you might have a dashboard button
                // ElevatedButton(
                //   onPressed: () => handleGoToDashboard(), // Implement this
                //   child: const Text('Go to Dashboard'),
                // ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    isMessageDisabled = !startGame ||
        isGameAborted ||
        isRoomLeft ||
        winData != null ||
        drawStatus ||
        threefoldStatus;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text('Chat Room',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final msg = chatMessages[index];
                final isMe = msg['playerId'] == _currentUserDetail?.id;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  enabled: !isMessageDisabled,
                  decoration: InputDecoration(
                    hintText: 'Message here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => handleSendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isMessageDisabled ? null : () => handleSendMessage(),
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationDialog(BuildContext context, bool showDialogFlag,
      String message, VoidCallback onAccept, VoidCallback onCancel) {
    if (!showDialogFlag) return const SizedBox.shrink();

    return AlertDialog(
      title: const Text('Confirmation'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            onAccept();
            Navigator.of(context).pop();
          },
          child: const Text('Accept'),
        ),
        TextButton(
          onPressed: () {
            onCancel();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getPieceImageAsset(ChessPiece piece) {
    String colorString = piece.color == PieceColor.white ? 'white' : 'black';
    String type = '';

    switch (piece.type) {
      case PieceType.pawn:
        type = 'pawn';
        break;
      case PieceType.rook:
        type = 'rook';
        break;
      case PieceType.knight:
        type = 'knight';
        break;
      case PieceType.bishop:
        type = 'bishop';
        break;
      case PieceType.queen:
        type = 'queen';
        break;
      case PieceType.king:
        type = 'king';
        break;
      case PieceType.missile:
        type = 'missile';
        break;
    }
    String assetPath = 'assets/images/${colorString}_$type.png';
    // Ensure you have these assets in your pubspec.yaml and project structure
    // Example: assets/images/white_pawn.png, assets/images/black_rook.png etc.
    return assetPath;
  }

  Color _getSquareColor(
      int row, int col, bool isSelected, bool isPossibleMove) {
    if (isSelected) return Colors.blue[400]!;
    if (isPossibleMove) return Colors.blue[200]!;
    return (row + col) % 2 == 0 ? Colors.yellow : Colors.green;
  }

  void _handleTap(int row, int col) {
    final piece = board[row][col];
    print('piece selected ${row} ${col} ${piece?.color}');

    // Only allow interaction if it's the current player's turn
    final currentPlayerColor = players.firstWhere(
        (p) => p['playerId'] == _currentUserDetail?.id,
        orElse: () => {'colour': 'w'})['colour'];
    print(currentPlayerColor);

    if (piece != null &&
        ((piece.color == PieceColor.white && currentPlayerColor == 'w') ||
            (piece.color == PieceColor.black && currentPlayerColor == 'b')) &&
        piece.color ==
            (playerNextTurnColor == 'w'
                ? PieceColor.white
                : PieceColor.black)) {
      setState(() {
        selectedPosition = Position(row, col);
        possibleMoves = _getPossibleMoves(row, col);
        gameStatus = 'Selected: ${piece.name}';
      });
    } else if (selectedPosition != null) {
      final moveIsValid =
          possibleMoves.any((pos) => pos.row == row && pos.col == col);
      if (moveIsValid) {
        print('move is valid');
        _movePiece(selectedPosition!.row, selectedPosition!.col, row, col);
      } else {
        // If an invalid move is attempted, deselect the piece
        setState(() {
          selectedPosition = null;
          possibleMoves = [];
        });
      }
    }
  }

  void _movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    setState(() {
      final movingPiece = board[fromRow][fromCol];
      final capturedPiece = board[toRow][toCol];

      // Store current board state for sending to backend
      List<List<String>> currentBoardState =
          List.generate(boardSize, (r) => List.filled(boardSize, ''));
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          final p = board[r][c];
          if (p != null) {
            currentBoardState[r][c] =
                '${p.color == PieceColor.white ? 'w' : 'b'}${p.type.toString().substring(p.type.toString().indexOf('.') + 1)[0]}';
          }
        }
      }

      // Update local board state
      if (movingPiece != null && movingPiece.type == PieceType.pawn) {
        final distance = (fromRow - toRow).abs();
        final justMovedTwoOrThree = distance == 2 || distance == 3;

        board[toRow][toCol] = ChessPiece.withHistory(
          color: movingPiece.color,
          type: movingPiece.type,
          enPassantUsedCount: movingPiece.enPassantUsedCount,
          justMovedThreeOrTwoSquares: justMovedTwoOrThree,
        );
      } else {
        board[toRow][toCol] = movingPiece;
      }
      board[fromRow][fromCol] = null;

      // Generate simple algebraic notation for the move
      String moveNotation =
          '${movingPiece!.symbol}${String.fromCharCode(fromCol + 97)}${boardSize - fromRow}';
      if (capturedPiece != null) {
        moveNotation += 'x';
      }
      moveNotation += '${String.fromCharCode(toCol + 97)}${boardSize - toRow}';

      // Emit boardUpdate to backend
      socket?.emit('boardUpdate', {
        'roomId': roomId,
        'boardData': {
          'newPosition': currentBoardState
        }, // Send the string representation
        'playerId': _currentUserDetail!.id,
        'move': moveNotation,
      });

      selectedPosition = null;
      possibleMoves = [];
      // Current player turn is managed by the backend via 'nextPlayerTurn' event
      _checkPawnPromotion(toRow, toCol);
    });
  }

  void _checkPawnPromotion(int row, int col) {
    final piece = board[row][col];
    if (piece?.type == PieceType.pawn && (row == 0 || row == boardSize - 1)) {
      board[row][col] = ChessPiece(piece!.color, PieceType.queen);
      gameStatus = 'Pawn promoted to Queen!';
    }
  }

  List<Position> _getPossibleMoves(int row, int col) {
    final piece = board[row][col];
    print('piece selected _getPossibleMoves ${row} ${col} ${piece?.color}');
    if (piece == null) return [];
    final moves = <Position>[];
    switch (piece.type) {
      case PieceType.pawn:
        _getPawnMoves(row, col, piece.color, moves);
        break;
      case PieceType.rook:
        _getRookMoves(row, col, piece.color, moves);
        break;
      case PieceType.knight:
        _getKnightMoves(row, col, piece.color, moves);
        break;
      case PieceType.bishop:
        _getBishopMoves(row, col, piece.color, moves);
        break;
      case PieceType.queen:
        _getQueenMoves(row, col, piece.color, moves);
        break;
      case PieceType.king:
        _getKingMoves(row, col, piece.color, moves);
        break;
      case PieceType.missile:
        _getMissileMoves(row, col, piece.color, moves);
        break;
    }
    return moves;
  }

  void _getMissileMoves(
      int row, int col, PieceColor color, List<Position> moves) {
    // Bishop-style diagonal sliding
    const bishopDirections = [
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1]
    ];
    _getSlidingMoves(row, col, color, bishopDirections, moves);

    // Knight-style L-shaped jumps
    const knightMoves = [
      [2, 1],
      [2, -1],
      [-2, 1],
      [-2, -1],
      [1, 2],
      [1, -2],
      [-1, 2],
      [-1, -2]
    ];
    for (final move in knightMoves) {
      final newRow = row + move[0];
      final newCol = col + move[1];
      if (_isValidPosition(newRow, newCol)) {
        final piece = board[newRow][newCol];
        if (piece == null || piece.color != color) {
          moves.add(Position(newRow, newCol));
        }
      }
    }
  }

  void _getPawnMoves(int row, int col, PieceColor color, List<Position> moves) {
    final direction = color == PieceColor.white ? -1 : 1;
    print("direction $direction");
    // Normal forward move
    final mm = _isValidPosition(row + direction, col);
    print("mm $mm");
    if (_isValidPosition(row + direction, col) &&
        board[row + direction][col] == null) {
      moves.add(Position(row + direction, col));

      // Double or triple move allowed?
      final bool isStartingWhite = row == boardSize - 2 || row == boardSize - 3;
      final bool isStartingBlack = row == 1 || row == 2;

      if ((color == PieceColor.white && isStartingWhite) ||
          (color == PieceColor.black && isStartingBlack)) {
        // 2-square move
        if (_isValidPosition(row + 2 * direction, col) &&
            board[row + 2 * direction][col] == null) {
          moves.add(Position(row + 2 * direction, col));
        }

        // 3-square move
        if (_isValidPosition(row + 3 * direction, col) &&
            board[row + 3 * direction][col] == null) {
          moves.add(Position(row + 3 * direction, col));
        }
      }
    }

    // Capture moves
    for (var colOffset in [-1, 1]) {
      final newCol = col + colOffset;
      if (newCol >= 0 &&
          newCol < boardSize &&
          _isValidPosition(row + direction, newCol)) {
        final target = board[row + direction][newCol];
        if (target != null && target.color != color) {
          moves.add(Position(row + direction, newCol));
        }
      }
    }

    // En Passant Logic
    for (var colOffset in [-1, 1]) {
      final adjCol = col + colOffset;
      if (adjCol >= 0 && adjCol < boardSize) {
        final enemyPawn = board[row][adjCol];
        if (enemyPawn is ChessPiece &&
            enemyPawn.type == PieceType.pawn &&
            enemyPawn.color != color) {
          // Check if enemy pawn just did 2 or 3-square move
          if (enemyPawn.justMovedThreeOrTwoSquares) {
            final enPassantRow = row + direction;
            final enPassantCol = adjCol;

            if (_isValidPosition(enPassantRow, enPassantCol) &&
                board[enPassantRow][enPassantCol] == null) {
              moves.add(Position(enPassantRow, enPassantCol));
            }
          }
        }
      }
    }
  }

  void _getRookMoves(int row, int col, PieceColor color, List<Position> moves) {
    const directions = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1]
    ];
    _getSlidingMoves(row, col, color, directions, moves);
  }

  void _getKnightMoves(
      int row, int col, PieceColor color, List<Position> moves) {
    const knightMoves = [
      [2, 1],
      [2, -1],
      [-2, 1],
      [-2, -1],
      [1, 2],
      [1, -2],
      [-1, 2],
      [-1, -2]
    ];
    for (final move in knightMoves) {
      final newRow = row + move[0];
      final newCol = col + move[1];
      if (_isValidPosition(newRow, newCol)) {
        final piece = board[newRow][newCol];
        if (piece == null || piece.color != color) {
          moves.add(Position(newRow, newCol));
        }
      }
    }
  }

  void _getBishopMoves(
      int row, int col, PieceColor color, List<Position> moves) {
    const directions = [
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1]
    ];
    _getSlidingMoves(row, col, color, directions, moves);
  }

  void _getQueenMoves(
      int row, int col, PieceColor color, List<Position> moves) {
    const directions = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1]
    ];
    _getSlidingMoves(row, col, color, directions, moves);
  }

  void _getKingMoves(int row, int col, PieceColor color, List<Position> moves) {
    for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (int colOffset = -1; colOffset <= 1; colOffset++) {
        if (rowOffset == 0 && colOffset == 0) continue;
        final newRow = row + rowOffset;
        final newCol = col + colOffset;
        if (_isValidPosition(newRow, newCol)) {
          final piece = board[newRow][newCol];
          if (piece == null || piece.color != color) {
            moves.add(Position(newRow, newCol));
          }
        }
      }
    }
  }

  void _getSlidingMoves(int row, int col, PieceColor color,
      List<List<int>> directions, List<Position> moves) {
    for (final direction in directions) {
      for (int i = 1; i < boardSize; i++) {
        final newRow = row + direction[0] * i;
        final newCol = col + direction[1] * i;
        if (!_isValidPosition(newRow, newCol)) break;
        final piece = board[newRow][newCol];
        if (piece == null) {
          moves.add(Position(newRow, newCol));
        } else {
          if (piece.color != color) {
            moves.add(Position(newRow, newCol));
          }
          break;
        }
      }
    }
  }

  bool _isValidPosition(int row, int col) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }

  void _resetGame() {
    setState(() {
      _initializeBoard();
      currentPlayer = PieceColor.white;
      selectedPosition = null;
      possibleMoves = [];
      gameStatus = 'White\'s turn';
      // Reset socket related states
      roomId = null;
      startGame = false;
      timer1 = '00:00';
      timer2 = '00:00';
      players = [];
      playerNextTurnColor = '';
      playerNextId = '';
      winData = null;
      drawMessage = null;
      drawStatus = false;
      threefoldMessage = null;
      threefoldStatus = false;
      rematchRequested = false;
      takebackRequested = false;
      moveList = [];
      chatMessages = [];
      isGameAborted = false;
      isRoomLeft = false;
      showLeaveConfirmation = false;
      showRematchConfirmation = false;
      showTakebackConfirmation = false;
      showDrawConfirmation = false;
      showThreefoldConfirmation = false;
      timerIs60 = false;
      newGameTriggered = false; // Allow new game to be triggered
      isPopupDisabled = false; // Show "Please wait" popup again
    });
    _connectSocket(); // Reconnect to join a new game
  }

  // --- Socket Event Emitters (mimicking React app's socket.emit calls) ---

  void handleLeaveRoom() {
    if (roomId != null && _currentUserDetail?.id != null) {
      socket?.emit(
          "leaveRoom", {"roomId": roomId, "playerId": _currentUserDetail!.id});
      setState(() {
        showLeaveConfirmation = false;
        isRoomLeft = true;
      });
    }
  }

  void abortGame() {
    if (roomId != null) {
      // The React app has a conditional for tournament specific abort with more params
      // For simplicity, this will send the basic abort
      socket?.emit("Abort", {"roomId": roomId});
      setState(() {
        isGameAborted = true;
      });
    }
  }

  void requestDraw() {
    if (roomId != null &&
        moveList.length > 1 &&
        !isGameAborted &&
        !isRoomLeft &&
        winData == null &&
        !drawStatus) {
      socket?.emit(
          "Draw", {"roomId": roomId, "playerId": _currentUserDetail!.id});
    } else {
      toastInfo("Cannot offer a draw at this time.");
    }
  }

  void HandleDraw() {
    if (roomId != null) {
      socket?.emit("DrawStatus", {"roomId": roomId, "DrawStatus": true});
      setState(() {
        showDrawConfirmation = false;
      });
    }
  }

  void CancelDraw() {
    if (roomId != null) {
      socket?.emit("DrawStatus", {"roomId": roomId, "DrawStatus": false});
      setState(() {
        showDrawConfirmation = false;
      });
    }
  }

  void Handlethreefold() {
    if (roomId != null && moveList.length > 1) {
      socket?.emit("threefoldCancel", {"roomId": roomId, "threefold": true});
      setState(() {
        showThreefoldConfirmation = false;
      });
    }
  }

  void HandleRematch() {
    if (roomId != null) {
      socket?.emit(
          "rematch", {"roomId": roomId, "playerId": _currentUserDetail!.id});
    }
  }

  void HandleRematchAccept() {
    if (roomId != null) {
      socket
          ?.emit("rematchStatus", {"roomId": roomId, "rematchResponse": true});
      setState(() {
        showRematchConfirmation = false;
      });
    }
  }

  void CancelRematch() {
    if (roomId != null) {
      socket
          ?.emit("rematchStatus", {"roomId": roomId, "rematchResponse": false});
      setState(() {
        showRematchConfirmation = false;
      });
    }
  }

  void HandleTackback() {
    if (roomId != null &&
        moveList.length > 1 &&
        !isGameAborted &&
        !isRoomLeft &&
        winData == null &&
        !drawStatus) {
      socket?.emit(
          "turnBack", {"roomId": roomId, "playerId": _currentUserDetail!.id});
      _audioPlayer.play(
          AssetSource('sound/notification.mp3')); // Play notification sound
    } else {
      toastInfo("Cannot request a takeback at this time.");
    }
  }

  void HandleTackbackAccept() {
    if (roomId != null) {
      socket?.emit("turnBackStatus", {
        "roomId": roomId,
        "playerId": _currentUserDetail!.id,
        "turnBack": true
      });
      setState(() {
        showTakebackConfirmation = false;
      });
    }
  }

  void CancelTackback() {
    if (roomId != null) {
      socket?.emit("turnBackStatus", {"roomId": roomId, "turnBack": false});
      setState(() {
        showTakebackConfirmation = false;
      });
    }
  }

  void handleSendMessage() {
    if (messageController.text.trim().isNotEmpty &&
        startGame &&
        !isMessageDisabled) {
      socket?.emit("send_message", {
        "roomId": roomId,
        "playerId": _currentUserDetail!.id,
        "message": messageController.text.trim(),
      });
      messageController.clear();
    }
  }

  void _playGameEndSound(bool? isWinner) {
    if (isWinner == true) {
      _audioPlayer.play(AssetSource('sound/win2.mp3'));
    } else if (isWinner == false) {
      _audioPlayer.play(AssetSource('sound/lose.mp3'));
    } else {
      // Draw
      _audioPlayer.play(AssetSource('sound/draw.mp3'));
    }
  }
}
