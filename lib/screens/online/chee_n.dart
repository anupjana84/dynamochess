import 'package:dynamochess/utils/api_list.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'position.dart';
import 'helper.dart';

import 'package:dynamochess/models/user_details.dart';

var logger = Logger();

void toastInfo(String message) {
  // Replace with your actual toast/snackbar implementation
  debugPrint("Toast: $message");
}

class ChessnewScreen extends StatefulWidget {
  final bool isBlackAtBottom;

  const ChessnewScreen({super.key, this.isBlackAtBottom = false});

  @override
  State<ChessnewScreen> createState() => _ChessnewScreenState();
}

class _ChessnewScreenState extends State<ChessnewScreen> {
  late List<List<String>> position;
  late bool isBlackAtBottom;
  late bool isWhiteTurn;
  int? selectedRow;
  int? selectedCol;
  List<String> moveHistory = [];
  List<List<List<String>>> boardHistory = [];

  //
  bool isMoveLocked = false; // Prevents consecutive moves by same player
  bool isTimerPaused = false; // Controls timer state
  String? lastMovePlayerId; // Track who made the last move
  DateTime? lastMoveTime;
  //

  // Socket and game state
  io.Socket? socket;
  String timer1 = '00:00';
  String timer2 = '00:00';
  bool isSound = true;
  bool isNavigation = true;
  bool gameAborted = false;
  bool leaveRoom = false;
  bool leave = false;
  List<Map<String, dynamic>> players = [];
  String playernextTurn = "";
  String? nextPlayerColor;
  var newBoardData = [];
  var movePosition = '';
  Position? selectedPosition;
  bool startGame = false;
  String playerNextTurnColor = '';
  String playerNextId = '';
  Map<String, dynamic>? winData;
  String? drawMessage;
  bool drawStatus = false;
  String? threefoldMessage;
  bool threefoldStatus = false;
  bool rematchRequested = false;
  bool takebackRequested = false;
  List<dynamic> moveList = [];
  String? gameStatus;
  String? pieceString;
  bool showboard = true;
  String? roomId;
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
  bool currentPlayerIsWhite = false;
  UserDetail? _currentUserDetail;
  String? playerId;
  List<List<bool>> validMoves =
      List.generate(10, (_) => List.filled(10, false));
  Position? whiteKingPosition;
  Position? blackKingPosition;
  bool isWhiteKingInCheck = false;
  bool isBlackKingInCheck = false;
  int currentMoveIndex = -1;
  bool isMyTurn = false;
  bool isConnected = false;
  bool isWaitingForOpponent = false;

  @override
  void initState() {
    super.initState();
    isBlackAtBottom = widget.isBlackAtBottom;
    position = createPosition(isBlackAtBottom: isBlackAtBottom);
    isWhiteTurn = true;
    updateKingPositions();
    checkForCheck();

    _initializeGame();
  }

  @override
  void dispose() {
    _disconnectSocket();
    super.dispose();
  }

