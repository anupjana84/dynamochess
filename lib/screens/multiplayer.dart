import 'package:dynamochess/utils/api_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';

class MultiplayerChessScreen extends StatefulWidget {
  const MultiplayerChessScreen({Key? key}) : super(key: key);

  @override
  State<MultiplayerChessScreen> createState() => _MultiplayerChessScreenState();
}

class _MultiplayerChessScreenState extends State<MultiplayerChessScreen> {
  late IO.Socket socket;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const int boardSize = 10;
  late List<List<String>> board;
  // late String playerId;
  String roomCode = "pp";
  String playerColor = 'w'; // Default to white // 'w' or 'b'
  String currentTurnColor = 'w'; // Initial turn is white
  bool isJoined = true;
  bool isInitialized = false;
  bool isKingInCheckFlag = false;
  bool isGameOver = false;
  String? gameResult; // e.g., "Checkmate! White wins!"
  String? playerId;
  String? userName;
  String? userProfileImage;
  double? userRating;
  String? countryIcon;
  String? dynamoCoin;

  TextEditingController roomIdController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _loadUserData();
    // connectToSocket();
    _loadUserData().then((_) {
      if (playerId != null) {
        connectToSocket();
      } else {
        Get.snackbar("Error", "User not logged in");
        // Get.offAllNamed('/login');
      }
    });
    //playerId = "player_${DateTime.now().millisecondsSinceEpoch}";
    board = createPosition(); // Default starting position
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs);
    setState(() {
      playerId = prefs.getString('_id');
      userName = prefs.getString('name');
      userProfileImage = prefs.getString('profileImageUrl');
      userRating = prefs.getDouble('rating');
      countryIcon = prefs.getString('countryIcon');
      dynamoCoin = prefs.getString('ountryIcon');
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _audioPlayer.dispose();
    roomIdController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _joinRoom() {
    if (playerId == null) return;

    socket.emit('joinRoom', {
      "playerId": playerId,
      "name": userName,
      "coin": dynamoCoin, // Assuming fixed coin value
      "profileImageUrl": userProfileImage ?? "",
      "playerStatus": "Good",
      "joinId": "randomMultiplayer",
      "timer": "600", // 10 minutes
      "countryicon": countryIcon,
    });
  }

  void connectToSocket() {
    // IMPORTANT: Replace with your actual backend URL
    socket = IO.io(ApiList.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      debugPrint("Connected to server");
      _joinRoom();
    });

    socket.on("receive_boardData", (data) {
      setState(() {
        final receivedPlayerColor =
            data['playerColour']; // The color of the player who *made* the move
        final boardData = List<List<String>>.from(
          (data['data']['newPosition'] as List)
              .map((row) => List<String>.from(row as List)),
        );
        final nextTurn =
            data['turn']; // Assuming your backend sends the next turn

        if (playerColor == 'b') {
          // Reverse board for black perspective if this client is black
          board = reverseBoard(boardData);
        } else {
          board = boardData;
        }

        currentTurnColor = nextTurn; // Update the turn based on server
        isKingInCheckFlag = isKingInCheck(board, playerColor);

        if (isKingInCheckFlag && isCheckmate(playerColor)) {
          gameResult =
              "Checkmate! ${playerColor == 'w' ? 'Black' : 'White'} wins!";
          isGameOver = true;
        } else if (isStalemate(playerColor)) {
          gameResult = "Stalemate! It's a draw.";
          isGameOver = true;
        }

        debugPrint("Board updated from opponent. Next turn: $currentTurnColor");
      });
    });

    socket.on("reJoinRoomData", (roomData) {
      setState(() {
        final players = roomData['players'];
        for (var p in players) {
          if (p['playerId'] == playerId) {
            playerColor = p['colour'];
            break;
          }
        }

        final data = List<List<String>>.from(
          (roomData['allBoardData'].last['newPosition'] as List)
              .map((row) => List<String>.from(row as List)),
        );
        board = playerColor == 'w' ? data : reverseBoard(data);
        roomCode = roomData['_id'];
        currentTurnColor = roomData['turn']; // Get current turn on rejoin
        isJoined = true;
        isInitialized = true;
        isKingInCheckFlag = isKingInCheck(board, playerColor);
        debugPrint(
            "Rejoined room: $roomCode. My color: $playerColor. Turn: $currentTurnColor");
      });
    });

    socket.on("JoinStatus", (status) {
      if (status == true) {
        debugPrint("Successfully joined room");
      } else {
        debugPrint("Failed to join room");
      }
    });

    socket.on("nextPlayerTurn", (data) {
      setState(() {
        currentTurnColor =
            data; // Ensure this data is just the color 'w' or 'b'
        debugPrint("It's $currentTurnColor's turn.");
      });
    });

    socket.on("gameEnded", (data) {
      setState(() {
        isGameOver = true;
        gameResult = data['message'] ?? "Game Over!";
      });
    });
  }

  List<List<String>> createPosition() {
    List<List<String>> position =
        List.generate(boardSize, (_) => List.filled(boardSize, ''));

    // Pawns
    for (int i = 0; i < boardSize; i++) {
      position[1][i] = 'bp'; // Black pawns
      position[8][i] = 'wp'; // White pawns
    }

    // Back rank pieces (10x10)
    // wr, wn, wb, wm, wq, wk, wm, wb, wn, wr
    final whitePieces = [
      'wr',
      'wn',
      'wb',
      'wm',
      'wq',
      'wk',
      'wm',
      'wb',
      'wn',
      'wr'
    ];
    final blackPieces = [
      'br',
      'bn',
      'bb',
      'bm',
      'bq',
      'bk',
      'bm',
      'bb',
      'bn',
      'br'
    ];

    for (int i = 0; i < boardSize; i++) {
      position[0][i] = blackPieces[i];
      position[9][i] = whitePieces[i];
    }

    return position;
  }

  List<List<String>> reverseBoard(List<List<String>> pos) {
    return List.generate(pos.length, (i) => pos[pos.length - 1 - i]);
  }

  void joinRoom(String roomId) {
    final name = nameController.text.isNotEmpty ? nameController.text : "Guest";

    final data = {
      "roomId": roomId,
      "playerId": playerId,
      "name": name,
      "coin": 0,
      "joinId":
          "randomMultiplayer", // This seems specific to your backend setup
      "timer": 60,
      "profileImageUrl": "",
      "countryicon": "",
    };

    socket.emit("joinRoom", data);

    setState(() {
      roomCode = roomId;
      isJoined = true;
    });
  }

  void sendMove(
      int fromRow, int fromCol, int toRow, int toCol, String pieceMoved) {
    setState(() {
      final moveData = {
        "roomId": roomCode,
        "playerId": playerId,
        "boardData": {"newPosition": board}, // Send the updated board
        "fromRow": fromRow,
        "fromCol": fromCol,
        "toRow": toRow,
        "toCol": toCol,
        "piece": pieceMoved,
      };

      socket.emit("boardUpdate", moveData);
      _playMoveSound();

      // After a move, update check status for the *other* player's king
      final opponentColor = playerColor == 'w' ? 'b' : 'w';
      isKingInCheckFlag = isKingInCheck(board,
          opponentColor); // This will show if the *opponent's* king is in check.
      // You might want a separate flag for your own king.
      // For simplicity, isKingInCheckFlag here just indicates *a* king is in check
      // For UI, you'd check isKingInCheck(board, playerColor)
    });
  }

  void _playMoveSound() async {
    await _audioPlayer.play(AssetSource('sound/move.mp3'));
  }

  Position? selectedPosition;
  List<Position> possibleMoves = [];

  void onTileTap(int row, int col) {
    debugPrint(row.toString());
    print(!isJoined);
    print(isInitialized);
    print(isGameOver);
    print(currentTurnColor);
    print(playerColor);
    // if (!isJoined || !isInitialized || isGameOver) return;
    if (playerColor != currentTurnColor) {
      debugPrint("It's not your turn!");
      return;
    }

    final piece = board[row][col];
    final isMyPiece = piece.isNotEmpty &&
        ((playerColor == 'w' && piece.startsWith('w')) ||
            (playerColor == 'b' && piece.startsWith('b')));

    if (selectedPosition == null) {
      if (isMyPiece) {
        setState(() {
          selectedPosition = Position(row, col);
          possibleMoves = _calculatePossibleMoves(row, col);
        });
      }
    } else {
      final fromRow = selectedPosition!.row;
      final fromCol = selectedPosition!.col;

      // If the tapped tile is the currently selected piece, deselect it
      if (fromRow == row && fromCol == col) {
        setState(() {
          selectedPosition = null;
          possibleMoves = [];
        });
        return;
      }

      // If the tapped tile contains my own piece, change selection
      if (isMyPiece) {
        setState(() {
          selectedPosition = Position(row, col);
          possibleMoves = _calculatePossibleMoves(row, col);
        });
        return;
      }

      // If valid move to a different square
      if (isValidMove(fromRow, fromCol, row, col)) {
        String movedPiece = board[fromRow][fromCol];

        // Handle missile promotion
        if (movedPiece.endsWith('m')) {
          final int promotionRow = playerColor == 'w'
              ? 0
              : 9; // White promotes at row 0, Black at row 9
          if (row == promotionRow) {
            movedPiece =
                movedPiece.replaceFirst('m', 'q'); // Promote missile to queen
          }
        }

        // Apply the move to the local board state immediately for visual feedback
        // The server will send the authoritative board state back
        List<List<String>> tempBoard =
            List.from(board.map((r) => List.from(r)));
        tempBoard[row][col] = movedPiece;
        tempBoard[fromRow][fromCol] = '';
        board = tempBoard; // Update local board

        sendMove(fromRow, fromCol, row, col,
            movedPiece); // Send this move to the server

        setState(() {
          selectedPosition = null;
          possibleMoves = [];
          // The board will be updated again by `receive_boardData` from the server
          // This ensures client and server are in sync.
        });
      } else {
        // If it's an invalid move, deselect the piece
        setState(() {
          selectedPosition = null;
          possibleMoves = [];
        });
      }
    }
  }

  // --- Move Validation Logic ---

  List<Position> _calculatePossibleMoves(int fromRow, int fromCol) {
    List<Position> moves = [];
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (isValidMove(fromRow, fromCol, row, col)) {
          moves.add(Position(row, col));
        }
      }
    }
    return moves;
  }

  bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (fromRow < 0 ||
        fromRow >= boardSize ||
        fromCol < 0 ||
        fromCol >= boardSize ||
        toRow < 0 ||
        toRow >= boardSize ||
        toCol < 0 ||
        toCol >= boardSize) {
      return false; // Out of bounds
    }

    if (fromRow == toRow && fromCol == toCol) {
      return false; // Cannot move to the same square
    }

    final piece = board[fromRow][fromCol];
    if (piece.isEmpty) {
      return false; // No piece to move
    }

    final targetPiece = board[toRow][toCol];
    final isWhitePiece = piece.startsWith('w');
    final isBlackPiece = piece.startsWith('b');
    final isTargetWhitePiece = targetPiece.startsWith('w');
    final isTargetBlackPiece = targetPiece.startsWith('b');

    if ((isWhitePiece && isTargetWhitePiece) ||
        (isBlackPiece && isTargetBlackPiece)) {
      return false; // Cannot capture your own piece
    }

    // Ensure it's the current player's piece
    if ((playerColor == 'w' && isBlackPiece) ||
        (playerColor == 'b' && isWhitePiece)) {
      // This check might be redundant if `onTileTap` already filters for `isMyPiece`
      // but good for robustness if `isValidMove` is called elsewhere.
      return false;
    }

    // Piece-specific raw move validation (without check consideration yet)
    bool rawMoveValid = false;
    switch (piece.substring(1)) {
      // Get piece type (e.g., 'p' for pawn)
      case 'p':
        rawMoveValid =
            _isValidPawnMove(board, fromRow, fromCol, toRow, toCol, piece);
        break;
      case 'r':
        rawMoveValid = _isValidRookMove(board, fromRow, fromCol, toRow, toCol);
        break;
      case 'n':
        rawMoveValid = _isValidKnightMove(fromRow, fromCol, toRow, toCol);
        break;
      case 'b':
        rawMoveValid =
            _isValidBishopMove(board, fromRow, fromCol, toRow, toCol);
        break;
      case 'q':
        rawMoveValid = _isValidQueenMove(board, fromRow, fromCol, toRow, toCol);
        break;
      case 'k':
        rawMoveValid = _isValidKingMove(fromRow, fromCol, toRow, toCol);
        break;
      case 'm':
        rawMoveValid =
            _isValidMissileMove(board, fromRow, fromCol, toRow, toCol, piece);
        break;
      default:
        rawMoveValid = false; // Unknown piece
    }

    if (!rawMoveValid) {
      return false;
    }

    // Simulate the move to check for King in check
    List<List<String>> tempBoard =
        List.from(board.map((row) => List.from(row)));
    tempBoard[toRow][toCol] = tempBoard[fromRow][fromCol];
    tempBoard[fromRow][fromCol] = '';

    if (isKingInCheck(tempBoard, playerColor)) {
      return false; // Move puts or leaves current player's king in check
    }

    return true;
  }

  // Helper functions for raw piece movement (no check logic)
  bool _isValidPawnMove(List<List<String>> currentBoard, int fromRow,
      int fromCol, int toRow, int toCol, String piece) {
    final int direction = piece.startsWith('w')
        ? -1
        : 1; // White moves up (-1), Black moves down (+1)

    // Forward move
    if (fromCol == toCol) {
      // Single step forward
      if (toRow == fromRow + direction && currentBoard[toRow][toCol].isEmpty) {
        return true;
      }
      // Initial two-square move (for 10x10, pawns start on row 8 for white, row 1 for black)
      if ((piece.startsWith('w') &&
              fromRow == 8 &&
              toRow == 6 &&
              currentBoard[6][toCol].isEmpty &&
              currentBoard[7][toCol].isEmpty) ||
          (piece.startsWith('b') &&
              fromRow == 1 &&
              toRow == 3 &&
              currentBoard[3][toCol].isEmpty &&
              currentBoard[2][toCol].isEmpty)) {
        return true;
      }
    }
    // Captures (diagonal)
    if ((toCol == fromCol + 1 || toCol == fromCol - 1) &&
        toRow == fromRow + direction) {
      if (currentBoard[toRow][toCol].isNotEmpty &&
          ((piece.startsWith('w') &&
                  currentBoard[toRow][toCol].startsWith('b')) ||
              (piece.startsWith('b') &&
                  currentBoard[toRow][toCol].startsWith('w')))) {
        return true;
      }
    }
    return false;
  }

  bool _isValidRookMove(List<List<String>> currentBoard, int fromRow,
      int fromCol, int toRow, int toCol) {
    if (fromRow == toRow) {
      // Horizontal move
      int startCol = fromCol < toCol ? fromCol : toCol;
      int endCol = fromCol < toCol ? toCol : fromCol;
      for (int col = startCol + 1; col < endCol; col++) {
        if (currentBoard[fromRow][col].isNotEmpty) return false; // Path blocked
      }
      return true;
    } else if (fromCol == toCol) {
      // Vertical move
      int startRow = fromRow < toRow ? fromRow : toRow;
      int endRow = fromRow < toRow ? toRow : fromRow;
      for (int row = startRow + 1; row < endRow; row++) {
        if (currentBoard[row][fromCol].isNotEmpty) return false; // Path blocked
      }
      return true;
    }
    return false;
  }

  bool _isValidKnightMove(int fromRow, int fromCol, int toRow, int toCol) {
    final int dr = (fromRow - toRow).abs();
    final int dc = (fromCol - toCol).abs();
    return (dr == 1 && dc == 2) || (dr == 2 && dc == 1);
  }

  bool _isValidBishopMove(List<List<String>> currentBoard, int fromRow,
      int fromCol, int toRow, int toCol) {
    if ((fromRow - toRow).abs() != (fromCol - toCol).abs()) {
      return false; // Not a diagonal move
    }

    int rowDirection = (toRow > fromRow) ? 1 : -1;
    int colDirection = (toCol > fromCol) ? 1 : -1;

    int r = fromRow + rowDirection;
    int c = fromCol + colDirection;

    while (r != toRow || c != toCol) {
      if (currentBoard[r][c].isNotEmpty) {
        return false; // Path blocked
      }
      r += rowDirection;
      c += colDirection;
    }
    return true;
  }

  bool _isValidQueenMove(List<List<String>> currentBoard, int fromRow,
      int fromCol, int toRow, int toCol) {
    return _isValidRookMove(currentBoard, fromRow, fromCol, toRow, toCol) ||
        _isValidBishopMove(currentBoard, fromRow, fromCol, toRow, toCol);
  }

  bool _isValidKingMove(int fromRow, int fromCol, int toRow, int toCol) {
    final int dr = (fromRow - toRow).abs();
    final int dc = (fromCol - toCol).abs();
    return (dr <= 1 && dc <= 1);
  }

  // Custom Missile Move: straight forward, can't capture, can promote
  bool _isValidMissileMove(List<List<String>> currentBoard, int fromRow,
      int fromCol, int toRow, int toCol, String piece) {
    final int direction = piece.startsWith('w')
        ? -1
        : 1; // White missile moves up, Black missile moves down

    // Must move in the same column and forward
    if (fromCol == toCol && (toRow - fromRow).sign == direction) {
      // Check if path is clear
      int startRow = fromRow + direction;
      int endRow = toRow;

      if (direction == 1) {
        // Black missile
        for (int r = startRow; r < endRow; r += direction) {
          if (currentBoard[r][fromCol].isNotEmpty) return false; // Path blocked
        }
      } else {
        // White missile
        for (int r = startRow; r > endRow; r += direction) {
          if (currentBoard[r][fromCol].isNotEmpty) return false; // Path blocked
        }
      }

      // Missile cannot capture other pieces, must land on empty square
      return currentBoard[toRow][toCol].isEmpty;
    }
    return false;
  }

  // --- Check/Checkmate Logic ---

  Position? _findKing(List<List<String>> currentBoard, String kingColor) {
    final String kingPiece = kingColor == 'w' ? 'wk' : 'bk';
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (currentBoard[r][c] == kingPiece) {
          return Position(r, c);
        }
      }
    }
    return null; // Should not happen in a valid game
  }

  bool isKingInCheck(List<List<String>> currentBoard, String kingColor) {
    final Position? kingPos = _findKing(currentBoard, kingColor);
    if (kingPos == null) return false;

    final int kingRow = kingPos.row;
    final int kingCol = kingPos.col;
    final String opponentColor = kingColor == 'w' ? 'b' : 'w';

    // Iterate through all opponent's pieces and check if they can attack the king
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final String piece = currentBoard[r][c];
        if (piece.isNotEmpty && piece.startsWith(opponentColor)) {
          if (_canOpponentPieceAttack(currentBoard, r, c, kingRow, kingCol)) {
            return true; // King is in check
          }
        }
      }
    }
    return false;
  }

  // Helper to check if an opponent's piece can attack a target square on a given board
  bool _canOpponentPieceAttack(List<List<String>> boardToCheck, int fromRow,
      int fromCol, int toRow, int toCol) {
    final String piece = boardToCheck[fromRow][fromCol];
    if (piece.isEmpty) return false;

    final String pieceType = piece.substring(1);

    switch (pieceType) {
      case 'p':
        return _isValidPawnAttack(
            boardToCheck, fromRow, fromCol, toRow, toCol, piece);
      case 'r':
        return _isValidRookMove(boardToCheck, fromRow, fromCol, toRow, toCol);
      case 'n':
        return _isValidKnightMove(fromRow, fromCol, toRow, toCol);
      case 'b':
        return _isValidBishopMove(boardToCheck, fromRow, fromCol, toRow, toCol);
      case 'q':
        return _isValidQueenMove(boardToCheck, fromRow, fromCol, toRow, toCol);
      case 'k':
        return _isValidKingMove(fromRow, fromCol, toRow, toCol);
      case 'm':
        return _isValidMissileAttack(
            boardToCheck, fromRow, fromCol, toRow, toCol, piece);
      default:
        return false;
    }
  }

  // Specialized pawn attack (only diagonal for captures)
  bool _isValidPawnAttack(List<List<String>> boardToCheck, int fromRow,
      int fromCol, int toRow, int toCol, String piece) {
    final int direction = piece.startsWith('w')
        ? -1
        : 1; // White pawn attacks down, Black pawn attacks up
    if (toRow == fromRow + direction &&
        (toCol == fromCol + 1 || toCol == fromCol - 1)) {
      return true;
    }
    return false;
  }

  // Missile attack - similar to move, but can target a piece
  bool _isValidMissileAttack(List<List<String>> currentBoard, int fromRow,
      int fromCol, int toRow, int toCol, String piece) {
    final int direction = piece.startsWith('w') ? -1 : 1;

    if (fromCol == toCol && (toRow - fromRow).sign == direction) {
      int startRow = fromRow + direction;
      int endRow = toRow;

      if (direction == 1) {
        // Black missile
        for (int r = startRow; r < endRow; r += direction) {
          if (currentBoard[r][fromCol].isNotEmpty) return false;
        }
      } else {
        // White missile
        for (int r = startRow; r > endRow; r += direction) {
          if (currentBoard[r][fromCol].isNotEmpty) return false;
        }
      }
      // Missile can attack any piece in its straight path
      return true;
    }
    return false;
  }

  bool isCheckmate(String kingColor) {
    if (!isKingInCheck(board, kingColor)) {
      return false; // Not in check, so not checkmate
    }

    // Iterate through all of the current player's pieces
    for (int fromRow = 0; fromRow < boardSize; fromRow++) {
      for (int fromCol = 0; fromCol < boardSize; fromCol++) {
        final String piece = board[fromRow][fromCol];
        if (piece.isNotEmpty &&
            ((kingColor == 'w' && piece.startsWith('w')) ||
                (kingColor == 'b' && piece.startsWith('b')))) {
          // For each piece, check all possible moves
          for (int toRow = 0; toRow < boardSize; toRow++) {
            for (int toCol = 0; toCol < boardSize; toCol++) {
              // If isValidMove returns true, it means the move is legal and does not
              // leave the king in check. So, it's not checkmate.
              if (isValidMove(fromRow, fromCol, toRow, toCol)) {
                return false;
              }
            }
          }
        }
      }
    }
    return true; // No legal moves found to get out of check
  }

  bool isStalemate(String kingColor) {
    // If the king is in check, it's not stalemate
    if (isKingInCheck(board, kingColor)) {
      return false;
    }

    // Check if the current player has any legal moves
    for (int fromRow = 0; fromRow < boardSize; fromRow++) {
      for (int fromCol = 0; fromCol < boardSize; fromCol++) {
        final String piece = board[fromRow][fromCol];
        if (piece.isNotEmpty &&
            ((kingColor == 'w' && piece.startsWith('w')) ||
                (kingColor == 'b' && piece.startsWith('b')))) {
          for (int toRow = 0; toRow < boardSize; toRow++) {
            for (int toCol = 0; toCol < boardSize; toCol++) {
              if (isValidMove(fromRow, fromCol, toRow, toCol)) {
                return false; // Found a legal move, so not stalemate
              }
            }
          }
        }
      }
    }
    return true; // No legal moves found, and not in check, so it's stalemate
  }

  @override
  Widget build(BuildContext context) {
    final displayBoard = playerColor == 'b' ? reverseBoard(board) : board;
    final displaySelectedPosition = selectedPosition != null
        ? (playerColor == 'b'
            ? Position(boardSize - 1 - selectedPosition!.row,
                boardSize - 1 - selectedPosition!.col)
            : selectedPosition!)
        : null;
    final displayPossibleMoves = possibleMoves
        .map((pos) => playerColor == 'b'
            ? Position(boardSize - 1 - pos.row, boardSize - 1 - pos.col)
            : pos)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            const Text('Dynamo Chess', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              isJoined ? "Room: $roomCode" : "Online Chess",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  isGameOver
                      ? gameResult!
                      : (playerColor == currentTurnColor
                          ? "Your Turn (${playerColor.toUpperCase()})"
                          : "Opponent's Turn (${currentTurnColor.toUpperCase()})"),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isKingInCheck(board, playerColor)
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: boardSize,
                  ),
                  itemCount: boardSize * boardSize,
                  itemBuilder: (context, index) {
                    final row = index ~/ boardSize;
                    final col = index % boardSize;

                    final piece = displayBoard[row][col];
                    final isSelected = displaySelectedPosition?.row == row &&
                        displaySelectedPosition?.col == col;
                    final isPossibleMove =
                        displayPossibleMoves.contains(Position(row, col));

                    Color tileColor = (row + col) % 2 == 0
                        ? Colors.brown.shade200
                        : Colors.white;

                    if (isSelected) {
                      tileColor = Colors.yellow;
                    } else if (isPossibleMove) {
                      tileColor = Colors.green.shade200;
                    }

                    // Highlight king in check
                    final kingPos = _findKing(board, playerColor);
                    if (isKingInCheck(board, playerColor) &&
                        kingPos != null &&
                        ((playerColor == 'w' &&
                                row == kingPos.row &&
                                col == kingPos.col) ||
                            (playerColor == 'b' &&
                                row == (boardSize - 1 - kingPos.row) &&
                                col == (boardSize - 1 - kingPos.col)))) {
                      tileColor = Colors.red.shade400;
                    }

                    return GestureDetector(
                      onTap: () => onTileTap(
                        playerColor == 'b'
                            ? boardSize - 1 - row
                            : row, // Convert display coordinates back to actual board coordinates
                        playerColor == 'b' ? boardSize - 1 - col : col,
                      ),
                      child: Container(
                        color: tileColor,
                        child: Center(
                          child: piece.isNotEmpty
                              ? Image.asset("assets/ducpices/BLACK/$piece.png")
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (isGameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: AlertDialog(
                    title: const Text("Game Over!"),
                    content: Text(gameResult ?? "The game has ended."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Reset game state or navigate away
                          setState(() {
                            isJoined = false;
                            isInitialized = false;
                            isGameOver = false;
                            gameResult = null;
                            board = createPosition();
                            currentTurnColor = 'w';
                            isKingInCheckFlag = false;
                            selectedPosition = null;
                            possibleMoves = [];
                            // Reconnect or allow new room join
                            // You might want to disconnect and reconnect socket or have a "New Game" button
                          });
                        },
                        child: const Text("Play Again"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back from chess screen
                        },
                        child: const Text("Exit"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  String get algebraic {
    if (row < 0 || row >= 10 || col < 0 || col >= 10) {
      return 'Invalid';
    }
    final colChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rowNum =
        10 - row; // Assuming 10x10 board, a10 is bottom-left, j1 is top-right
    return '$colChar$rowNum';
  }
}