  Future<void> _initializeGame() async {
    await _loadUserData();
    if (_currentUserDetail != null && _currentUserDetail!.id.isNotEmpty) {
      _connectSocket();
      setState(() {
        gameStatus = 'Connecting to server...';
      });
    } else {
      setState(() {
        gameStatus = 'Please log in to play';
      });
      toastInfo("User not logged in. Please log in to play online.");
    }
  }

  Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentUserDetail = UserDetail.fromSharedPreferences(prefs);
      });
    } catch (e) {
      logger.e('Error loading user data: $e');
    }
  }

  void _connectSocket() {
    if (socket?.connected == true) {
      logger.d('Socket already connected');
      return;
    }

    socket = io.io(ApiList.baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5,
      'timeout': 20000,
    });

    socket?.connect();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    socket?.onConnect((_) {
      logger.d('Connected to Socket.IO');
      setState(() {
        isConnected = true;
        gameStatus = 'Connected! Looking for game...';
      });

      if (_currentUserDetail != null && _currentUserDetail!.id.isNotEmpty) {
        _joinRoom();
      }
    });

    socket?.onDisconnect((_) {
      logger.d('Disconnected from Socket.IO');
      setState(() {
        isConnected = false;
        gameStatus = 'Disconnected from server';
      });
    });

    socket?.onConnectError((err) {
      logger.e('Connection Error: $err');
      setState(() {
        gameStatus = 'Connection failed: $err';
      });
    });

    socket?.onError((err) {
      logger.e('Socket Error: $err');
    });

    // Game-specific socket listeners
    socket?.on('roomJoined', _onRoomJoined);
    socket?.on('updatedRoom', _onUpdatedRoom);
    socket?.on('receive_boardData', _onReceiveBoardData);
    socket?.on('nextPlayerTurn', _onNextPlayerTurn);
    socket?.on('startGame', _onStartGame);
    socket?.on('playerWon', _onPlayerWon);
    socket?.on('checkMate', _onCheckMate);
    socket?.on('abort', _onGameAbort);
    socket?.on('roomLeftPlayerId', _onRoomLeft);
    socket?.on('DrawMessage', _onDrawMessage);
    socket?.on('DrawStatus', _onDrawStatus);
    socket?.on('ThreeFold', _onThreeFold);
    socket?.on('threefoldStatus', _onThreefoldStatus);
    socket?.on('rematch', _onRematch);
    socket?.on('rematchResponse', _onRematchResponse);
    socket?.on('turnBack', _onTurnBack);
    socket?.on('turnBackStatus', _onTurnBackStatus);
    socket?.on('timer1', _onTimer1);
    socket?.on('timer2', _onTimer2);
    socket?.on('moveList', _onMoveList);
    socket?.on('errorOccured', _onError);
  }

  void _onRoomJoined(dynamic data) {
    logger.d('Room joined: $data');
    setState(() {
      roomId = data['roomId'];
      gameStatus = 'Room joined: $roomId';
      isWaitingForOpponent = true;
    });
  }

  void _onUpdatedRoom(dynamic data) {
    logger.d('Room updated: $data');
    setState(() {
      nextPlayerColor = data['nextPlayerColor'];
      players = List<Map<String, dynamic>>.from(data['players'] ?? []);
      timer1 = _convertSecondsToMinutes(data['timer1'] ?? 0);
      timer2 = _convertSecondsToMinutes(data['timer2'] ?? 0);

      if (players.length >= 2) {
        startGame = true;
        isWaitingForOpponent = false;
        isPopupDisabled = true;
        gameStatus = 'Game starting...';

        // Determine player color and board orientation
        bool isCurrentUserBlack = players.any((p) =>
            p['playerId'] == _currentUserDetail?.id && p['colour'] == 'b');

        if (isCurrentUserBlack != isBlackAtBottom) {
          resetGame(blackAtBottom: isCurrentUserBlack);
        }

        _updateTurnStatus();
      }

      showboard = true;
    });
  }

  // void _onReceiveBoardData(dynamic data) {
  //   logger.d('Received board data: $data');
  //   if (data['data'] != null && data['data']['newPosition'] != null) {
  //     final List<dynamic> newPositionData = data['data']['newPosition'];
  //     final List<List<String>> convertedPosition =
  //         _convertBackendBoard(newPositionData);

  //     setState(() {
  //       if (newPositionData.isNotEmpty) {
  //         bool isCurrentUserBlack = players.isNotEmpty &&
  //             players.any((p) =>
  //                 p['playerId'] == _currentUserDetail?.id &&
  //                 p['colour'] == 'w');
  //         logger.d('isCurrentUserBlack: $isCurrentUserBlack');
  //       }
  //       position = convertedPosition;
  //       selectedRow = null;
  //       selectedCol = null;
  //       resetValidMoves();
  //       updateKingPositions();
  //       checkForCheck();

  //       // Update turn based on the move
  //       isWhiteTurn = true;
  //       _updateTurnStatus();
  //     });
  //   }
  // }
  void _onReceiveBoardData(dynamic data) {
    logger.d('Received board data: $data');

    if (data['data'] != null && data['data']['newPosition'] != null) {
      final List<dynamic> newPositionData = data['data']['newPosition'];
      final List<List<String>> convertedPosition =
          _convertBackendBoard(newPositionData);

      setState(() {
        position = convertedPosition;
        selectedRow = null;
        selectedCol = null;
        resetValidMoves();
        updateKingPositions();
        checkForCheck();

        // Unlock moves for the receiving player (opponent of the one who just moved)
        isMoveLocked = false;
        isTimerPaused = false;

        // Update turn based on the move
        isWhiteTurn = !isWhiteTurn; // Toggle turn
        _updateTurnStatus();
      });
    }
  }

  // void _onNextPlayerTurn(dynamic data) {
  //   logger.d('Next player turn: $data');
  //   setState(() {
  //     playerNextTurnColor = data['playerColour'] ?? '';
  //     playerNextId = data['playerId'] ?? '';
  //     // _updateTurnStatus();
  //   });
  // }

  void _onNextPlayerTurn(dynamic data) {
    logger.d('Next player turn: $data');

    setState(() {
      playerNextTurnColor = data['playerColour'] ?? '';
      playerNextId = data['playerId'] ?? '';

      // Unlock moves when it becomes player's turn
      if (playerNextId == _currentUserDetail?.id) {
        isMoveLocked = false;
        isTimerPaused = false;
      } else {
        isMoveLocked = true;
        isTimerPaused = true;
      }

      _updateTurnStatus();
    });
  }

  void _onStartGame(dynamic data) {
    logger.d('Game started: $data');
    setState(() {
      startGame = data['start'] ?? false;
      isPopupDisabled = true;
      gameStatus = 'Game started!';
      _updateTurnStatus();
    });
  }

  void _onPlayerWon(dynamic data) {
    logger.d('Player won: $data');
    setState(() {
      winData = data;
      gameStatus =
          data['playerId'] == _currentUserDetail?.id ? 'You Win!' : 'You Lose!';
      isMyTurn = false;
    });
  }

  void _onCheckMate(dynamic data) {
    logger.d('Checkmate: $data');
    setState(() {
      gameStatus = 'Checkmate!';
      isMyTurn = false;
    });
  }

  void _onGameAbort(dynamic data) {
    logger.d('Game aborted: $data');
    setState(() {
      isGameAborted = true;
      gameStatus = 'Game Aborted!';
      isMyTurn = false;
    });
  }

  void _onRoomLeft(dynamic data) {
    logger.d('Room left: $data');
    setState(() {
      isRoomLeft = true;
      gameStatus = 'Opponent Left!';
      isMyTurn = false;
    });
  }

  void _onDrawMessage(dynamic data) {
    logger.d('Draw message: $data');
    setState(() {
      drawMessage = data['message'];
      showDrawConfirmation = true;
    });
  }

  void _onDrawStatus(dynamic data) {
    logger.d('Draw status: $data');
    setState(() {
      drawStatus = data['DrawStatus'] ?? false;
      if (drawStatus) {
        gameStatus = 'Game Drawn!';
        isMyTurn = false;
      }
      showDrawConfirmation = false;
    });
  }

  void _onThreeFold(dynamic data) {
    logger.d('Threefold: $data');
    setState(() {
      threefoldMessage = data['message'];
      showThreefoldConfirmation = true;
    });
  }

  void _onThreefoldStatus(dynamic data) {
    logger.d('Threefold status: $data');
    setState(() {
      threefoldStatus = data['threefoldStatus'] ?? false;
      if (threefoldStatus) {
        gameStatus = 'Game Drawn by Threefold Repetition!';
        isMyTurn = false;
      }
      showThreefoldConfirmation = false;
    });
  }

  void _onRematch(dynamic data) {
    logger.d('Rematch: $data');
    setState(() {
      rematchRequested = true;
      showRematchConfirmation = true;
    });
  }

  void _onRematchResponse(dynamic data) {
    logger.d('Rematch response: $data');
    setState(() {
      rematchRequested = false;
      showRematchConfirmation = false;
      if (data != false) {
        newGameTriggered = true;
        _resetGameState();
      }
    });
  }

  void _onTurnBack(dynamic data) {
    logger.d('Turn back: $data');
    setState(() {
      takebackRequested = true;
      showTakebackConfirmation = true;
    });
  }

  void _onTurnBackStatus(dynamic data) {
    logger.d('Turn back status: $data');
    setState(() {
      takebackRequested = false;
      showTakebackConfirmation = false;
      if (data['turnBackStatus'] == true) {
        // Handle successful takeback
        toastInfo('Takeback accepted!');
      }
    });
  }

  void _onTimer1(dynamic data) {
    setState(() {
      timer1 = data?.toString() ?? '00:00';
    });
  }

  void _onTimer2(dynamic data) {
    setState(() {
      timer2 = data?.toString() ?? '00:00';
    });
  }

  void _onMoveList(dynamic data) {
    logger.d('Move list: $data');
    setState(() {
      moveList = data ?? [];
    });
  }

  void _onError(dynamic data) {
    logger.e('Socket error: $data');
    toastInfo('Error: $data');
  }

  // void _updateTurnStatus() {
  //   if (players.isEmpty || _currentUserDetail == null) return;

  //   final currentPlayer = players.firstWhere(
  //     (p) => p['playerId'] == _currentUserDetail!.id,
  //     orElse: () => <String, dynamic>{},
  //   );

  //   if (currentPlayer.isNotEmpty) {
  //     final myColor = currentPlayer['colour'] as String?;
  //     final currentTurnColor = playerNextTurnColor.isNotEmpty
  //         ? playerNextTurnColor
  //         : (isWhiteTurn ? 'w' : 'b');

  //     setState(() {
  //       isMyTurn = myColor == currentTurnColor;
  //       gameStatus = isMyTurn ? 'Your turn' : 'Opponent\'s turn';
  //     });
  //   }
  // }
  void _updateTurnStatus() {
    if (players.isEmpty || _currentUserDetail == null) return;

    final currentPlayer = players.firstWhere(
      (p) => p['playerId'] == _currentUserDetail!.id,
      orElse: () => <String, dynamic>{},
    );

    if (currentPlayer.isNotEmpty) {
      final myColor = currentPlayer['colour'] as String?;
      final currentTurnColor = playerNextTurnColor.isNotEmpty
          ? playerNextTurnColor
          : (isWhiteTurn ? 'w' : 'b');

      setState(() {
        bool newIsMyTurn = myColor == currentTurnColor;

        // Only allow moves if it's actually my turn and moves aren't locked
        isMyTurn = newIsMyTurn && !isMoveLocked;

        if (newIsMyTurn && !isMoveLocked) {
          gameStatus = 'Your turn - Make your move!';
          isTimerPaused = false; // Resume timer for active player
        } else if (newIsMyTurn && isMoveLocked) {
          gameStatus = 'Please wait...';
        } else {
          gameStatus = 'Opponent\'s turn';
          isTimerPaused = true; // Pause timer for inactive player
        }
      });
    }
  }

  // void _resetGameState() {
  //   setState(() {
  //     position = createPosition(isBlackAtBottom: isBlackAtBottom);
  //     selectedRow = null;
  //     selectedCol = null;
  //     resetValidMoves();
  //     isWhiteTurn = true;
  //     moveHistory.clear();
  //     boardHistory.clear();
  //     currentMoveIndex = -1;
  //     updateKingPositions();
  //     checkForCheck();
  //     _updateTurnStatus();
  //   });
  // }
  void _handleMoveTimeout() {
    // Call this method if a move hasn't been acknowledged within reasonable time
    if (isMoveLocked &&
        lastMoveTime != null &&
        DateTime.now().difference(lastMoveTime!).inSeconds > 30) {
      setState(() {
        isMoveLocked = false; // Unlock moves after timeout
        gameStatus = 'Connection issue - moves unlocked';
      });
      toastInfo('Move timeout - unlocking moves');
    }
  }

  List<List<String>> _convertBackendBoard(List<dynamic> boardData) {
    if (boardData.isEmpty) return position;

    int size = boardData.length;
    List<List<String>> convertedBoard =
        List.generate(size, (_) => List.filled(size, ''));

    for (int i = 0; i < size; i++) {
      if (boardData[i] is List) {
        List row = boardData[i];
        for (int j = 0; j < row.length && j < size; j++) {
          convertedBoard[i][j] = row[j]?.toString() ?? '';
        }
      }
    }

    return convertedBoard;
  }

  String _convertSecondsToMinutes(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _joinRoom() {
    if (_currentUserDetail == null || _currentUserDetail!.id.isEmpty) {
      toastInfo("User data not loaded. Cannot join room.");
      return;
    }

    if (_currentUserDetail!.dynamoCoin < 200) {
      toastInfo("Minimum 200 coins required to play");
      return;
    }

    final String currentUrl = Uri.base.toString();
    final bool isTournament = currentUrl.contains("tournament:");
    final String? uniqueID =
        isTournament ? currentUrl.split("tournament:")[1].split('/')[0] : null;
    final String currentRoomId = uniqueID ?? 'randomMultiplayer';
    const String currentTime = '600';

    final Map<String, dynamic> joinRoomData = {
      "playerId": _currentUserDetail!.id,
      "name": _currentUserDetail!.name,
      "coin": 200,
      "profileImageUrl": "null",
      "playerStatus": "Good",
      "joinId": currentRoomId,
      "timer": currentTime,
      "countryicon": _currentUserDetail!.countryIcon,
      "colour": null, // Let backend assign
    };

    try {
      if (isTournament) {
        socket?.emit('joinRoomViaTournament', joinRoomData);
      } else if (currentRoomId == "randomMultiplayer") {
        socket?.emit('joinRoom', joinRoomData);
      } else {
        socket?.emit('joinById', joinRoomData);
      }

      setState(() {
        isWaitingForOpponent = true;
        gameStatus = 'Joining room...';
      });
    } catch (e) {
      logger.e('Error joining room: $e');
      toastInfo('Failed to join room');
    }
  }

  void _disconnectSocket() {
    if (socket?.connected == true) {
      if (roomId != null && _currentUserDetail != null) {
        socket?.emit('leaveRoom', {
          "roomId": roomId,
          "playerId": _currentUserDetail!.id,
        });
      }
      socket?.disconnect();
    }
    socket?.dispose();
  }

  void resetValidMoves() {
    validMoves = List.generate(10, (_) => List.filled(10, false));
  }

  void updateKingPositions() {
    whiteKingPosition = null;
    blackKingPosition = null;

    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 10; col++) {
        if (position[row][col] == 'wk') {
          whiteKingPosition = Position(row, col);
        } else if (position[row][col] == 'bk') {
          blackKingPosition = Position(row, col);
        }
      }
    }
  }

  bool isSquareUnderAttack(int row, int col, bool byWhite) {
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        String piece = position[r][c];
        if (piece.isEmpty) continue;

        bool isPieceWhite = piece.startsWith('w');
        if (isPieceWhite != byWhite) continue;

        List<List<bool>> tempValidMoves =
            List.generate(10, (_) => List.filled(10, false));

        switch (piece[1]) {
          case 'p':
            _calculatePawnAttacks(r, c, isPieceWhite, tempValidMoves);
            break;
          case 'r':
            _calculateStraightAttacks(r, c, isPieceWhite, tempValidMoves);
            break;
          case 'n':
            _calculateKnightAttacks(r, c, isPieceWhite, tempValidMoves);
            break;
          case 'b':
            _calculateDiagonalAttacks(r, c, isPieceWhite, tempValidMoves);
            break;
          case 'q':
            _calculateStraightAttacks(r, c, isPieceWhite, tempValidMoves);
            _calculateDiagonalAttacks(r, c, isPieceWhite, tempValidMoves);
            break;
          case 'k':
            _calculateKingAttacks(r, c, isPieceWhite, tempValidMoves);
            break;
          case 'm':
            _calculateDiagonalAttacks(r, c, isPieceWhite, tempValidMoves);
            _calculateKnightAttacks(r, c, isPieceWhite, tempValidMoves);
            break;
        }

        if (tempValidMoves[row][col]) {
          return true;
        }
      }
    }
    return false;
  }

  void checkForCheck() {
    updateKingPositions();

    if (whiteKingPosition != null) {
      isWhiteKingInCheck = isSquareUnderAttack(
        whiteKingPosition!.row,
        whiteKingPosition!.col,
        false,
      );
    }

    if (blackKingPosition != null) {
      isBlackKingInCheck = isSquareUnderAttack(
        blackKingPosition!.row,
        blackKingPosition!.col,
        true,
      );
    }
  }

  void _calculatePawnAttacks(
      int row, int col, bool isWhite, List<List<bool>> attacks) {
    int direction = isBlackAtBottom ? (isWhite ? -1 : 1) : (isWhite ? 1 : -1);

    for (int i = -1; i <= 1; i += 2) {
      if (col + i >= 0 &&
          col + i < 10 &&
          row + direction >= 0 &&
          row + direction < 10) {
        attacks[row + direction][col + i] = true;
      }
    }
  }

  void _calculateStraightAttacks(
      int row, int col, bool isWhite, List<List<bool>> attacks) {
    for (int dCol in [-1, 1]) {
      for (int c = col + dCol; c >= 0 && c < 10; c += dCol) {
        attacks[row][c] = true;
        if (position[row][c].isNotEmpty) break;
      }
    }

    for (int dRow in [-1, 1]) {
      for (int r = row + dRow; r >= 0 && r < 10; r += dRow) {
        attacks[r][col] = true;
        if (position[r][col].isNotEmpty) break;
      }
    }
  }

  void _calculateDiagonalAttacks(
      int row, int col, bool isWhite, List<List<bool>> attacks) {
    List<List<int>> directions = [
      [-1, -1],
      [-1, 1],
      [1, -1],
      [1, 1]
    ];

    for (var dir in directions) {
      int dRow = dir[0], dCol = dir[1];
      for (int i = 1; i < 10; i++) {
        int r = row + i * dRow;
        int c = col + i * dCol;

        if (r >= 0 && r < 10 && c >= 0 && c < 10) {
          attacks[r][c] = true;
          if (position[r][c].isNotEmpty) break;
        } else {
          break;
        }
      }
    }
  }

  void _calculateKnightAttacks(
      int row, int col, bool isWhite, List<List<bool>> attacks) {
    List<List<int>> moves = [
      [row - 2, col - 1],
      [row - 2, col + 1],
      [row - 1, col - 2],
      [row - 1, col + 2],
      [row + 1, col - 2],
      [row + 1, col + 2],
      [row + 2, col - 1],
      [row + 2, col + 1],
    ];

    for (var move in moves) {
      int r = move[0], c = move[1];
      if (r >= 0 && r < 10 && c >= 0 && c < 10) {
        attacks[r][c] = true;
      }
    }
  }

  void _calculateKingAttacks(
      int row, int col, bool isWhite, List<List<bool>> attacks) {
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int r = row + i, c = col + j;
        if (r >= 0 && r < 10 && c >= 0 && c < 10) {
          attacks[r][c] = true;
        }
      }
    }
  }

  void calculateValidMoves(int row, int col) {
    resetValidMoves();
    String piece = position[row][col];
    if (piece.isEmpty) return;

    bool isWhite = piece.startsWith('w');

    switch (piece[1]) {
      case 'p':
        calculatePawnMoves(row, col, isWhite);
        break;
      case 'r':
        calculateStraightMoves(row, col, isWhite);
        break;
      case 'n':
        calculateKnightMoves(row, col, isWhite);
        break;
      case 'b':
        calculateDiagonalMoves(row, col, isWhite);
        break;
      case 'q':
        calculateStraightMoves(row, col, isWhite);
        calculateDiagonalMoves(row, col, isWhite);
        break;
      case 'k':
        calculateKingMoves(row, col, isWhite);
        break;
      case 'm':
        calculateDiagonalMoves(row, col, isWhite);
        calculateKnightMoves(row, col, isWhite);
        break;
    }
  }

  void calculatePawnMoves(int row, int col, bool isWhite) {
    // Pawn movement: pawns always move toward the enemy
    // In our coordinate system (0,0) is bottom-left, (9,9) is top-right
    int direction;
    int startRow;

    if (isBlackAtBottom) {
      // Black at bottom: black pawns move up (+1), white pawns move down (-1)
      direction = isWhite ? -1 : 1;
      startRow = isWhite ? 8 : 1;
    } else {
      // White at bottom: white pawns move up (+1), black pawns move down (-1)
      direction = isWhite ? 1 : -1;
      startRow = isWhite ? 1 : 8;
    }

    // Move forward
    if (row + direction >= 0 && row + direction < 10) {
      if (position[row + direction][col].isEmpty) {
        validMoves[row + direction][col] = true;

        // Double move from starting position
        if (row == startRow &&
            row + 2 * direction >= 0 &&
            row + 2 * direction < 10) {
          if (position[row + 2 * direction][col].isEmpty) {
            validMoves[row + 2 * direction][col] = true;

            // Triple move (special 10x10 rule)
            if (row + 3 * direction >= 0 && row + 3 * direction < 10) {
              if (position[row + 3 * direction][col].isEmpty) {
                validMoves[row + 3 * direction][col] = true;
              }
            }
          }
        }
      }
    }

    // Capture diagonally
    for (int i = -1; i <= 1; i += 2) {
      if (col + i >= 0 &&
          col + i < 10 &&
          row + direction >= 0 &&
          row + direction < 10) {
        String target = position[row + direction][col + i];
        if (target.isNotEmpty && target[0] != (isWhite ? 'w' : 'b')) {
          validMoves[row + direction][col + i] = true;
        }
      }
    }
  }

  void calculateStraightMoves(int row, int col, bool isWhite) {
    // Horizontal moves
    for (int dCol in [-1, 1]) {
      for (int c = col + dCol; c >= 0 && c < 10; c += dCol) {
        String target = position[row][c];
        if (target.isEmpty) {
          validMoves[row][c] = true;
        } else {
          if (target[0] != (isWhite ? 'w' : 'b')) {
            validMoves[row][c] = true;
          }
          break;
        }
      }
    }

    // Vertical moves
    for (int dRow in [-1, 1]) {
      for (int r = row + dRow; r >= 0 && r < 10; r += dRow) {
        String target = position[r][col];
        if (target.isEmpty) {
          validMoves[r][col] = true;
        } else {
          if (target[0] != (isWhite ? 'w' : 'b')) {
            validMoves[r][col] = true;
          }
          break;
        }
      }
    }
  }

  void calculateDiagonalMoves(int row, int col, bool isWhite) {
    List<List<int>> directions = [
      [-1, -1],
      [-1, 1],
      [1, -1],
      [1, 1]
    ];

    for (var dir in directions) {
      int dRow = dir[0], dCol = dir[1];
      for (int i = 1; i < 10; i++) {
        int r = row + i * dRow;
        int c = col + i * dCol;

        if (r >= 0 && r < 10 && c >= 0 && c < 10) {
          String target = position[r][c];
          if (target.isEmpty) {
            validMoves[r][c] = true;
          } else {
            if (target[0] != (isWhite ? 'w' : 'b')) {
              validMoves[r][c] = true;
            }
            break;
          }
        } else {
          break;
        }
      }
    }
  }

  void calculateKnightMoves(int row, int col, bool isWhite) {
    List<List<int>> moves = [
      [row - 2, col - 1],
      [row - 2, col + 1],
      [row - 1, col - 2],
      [row - 1, col + 2],
      [row + 1, col - 2],
      [row + 1, col + 2],
      [row + 2, col - 1],
      [row + 2, col + 1],
    ];

    for (var move in moves) {
      int r = move[0], c = move[1];
      if (r >= 0 && r < 10 && c >= 0 && c < 10) {
        String target = position[r][c];
        if (target.isEmpty || target[0] != (isWhite ? 'w' : 'b')) {
          validMoves[r][c] = true;
        }
      }
    }
  }

  void calculateKingMoves(int row, int col, bool isWhite) {
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int r = row + i, c = col + j;
        if (r >= 0 && r < 10 && c >= 0 && c < 10) {
          String target = position[r][c];
          if (target.isEmpty || target[0] != (isWhite ? 'w' : 'b')) {
            validMoves[r][c] = true;
          }
        }
      }
    }
  }

  String generateMoveNotation(
      int fromRow, int fromCol, int toRow, int toCol, piece,
      {bool isCapture = false, required bool isBlackAtBottom}) {
    // Add this parameter

    String pp = '';
    if (pieceString != null && pieceString!.isNotEmpty) {
      final lastChar = pieceString!.characters.last;
      pp = lastChar.toUpperCase();
    }

    String from =
        Position(fromRow, fromCol, isBlackAtBottom: isBlackAtBottom).algebraic;
    String to =
        Position(toRow, toCol, isBlackAtBottom: isBlackAtBottom).algebraic;
    print("pp ${pp} $from $to");
    if (isCapture) {
      if (pp == 'P') {
        return '${from[0]}x$to';
      }
      return '$pp${from[0]}x$to';
    } else {
      if (pp == 'P') {
        return '$to';
      }

      return "${pp}$to";
    }
  }

  // void movePiece(int fromRow, int fromCol, int toRow, int toCol) {
  //   // Create a deep copy of the current position
  //   bool isCapture = position[toRow][toCol].isNotEmpty;

  //   List<List<String>> newPosition =
  //       position.map((row) => List<String>.from(row)).toList();

  //   // Make the move on the copy
  //   String piece = newPosition[fromRow][fromCol];
  //   String capturedPiece = newPosition[toRow][toCol];
  //   newPosition[toRow][toCol] = piece;
  //   newPosition[fromRow][fromCol] = '';

  //   // Create move notation
  //   Position fromPos =
  //       Position(fromRow, fromCol, isBlackAtBottom: isBlackAtBottom);
  //   Position toPos = Position(toRow, toCol, isBlackAtBottom: isBlackAtBottom);
  //   String moveNotation = '${fromPos.algebraic}-${toPos.algebraic}';
  //   if (capturedPiece.isNotEmpty) {
  //     moveNotation += ' (captured ${capturedPiece.toUpperCase()})';
  //   }
  //   final dddddd = generateMoveNotation(
  //       fromRow,
  //       fromCol,
  //       toRow,
  //       toCol,
  //       isCapture: isCapture,
  //       isBlackAtBottom: isBlackAtBottom,
  //       piece);
  //   logger.d("Move notation: $dddddd ");
  //   if (socket != null && roomId != null && _currentUserDetail != null) {
  //     final ddddd = newPosition;
  //     socket?.emit('boardUpdate', {
  //       'roomId': roomId,
  //       'boardData': {"newPosition": ddddd},
  //       'playerId': _currentUserDetail!.id,
  //       'move': dddddd,
  //     });
  //   }
  //   setState(() {
  //     position = newPosition;
  //     selectedRow = null;
  //     selectedCol = null;
  //     resetValidMoves();
  //     isWhiteTurn = false;
  //     moveHistory.add(moveNotation);
  //     boardHistory.add(newPosition); // Store the new position
  //     currentMoveIndex = -1; // Viewing latest position

  //     checkForCheck();
  //   });
  // }
  void movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    // Prevent move if locked or not player's turn
    if (isMoveLocked || !isMyTurn) {
      toastInfo("Please wait for your turn");
      return;
    }

    // Lock moves immediately after making a move
    setState(() {
      isMoveLocked = true;
      isTimerPaused = true; // Pause timer until opponent moves
      lastMoveTime = DateTime.now();
      lastMovePlayerId = _currentUserDetail?.id;
    });

    // Create a deep copy of the current position
    bool isCapture = position[toRow][toCol].isNotEmpty;
    List<List<String>> newPosition =
        position.map((row) => List<String>.from(row)).toList();

    // Make the move on the copy
    String piece = newPosition[fromRow][fromCol];
    String capturedPiece = newPosition[toRow][toCol];
    newPosition[toRow][toCol] = piece;
    newPosition[fromRow][fromCol] = '';

    // Create move notation
    Position fromPos =
        Position(fromRow, fromCol, isBlackAtBottom: isBlackAtBottom);
    Position toPos = Position(toRow, toCol, isBlackAtBottom: isBlackAtBottom);
    String moveNotation = '${fromPos.algebraic}-${toPos.algebraic}';
    if (capturedPiece.isNotEmpty) {
      moveNotation += ' (captured ${capturedPiece.toUpperCase()})';
    }

    final moveString = generateMoveNotation(
        fromRow,
        fromCol,
        toRow,
        toCol,
        isCapture: isCapture,
        isBlackAtBottom: isBlackAtBottom,
        piece);

    logger.d("Move notation: $moveString");

    // Send move to server
    if (socket != null && roomId != null && _currentUserDetail != null) {
      socket?.emit('boardUpdate', {
        'roomId': roomId,
        'boardData': {"newPosition": newPosition},
        'playerId': _currentUserDetail!.id,
        'move': moveString,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    setState(() {
      position = newPosition;
      selectedRow = null;
      selectedCol = null;
      resetValidMoves();
      isWhiteTurn = !isWhiteTurn; // Toggle turn
      moveHistory.add(moveNotation);
      boardHistory.add(newPosition);
      currentMoveIndex = -1;

      // Update turn status - now it's opponent's turn
      isMyTurn = false;
      gameStatus = 'Waiting for opponent...';

      checkForCheck();
    });
  }

  void viewMove(int index) {
    setState(() {
      currentMoveIndex = index;
      position =
          boardHistory[index].map((row) => List<String>.from(row)).toList();

      // Update turn based on move index (even = white's turn next)
      isWhiteTurn = (index % 2 == 0);

      // Reset selection
      selectedRow = null;
      selectedCol = null;
      resetValidMoves();

      // Update king positions and check status
      updateKingPositions();
      checkForCheck();
    });
  }

  void returnToCurrentPosition() {
    if (currentMoveIndex == -1) return;

    setState(() {
      currentMoveIndex = -1;
      position =
          boardHistory.last.map((row) => List<String>.from(row)).toList();
      isWhiteTurn = (moveHistory.length % 2 == 0);

      // Reset selection
      selectedRow = null;
      selectedCol = null;
      resetValidMoves();

      updateKingPositions();
      checkForCheck();
    });
  }

  void resetGame({bool? blackAtBottom}) {
    setState(() {
      if (blackAtBottom != null) {
        isBlackAtBottom = blackAtBottom;
      }
      position = createPosition(isBlackAtBottom: isBlackAtBottom);
      selectedRow = null;
      selectedCol = null;
      resetValidMoves();
      isWhiteTurn = true;
      moveHistory.clear();

      // Reset check status
      updateKingPositions();
      checkForCheck();
    });
  }

  void _resetGameState() {
    setState(() {
      position = createPosition(isBlackAtBottom: isBlackAtBottom);
      selectedRow = null;
      selectedCol = null;
      resetValidMoves();
      isWhiteTurn = true;
      moveHistory.clear();
      boardHistory.clear();
      currentMoveIndex = -1;

      // Reset turn management state
      isMoveLocked = false;
      isTimerPaused = false;
      lastMovePlayerId = null;
      lastMoveTime = null;

      updateKingPositions();
      checkForCheck();
      _updateTurnStatus();
    });
  }

  Widget _buildPieceWidget(String piece, int row, int col) {
    if (piece.isEmpty) return const SizedBox();

    return Stack(alignment: Alignment.center, children: [
      Image.asset(
        pieceImages[piece]!,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to text symbols if image fails to load
          return Text(
            pieceSymbols[piece] ?? piece,
            style: const TextStyle(fontSize: 24),
          );
        },
      ),
      // Show coordinate for debugging
      Positioned(
        top: 2,
        left: 2,
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            "$row,$col",
            style: const TextStyle(fontSize: 8, color: Colors.black),
          ),
        ),
      ),
    ]);
  }

  // Widget _buildBoard() {
  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       final boardDimension = constraints.maxWidth < constraints.maxHeight
  //           ? constraints.maxWidth
  //           : constraints.maxHeight;
  //       final safeBoardDimension = boardDimension <= 0 ? 300.0 : boardDimension;

  //       return Center(
  //         child: SizedBox(
  //           width: safeBoardDimension,
  //           height: safeBoardDimension,
  //           child: GridView.builder(
  //             physics: const NeverScrollableScrollPhysics(),
  //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //               crossAxisCount: 10,
  //             ),
  //             itemCount: 100,
  //             itemBuilder: (context, index) {
  //               // Convert GridView index to board coordinates
  //               // GridView displays from top-left to bottom-right
  //               int gridRow = index ~/ 10; // 0-9 from top to bottom
  //               int gridCol = index % 10; // 0-9 from left to right

  //               // Convert to internal position coordinates
  //               // Internal array: (0,0) is always bottom-left conceptually
  //               int row =
  //                   9 - gridRow; // Flip vertically so (0,0) is bottom-left
  //               int col = gridCol; // Keep horizontal as is

  //               String piece = position[row][col];
  //               bool isSelected = selectedRow == row && selectedCol == col;
  //               bool isValidMove = validMoves[row][col];

  //               // Checkerboard pattern based on grid position
  //               Color tileColor = ((gridRow + gridCol) % 2 == 0)
  //                   ? const Color(0xFFDCDA5C)
  //                   : const Color(0xFF769656);

  //               // Check if this square contains a king in danger
  //               bool isKingInDanger = false;
  //               if (piece == 'wk' && isWhiteKingInCheck) {
  //                 isKingInDanger = true;
  //               } else if (piece == 'bk' && isBlackKingInCheck) {
  //                 isKingInDanger = true;
  //               }

  //               if (isKingInDanger) {
  //                 tileColor = Colors.red.withOpacity(0.8);
  //               } else if (isSelected) {
  //                 tileColor = Colors.yellowAccent;
  //               } else if (isValidMove) {
  //                 tileColor = Colors.lightGreenAccent;
  //               }

  //               return GestureDetector(
  //                 onTap: () {
  //                   if (_currentUserDetail!.id == playerNextId) {
  //                     if (selectedRow != null &&
  //                         selectedCol != null &&
  //                         isValidMove) {
  //                       // Make the move
  //                       movePiece(selectedRow!, selectedCol!, row, col);
  //                     } else if (piece.isNotEmpty) {
  //                       // Check if it's the correct player's turn
  //                       bool isPieceWhite = piece.startsWith('w');
  //                       if (isPieceWhite == isWhiteTurn) {
  //                         setState(() {
  //                           selectedRow = row;
  //                           selectedCol = col;
  //                           calculateValidMoves(row, col);
  //                         });
  //                       } else {
  //                         // Show message for wrong turn
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(
  //                             content: Text(
  //                                 'It\'s ${isWhiteTurn ? 'White' : 'Black'}\'s turn!'),
  //                             duration: const Duration(seconds: 1),
  //                           ),
  //                         );
  //                       }
  //                     } else {
  //                       // Deselect
  //                       setState(() {
  //                         selectedRow = null;
  //                         selectedCol = null;
  //                         resetValidMoves();
  //                       });
  //                     }
  //                   }
  //                 },
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                     color: tileColor,
  //                     border: Border.all(color: Colors.black, width: 0.5),
  //                   ),
  //                   child: Stack(
  //                     children: [
  //                       if (piece.isNotEmpty)
  //                         Center(child: _buildPieceWidget(piece, row, col)),
  //                       if (isValidMove && piece.isEmpty)
  //                         Center(
  //                           child: Container(
  //                             width: 20,
  //                             height: 20,
  //                             decoration: const BoxDecoration(
  //                               color: Colors.green,
  //                               shape: BoxShape.circle,
  //                             ),
  //                           ),
  //                         ),
  //                       // Show algebraic notation in corner
  //                       Positioned(
  //                         bottom: 2,
  //                         right: 2,
  //                         child: Container(
  //                           padding: const EdgeInsets.all(1),
  //                           decoration: BoxDecoration(
  //                             color: Colors.black.withOpacity(0.3),
  //                             borderRadius: BorderRadius.circular(2),
  //                           ),
  //                           child: Text(
  //                             Position(row, col).algebraic,
  //                             style: const TextStyle(
  //                                 fontSize: 8, color: Colors.white),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardDimension = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final safeBoardDimension = boardDimension <= 0 ? 300.0 : boardDimension;

        return Center(
          child: SizedBox(
            width: safeBoardDimension,
            height: safeBoardDimension,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
              ),
              itemCount: 100,
              itemBuilder: (context, index) {
                // Convert GridView index to board coordinates
                int gridRow = index ~/ 10;
                int gridCol = index % 10;
                int row = 9 - gridRow;
                int col = gridCol;

                String piece = position[row][col];
                bool isSelected = selectedRow == row && selectedCol == col;
                bool isValidMove = validMoves[row][col];

                // Checkerboard pattern
                Color tileColor = ((gridRow + gridCol) % 2 == 0)
                    ? const Color(0xFFDCDA5C)
                    : const Color(0xFF769656);

                // Check if this square contains a king in danger
                bool isKingInDanger = false;
                if (piece == 'wk' && isWhiteKingInCheck) {
                  isKingInDanger = true;
                } else if (piece == 'bk' && isBlackKingInCheck) {
                  isKingInDanger = true;
                }

                if (isKingInDanger) {
                  tileColor = Colors.red.withOpacity(0.8);
                } else if (isSelected) {
                  tileColor = Colors.yellowAccent;
                } else if (isValidMove) {
                  tileColor = Colors.lightGreenAccent;
                }

                return GestureDetector(
                  onTap: () {
                    // Enhanced tap logic with turn locking
                    // if (!isMyTurn) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text('Wait for your turn!'),
                    //       duration: Duration(seconds: 1),
                    //     ),
                    //   );
                    //   return;
                    // }

                    // if (isMoveLocked) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text('Please wait for opponent\'s response'),
                    //       duration: Duration(seconds: 1),
                    //     ),
                    //   );
                    //   return;
                    // }

                    // Check if it's the correct player based on server state
                    if (_currentUserDetail?.id != playerNextId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('It\'s not your turn according to server!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }

                    if (selectedRow != null &&
                        selectedCol != null &&
                        isValidMove) {
                      // Make the move
                      movePiece(selectedRow!, selectedCol!, row, col);
                    } else if (piece.isNotEmpty) {
                      // Check if it's the correct player's piece
                      bool isPieceWhite = piece.startsWith('w');
                      bool shouldBeWhiteTurn = playerNextTurnColor == 'w';

                      if (isPieceWhite == shouldBeWhiteTurn) {
                        setState(() {
                          selectedRow = row;
                          selectedCol = col;
                          pieceString =
                              piece; // Set the piece string for move notation
                          calculateValidMoves(row, col);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'It\'s ${shouldBeWhiteTurn ? 'White' : 'Black'}\'s turn!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } else {
                      // Deselect
                      setState(() {
                        selectedRow = null;
                        selectedCol = null;
                        resetValidMoves();
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: tileColor,
                      border: Border.all(color: Colors.black, width: 0.5),
                    ),
                    child: Stack(
                      children: [
                        if (piece.isNotEmpty)
                          Center(child: _buildPieceWidget(piece, row, col)),
                        if (isValidMove && piece.isEmpty)
                          Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        // Show algebraic notation in corner
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              Position(row, col).algebraic,
                              style: const TextStyle(
                                  fontSize: 8, color: Colors.white),
                            ),
                          ),
                        ),
                        // Show lock indicator when moves are disabled
                        // if (isMoveLocked || !isMyTurn)
                        //   Container(
                        //     decoration: BoxDecoration(
                        //       color: Colors.grey.withOpacity(0.5),
                        //     ),
                        //     child: const Center(
                        //       child: Icon(
                        //         Icons.lock,
                        //         color: Colors.white70,
                        //         size: 16,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '10x10 Chess - ${isBlackAtBottom ? 'Black' : 'White'} at Bottom'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Game status
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Turn: ${isWhiteTurn ? 'White' : 'Black'}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isWhiteKingInCheck)
                  const Text(
                    'White King in CHECK!',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                if (isBlackKingInCheck)
                  const Text(
                    'Black King in CHECK!',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          // Board
          Expanded(child: _buildBoard()),
          // Move history
          if (moveHistory.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Move History:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      if (currentMoveIndex != -1)
                        TextButton(
                          onPressed: returnToCurrentPosition,
                          child: const Text('Return to Current'),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: moveHistory.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => viewMove(index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentMoveIndex == index
                                  ? Colors.blue[200]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}. ${moveHistory[index]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: currentMoveIndex == index
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => resetGame(blackAtBottom: false),
                  icon: const Icon(Icons.refresh),
                  label: const Text("White at Bottom"),
                ),
                ElevatedButton.icon(
                  onPressed: () => resetGame(blackAtBottom: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Black at Bottom"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
