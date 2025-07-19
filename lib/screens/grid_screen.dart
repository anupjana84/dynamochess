import 'package:audioplayers/audioplayers.dart';
import 'package:dynamochess/models/user_details.dart';
import 'package:dynamochess/utils/api_list.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void toastInfo(String message) {
  // Replace with your actual toast/snackbar implementation

  // Example using ScaffoldMessenger (requires a BuildContext)
  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class Position {
  final int row;
  final int col;
  final bool isBlackAtBottom;
  Position(this.row, this.col, {this.isBlackAtBottom = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  // New getter to convert to algebraic notation
  String get algebraic {
    if (row < 0 || row >= 10 || col < 0 || col >= 10) {
      return 'Invalid'; // Should not happen with valid game logic
    }
    // 'a' for col 0, 'b' for col 1, etc.
    final colChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    // For a 10x10 board, row 0 (top) is rank 10, row 9 (bottom) is rank 1
    // final rowNum = 10 - row;
    final rowNum = isBlackAtBottom ? row + 1 : 10 - row;
    return '$colChar$rowNum';
  }
}

List<List<String>> createPosition() {
  // Create a 10x10 board filled with empty strings
  List<List<String>> position = List.generate(10, (_) => List.filled(10, ''));

  // Setup pawns
  for (int i = 0; i < 10; i++) {
    position[1][i] = 'bp'; // Black pawns (now at row 1)
    position[8][i] = 'wp'; // White pawns (now at row 8)
  }

  // Setup black pieces (now at row 0)
  position[0][0] = 'br'; // Rook
  position[0][1] = 'bn'; // Knight
  position[0][2] = 'bb'; // Bishop
  position[0][3] = 'bm'; // missile
  position[0][4] = 'bq'; // Queen
  position[0][5] = 'bk'; // King
  position[0][6] = 'bm'; // missile
  position[0][7] = 'bb'; // Bishop
  position[0][8] = 'bn'; // Knight
  position[0][9] = 'br'; // Rook

  // Setup white pieces (now at row 9)
  position[9][0] = 'wr'; // Rook
  position[9][1] = 'wn'; // Knight
  position[9][2] = 'wb'; // Bishop
  position[9][3] = 'wm'; // missile
  position[9][4] = 'wq'; // Queen
  position[9][5] = 'wk'; // King
  position[9][6] = 'wm'; // missile
  position[9][7] = 'wb'; // Bishop
  position[9][8] = 'wn'; // Knight
  position[9][9] = 'wr'; // Rook

  return position;
}

const Map<String, String> pieceImages = {
  'bp': 'assets/ducpices/BLACK/bp2.png',
  'br': 'assets/ducpices/BLACK/br2.png',
  'bn': 'assets/ducpices/BLACK/bn.png',
  'bb': 'assets/ducpices/BLACK/bb.png',
  'bq': 'assets/ducpices/BLACK/bq2.png',
  'bk': 'assets/ducpices/BLACK/bk2.png',
  'bm': 'assets/ducpices/BLACK/bm.png',
  'wp': 'assets/ducpices/WHITE/wp2.png',
  'wr': 'assets/ducpices/WHITE/wr2.png',
  'wn': 'assets/ducpices/WHITE/wn.png',
  'wb': 'assets/ducpices/WHITE/wb.png',
  'wq': 'assets/ducpices/WHITE/wq2.png',
  'wk': 'assets/ducpices/WHITE/wk2.png',
  'wm': 'assets/ducpices/WHITE/wm.png',
};

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late List<List<String>> position;
  int? selectedRow;
  int? selectedCol;
  bool isWhiteTurn = true;
  io.Socket? socket;

  //
  String timer1 = '00:00';
  String timer2 = '00:00';

  // Booleans
  bool isSound = true;
  bool isNavigation = true;
  bool gameAborted = false;
  bool leaveRoom = false;
  bool leave = false;

  // Lists
  List<Map<String, dynamic>> players = [];

  // Strings
  String playernextTurn = "";
  // String playernextId = "";
  String? nextPlayerColor;

  var newBoardData = [];
  var movePosition = '';
  // String? playerId
  Position? selectedPosition;
  bool startGame = false;

  String playerNextTurnColor = ''; // 'w' or 'b'
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
  bool isPopupDisabled = false; // For the "Please wait for opponent" popup
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
  //
  String? playerId;
  String? userName;
  String? userProfileImage;
  double? userRating;
  String? countryIcon;
  String? dynamoCoin;
  List<List<bool>> validMoves =
      List.generate(10, (_) => List.filled(10, false));
  UserDetail? _currentUserDetail;
  OverlayEntry? _overlayEntry;
  final GlobalKey<_GridScreenState> gridKey = GlobalKey();

  void _showPromotionMenu(int toRow, int toCol, String colorPrefix) {
    final RenderBox gridBox = context.findRenderObject() as RenderBox;
    final Size squareSize = Size(50, 50); // Approximate tile size

    // Calculate position where the pawn is located
    final Offset buttonTopLeft = gridBox.localToGlobal(Offset(
      toCol * squareSize.width,
      toRow * squareSize.height,
    ));

    final OverlayState overlayState = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: buttonTopLeft.dx,
        top: buttonTopLeft.dy,
        child: Material(
          elevation: 8.0,
          child: buildPromotionMenu(toRow, toCol, colorPrefix),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  @override
  void initState() {
    super.initState();
    position = createPosition();
    _loadUserData().then((_) {
      if (_currentUserDetail != null && _currentUserDetail!.id.isNotEmpty) {
        _connectSocket();
        setState(() {
          gameStatus = 'Initializing game...';
        });
      } else {
        setState(() {
          gameStatus = 'Please log in to play';
          toastInfo("User not logged in. Please log in to play online.");
          // You might want to navigate to a login screen here
        });
      }
    });
  }

  void _playMoveSound(String sound) async {
    try {
      await _audioPlayer.play(AssetSource(sound));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  String _convertSecondsToMinutes(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    String formattedSeconds = seconds < 10 ? '0$seconds' : '$seconds';
    return '$minutes:$formattedSeconds';
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserDetail = UserDetail.fromSharedPreferences(prefs);
    });
  }

  void _connectSocket() {
    // Replace with your actual backend URL
    socket = io.io(ApiList.baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'timeout': 20000,
    });

    socket?.connect();

    socket?.onConnect((_) {
      debugPrint('Connected to Socket.IO');
      if (_currentUserDetail != null && _currentUserDetail!.id.isNotEmpty) {
        _joinRoom();
      } else {
        toastInfo("User not logged in. Cannot join room.");
      }
    });

    socket?.onDisconnect((_) => debugPrint('Disconnected from Socket.IO'));
    socket?.onConnectError((err) => debugPrint('Connection Error: $err'));
    socket?.onError((err) => debugPrint('Socket Error: $err.toString()'));

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    socket?.on('roomJoined', (data) {
      debugPrint(data.toString());
      setState(() {
        roomId = data['roomId'];
        // debugPrint('Room Joined: $roomId');
      });
    });

    socket?.on('createPosition', (data) {
      final List<dynamic> initialBoard = data['createPosition'];

      setState(() {});
    });

    socket?.on('receive_boardData', (data) {
      final List<dynamic> newPositionData = data['data']['newPosition'];
      print("data ${data}");

      setState(() {
        isGameAborted = false;
        isRoomLeft = false;
        winData = null;
        drawMessage = null;
        drawStatus = false;
        threefoldMessage = null;
        takebackRequested = false;
        rematchRequested = false;
        playerId = data['playerId'];

        // Determine if the board needs to be reversed for the current user
        if (newPositionData.isNotEmpty) {
          bool isCurrentUserBlack = players.isNotEmpty &&
              players.any((p) =>
                  p['playerId'] == _currentUserDetail?.id &&
                  p['colour'] == 'w');
          // print("isCurrentUserBlack $isCurrentUserBlack");
          // for bottom white

          // position = _convertBackendBoard(newPositionData,
          //     reverse: isCurrentUserBlack);
          // isWhiteTurn = true;

          // for bottom white

          // for bottom black
          // position = _convertBackendBoard(newPositionData,
          //     reverse: !isCurrentUserBlack);
          // isWhiteTurn = false;
          //for bottom black
          currentPlayerIsWhite = !isCurrentUserBlack;
          if (isCurrentUserBlack) {
            // print("yes");
            position = _convertBackendBoard(newPositionData,
                reverse: isCurrentUserBlack);
            isWhiteTurn = true;
          } else {
            // print("not");
            position = _convertBackendBoard(newPositionData,
                reverse: !isCurrentUserBlack);
            isWhiteTurn = false;
          }
        }
      });
    });
    socket?.on("moveList", (data) {
      print("object $data");
      setState(() {
        moveList = data;
      });
    });
    socket?.emit('abortGame', {
      'roomId': roomId,
      'playerId': _currentUserDetail?.id,
    });
    socket?.on('updatedRoom', (data) {
      print("updatedRoom $data");

      setState(() {
        nextPlayerColor = data['nextPlayerColor'];
        players = List<Map<String, dynamic>>.from(data['players']);
        timer1 = _convertSecondsToMinutes(data['timer1'] ?? 0);
        timer2 = _convertSecondsToMinutes(data['timer2'] ?? 0);
        // moveList = List<String>.from(data['moveList'] ?? []);

        if (players.length > 1) {
          startGame = true;
          isPopupDisabled = true;
        }

        if (data['allBoardData'] != null && data['allBoardData'].isNotEmpty) {
          final List<dynamic> latestBoardData =
              data['allBoardData'].last['newPosition'];
          // print("object $latestBoardData");

          bool isCurrentUserBlack = players.isNotEmpty &&
              players.any((p) =>
                  p['playerId'] == _currentUserDetail?.id &&
                  p['colour'] == 'w');
          // print("isCurrentUserBlack $isCurrentUserBlack");
          //for bottom white
          // position = _convertBackendBoard(latestBoardData,
          //     reverse: isCurrentUserBlack);
          // isWhiteTurn = isCurrentUserBlack;
          //for bottom white

          //for bottom black
          // position = _convertBackendBoard(latestBoardData,
          //     reverse: isCurrentUserBlack);
          // isWhiteTurn = false;
          //for bottom black

          if (_currentUserDetail!.id == playerNextId) {
            position = _convertBackendBoard(latestBoardData,
                reverse: isCurrentUserBlack);
            isWhiteTurn = isCurrentUserBlack;
          } else {
            position = _convertBackendBoard(latestBoardData,
                reverse: isCurrentUserBlack);
            isWhiteTurn = false;
          }
        }

        showboard = true;
      });
    });

    socket?.on('startGame', (data) {
      print(data);
      setState(() {
        startGame = data['start'];
        isPopupDisabled = true;
        // });
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
        print(data);
        setState(() {
          playerNextTurnColor = data['playerColour'];
          playerNextId = data['playerId'];
          //  gameStatus =
          // '${playerNextTurnColor == 'w' ? 'White' : 'Black'}\'s turn';
        });
      });

      socket?.on('playerWon', (data) {
        print("object $data");
        setState(() {
          //   winData = data;
          // gameStatus = data['playerId'] == _currentUserDetail?.id
          //    ? 'You Win!'
          //   : 'You Lose!';
          // _playGameEndSound(winData?['playerId'] == _currentUserDetail?.id);
        });
      });

      socket?.on('abort', (data) {
        setState(() {
          // isGameAborted = true;
          // gameStatus = 'Game Aborted!';
        });
      });

      socket?.on('checkMate', (data) {
        setState(() {
          // gameStatus = 'Checkmate!';
          // _playGameEndSound(winData?['playerId'] == _currentUserDetail?.id);
        });
      });

      socket?.on('roomLeftPlayerId', (data) {
        setState(() {
          // isRoomLeft = true;
          // gameStatus = 'Opponent Left!';
        });
      });

      socket?.on('DrawMessage', (data) {
        setState(() {
          //drawMessage = data['message'];
          //showDrawConfirmation = true;
        });
      });

      socket?.on('DrawStatus', (data) {
        setState(() {
          // drawStatus = data['DrawStatus'];
          // if (drawStatus) {
          //   gameStatus = 'Game Drawn!';
          //   _playGameEndSound(null); // Play draw sound
          // }
          // showDrawConfirmation = false;
        });
      });

      socket?.on('ThreeFold', (data) {
        setState(() {
          // threefoldMessage = data['message'];
          // showThreefoldConfirmation = true;
        });
      });

      socket?.on('threefoldStatus', (data) {
        setState(() {
          // threefoldStatus = data['threefoldStatus'];
          // if (threefoldStatus) {
          //   gameStatus = 'Game Drawn by Threefold Repetition!';
          //   _playGameEndSound(null);
          // }
          // showThreefoldConfirmation = false;
        });
      });

      socket?.on('rematch', (data) {
        setState(() {
          // rematchRequested = data;
          // showRematchConfirmation = true;
        });
      });

      socket?.on('rematchResponse', (data) {
        setState(() {
          // rematchRequested = false;
          // showRematchConfirmation = false;
          // if (data != false) {
          //   newGameTriggered = true;
          //   // In a real app, you'd navigate to the new room,
          //   // for this example, we'll just reload the board.
          //   _resetGame(); // Simulate new game
          //  _joinRoom(); // Join the new room
          //  }
        });
      });

      socket?.on('turnBack', (data) {
        setState(() {
          // takebackRequested = data;
          // showTakebackConfirmation = true;
        });
      });

      socket?.on('turnBackStatus', (data) {
        setState(() {
          // takebackRequested = false;
          // showTakebackConfirmation = false;
          // if (data['turnBackStatus'] == true) {
          //   // Backend should send the updated board after takeback
          //   // For now, we'll just acknowledge
          //   print('Takeback accepted!');
          //   }
        });
      });

      socket?.on('timerIs60', (data) {
        setState(() {
          // timerIs60 = data['successfully'];
          // if (timerIs60 && data['playerId'] == _currentUserDetail?.id) {
          //   _audioPlayer
          //       .play(AssetSource('sound/sort3.mp3')); // Play timer warning sound
          // }
        });
      });

      socket?.on('receive_message', (data) {
        setState(() {
          // chatMessages.add({
          //   'playerId': data['playerId'],
          //   'message': data['message'],
          // });
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

      // socket?.emit('leaveRoom', {
      //   "roomId": roomId,
      //   "playerId": _currentUserDetail!.id,
      // });

      // socket?.on('errorOccured', (data) {
      //   toastInfo('Error: $data');
    });
  }

  void _joinRoom() {
    // Ensure user data is loaded before attempting to join
    if (_currentUserDetail == null || _currentUserDetail!.id.isEmpty) {
      toastInfo("User data not loaded. Cannot join room.");
      return;
    }

    // You need to decide how roomId is determined.
    // For a random multiplayer game, you might not send a specific joinId.
    // For joining an existing game or tournament, you'd get this from navigation arguments.
    final String currentUrl =
        Uri.base.toString(); // This works for web, less for mobile
    final bool isTournament = currentUrl.contains("tournament:");
    final String? uniqueID =
        isTournament ? currentUrl.split("tournament:")[1].split('/')[0] : null;
    final String currentRoomId = uniqueID ??
        'randomMultiplayer'; // Default to random or specific ID from arguments
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
      setState(() {
        isPopupDisabled = false; // Show the "Please wait" popup
      });
    } else {
      toastInfo("Minimum point 2000 is not available");
      // Navigate away or show error
    }
  }

  void resetValidMoves() {
    validMoves = List.generate(10, (_) => List.filled(10, false));
  }

  List<List<String>> printBoardState() {
    List<List<String>> boardState = [];

    for (int i = 0; i < 10; i++) {
      List<String> row = [];
      for (int j = 0; j < 10; j++) {
        String piece = position[i][j];
        row.add(piece); // Add each piece directly
      }
      boardState.add(row); // Add the row to the board
    }

    return boardState;
  }

  void calculateValidMoves(int row, int col) {
    resetValidMoves();
    String piece = position[row][col];
    if (piece.isEmpty) return;

    bool isWhite = piece[0] == 'w';
    String pieceType = piece.substring(1);

    switch (pieceType) {
      case 'p': // Pawn
        // Get the current player's perspective
        bool isCurrentUserBlack = players.isNotEmpty &&
            players.any((p) =>
                p['playerId'] == _currentUserDetail?.id && p['colour'] == 'w');

        // Determine movement direction based on piece color and perspective
        int direction;
        if (isCurrentUserBlack) {
          // For black at bottom perspective
          direction = isWhite ? -1 : 1; // White moves up, black moves down
        } else {
          // For white at bottom perspective
          direction = isWhite ? 1 : -1; // White moves down, black moves up
        }

        // Check single square move forward
        if (row + direction >= 0 && row + direction < 10) {
          if (position[row + direction][col].isEmpty) {
            validMoves[row + direction][col] = true;

            // Check for initial 3-square move
            bool isStartingPosition = false;

            if (isWhite) {
              // White pawn starting positions
              if (isCurrentUserBlack) {
                isStartingPosition =
                    row == 8; // White starts at row 8 (black at bottom)
              } else {
                isStartingPosition =
                    row == 1; // White starts at row 1 (white at bottom)
              }
            } else {
              // Black pawn starting positions
              if (isCurrentUserBlack) {
                isStartingPosition =
                    row == 1; // Black starts at row 1 (black at bottom)
              } else {
                isStartingPosition =
                    row == 8; // Black starts at row 8 (white at bottom)
              }
            }

            // If on starting position, check for 2 and 3 squares ahead
            if (isStartingPosition) {
              // Check two squares ahead
              if (row + 2 * direction >= 0 &&
                  row + 2 * direction < 10 &&
                  position[row + direction][col].isEmpty &&
                  position[row + 2 * direction][col].isEmpty) {
                validMoves[row + 2 * direction][col] = true;
              }

              // Check three squares ahead
              if (row + 3 * direction >= 0 &&
                  row + 3 * direction < 10 &&
                  position[row + direction][col].isEmpty &&
                  position[row + 2 * direction][col].isEmpty &&
                  position[row + 3 * direction][col].isEmpty) {
                validMoves[row + 3 * direction][col] = true;
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
            if (target.isNotEmpty && target[0] != piece[0]) {
              validMoves[row + direction][col + i] = true;
            }
          }
        }
        break;
      case 'r': // Rook
        calculateStraightMoves(row, col, isWhite);
        break;
      case 'n': // Knight
        calculateKnightMoves(row, col, isWhite);
        break;
      case 'b': // Bishop
        calculateDiagonalMoves(row, col, isWhite);
        break;
      case 'q': // Queen
        calculateStraightMoves(row, col, isWhite);
        calculateDiagonalMoves(row, col, isWhite);
        break;
      case 'k': // King
        calculateKingMoves(row, col, isWhite);
        break;
      case 'm': // Minister (custom piece - moving like a knight but with different pattern)
        calculateDiagonalMoves(row, col, isWhite); // Bishop moves
        calculateKnightMoves(row, col, isWhite);
        break;
    }
  }

  void calculateStraightMoves(int row, int col, bool isWhite) {
    // Horizontal and vertical moves

    // Horizontal
    for (int dCol = -1; dCol <= 1; dCol += 2) {
      // -1 for left, 1 for right
      for (int c = col + dCol; c >= 0 && c < 10; c += dCol) {
        String targetPiece = position[row][c];
        if (targetPiece.isEmpty) {
          validMoves[row][c] = true;
        } else {
          if (targetPiece[0] != (isWhite ? 'w' : 'b')) {
            // Capture opponent's piece
            validMoves[row][c] = true;
          }
          break; // Stop at the first piece (own or opponent's)
        }
      }
    }

    // Vertical
    for (int dRow = -1; dRow <= 1; dRow += 2) {
      // -1 for up, 1 for down
      for (int r = row + dRow; r >= 0 && r < 10; r += dRow) {
        String targetPiece = position[r][col];
        if (targetPiece.isEmpty) {
          validMoves[r][col] = true;
        } else {
          if (targetPiece[0] != (isWhite ? 'w' : 'b')) {
            // Capture opponent's piece
            validMoves[r][col] = true;
          }
          break; // Stop at the first piece (own or opponent's)
        }
      }
    }
  }

  void calculateDiagonalMoves(int row, int col, bool isWhite) {
    // Directions for diagonal moves: topLeft, topRight, bottomLeft, bottomRight
    List<List<int>> directions = [
      [-1, -1], // Top-left
      [-1, 1], // Top-right
      [1, -1], // Bottom-left
      [1, 1] // Bottom-right
    ];

    for (var dir in directions) {
      int dRow = dir[0];
      int dCol = dir[1];

      for (int i = 1; i < 10; i++) {
        int r = row + i * dRow;
        int c = col + i * dCol;

        if (r >= 0 && r < 10 && c >= 0 && c < 10) {
          String targetPiece = position[r][c];
          if (targetPiece.isEmpty) {
            validMoves[r][c] = true;
          } else {
            if (targetPiece[0] != (isWhite ? 'w' : 'b')) {
              validMoves[r][c] = true; // Can capture opponent's piece
            }
            break; // Stop at the first piece (own or opponent's)
          }
        } else {
          break; // Out of bounds
        }
      }
    }
  }

  void calculateKnightMoves(int row, int col, bool isWhite) {
    // All possible L-shaped moves
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
        if (position[r][c].isEmpty ||
            position[r][c][0] == (isWhite ? 'b' : 'w')) {
          validMoves[r][c] = true;
        }
      }
    }
  }

  // The calculateMinisterMoves is not directly used for 'm' in calculateValidMoves
  // because the 'm' piece already combines Bishop and Knight moves.
  // It's kept here in case you want to define a distinct 'Minister' move later.
  void calculateMinisterMoves(int row, int col, bool isWhite) {
    // Example: moves 3 squares in any direction (not the current 'm' logic)
    List<List<int>> moves = [
      [row - 3, col],
      [row + 3, col],
      [row, col - 3],
      [row, col + 3],
      [row - 3, col - 3],
      [row - 3, col + 3],
      [row + 3, col - 3],
      [row + 3, col + 3],
    ];

    for (var move in moves) {
      int r = move[0], c = move[1];
      if (r >= 0 && r < 10 && c >= 0 && c < 10) {
        if (position[r][c].isEmpty ||
            position[r][c][0] == (isWhite ? 'b' : 'w')) {
          validMoves[r][c] = true;
        }
      }
    }
  }

  void calculateKingMoves(int row, int col, bool isWhite) {
    // All adjacent squares
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue; // Skip the current square
        int r = row + i, c = col + j;
        if (r >= 0 && r < 10 && c >= 0 && c < 10) {
          if (position[r][c].isEmpty ||
              position[r][c][0] == (isWhite ? 'b' : 'w')) {
            // Can move to empty square or capture opponent's piece
            validMoves[r][c] = true;
          }
        }
      }
    }
  }

  void movePiece(int fromRow, int fromCol, int toRow, int toCol, String piece) {
    bool isCapture = position[toRow][toCol].isNotEmpty;

    bool isBlackAtBottom = currentPlayerIsWhite;

    setState(() {
      // Move the piece
      position[toRow][toCol] = position[fromRow][fromCol];
      position[fromRow][fromCol] = '';

      // Check if this is a pawn reaching the end
      String movedPiece = position[toRow][toCol];

      if (movedPiece == 'wp' && toRow == 0) {
        _showPromotionDialog(context, toRow, toCol, 'w');
      } else if (movedPiece == 'bp' && toRow == 9) {
        _showPromotionDialog(context, toRow, toCol, 'b');
      }

      selectedRow = null;
      selectedCol = null;
      resetValidMoves();
      selectedPosition = Position(toRow, toCol);
      movePosition = generateMoveNotation(
          fromRow,
          fromCol,
          toRow,
          toCol,
          isCapture: isCapture,
          isBlackAtBottom: isBlackAtBottom,
          piece);

      final boardd = printBoardState();
      newBoardData = boardd;
    });

    if (socket != null && roomId != null && _currentUserDetail != null) {
      final ddddd = printBoardState().reversed.toList();
      socket?.emit('boardUpdate', {
        'roomId': roomId,
        'boardData': {"newPosition": ddddd},
        'playerId': _currentUserDetail!.id,
        'move': movePosition,
      });
    }
  }

  void _showPromotionDialog(
      BuildContext context, int toRow, int toCol, String colorPrefix) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (context) {
        return AlertDialog(
          title: Text('$colorPrefix Promotion'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Image.asset(
                  pieceImages['$colorPrefix' 'q']!,
                  width: 50,
                  height: 50,
                ),
                onPressed: () {
                  setState(() {
                    position[toRow][toCol] = '$colorPrefix' 'q';
                  });
                  Navigator.pop(context);
                },
                tooltip: 'Queen',
              ),
              IconButton(
                icon: Image.asset(
                  pieceImages['$colorPrefix' 'r']!,
                  width: 50,
                  height: 50,
                ),
                onPressed: () {
                  setState(() {
                    position[toRow][toCol] = '$colorPrefix' 'r';
                  });
                  Navigator.pop(context);
                },
                tooltip: 'Rook',
              ),
              IconButton(
                icon: Image.asset(
                  pieceImages['$colorPrefix' 'b']!,
                  width: 50,
                  height: 50,
                ),
                onPressed: () {
                  setState(() {
                    position[toRow][toCol] = '$colorPrefix' 'b';
                  });
                  Navigator.pop(context);
                },
                tooltip: 'Bishop',
              ),
              IconButton(
                icon: Image.asset(
                  pieceImages['$colorPrefix' 'n']!,
                  width: 50,
                  height: 50,
                ),
                onPressed: () {
                  setState(() {
                    position[toRow][toCol] = '$colorPrefix' 'n';
                  });
                  Navigator.pop(context);
                },
                tooltip: 'Knight',
              ),
            ],
          ),
        );
      },
    );
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
      _playMoveSound('sound/capture.mp3');

      if (pp == 'P') {
        return '${from[0]}x$to';
      }
      return '$pp${from[0]}x$to';
    } else {
      _playMoveSound('sound/move.mp3');
      if (pp == 'P') {
        return '$to';
      }

      return "${pp}$to";
    }
  }

  List<List<String>> _convertBackendBoard(List<dynamic> boardData,
      {bool reverse = false}) {
    int size = boardData.length;
    List<List<String>> convertedBoard =
        List.generate(size, (_) => List.filled(size, ''));

    for (int i = 0; i < size; i++) {
      List row = boardData[i];
      for (int j = 0; j < size; j++) {
        String piece = row[j]?.toString() ?? '';
        convertedBoard[i][j] = piece;
      }
    }

    if (reverse) {
      // Flip rows so the board appears from black's perspective
      convertedBoard = convertedBoard.reversed.map((row) => [...row]).toList();
    }

    return convertedBoard.cast<List<String>>();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(isWhiteTurn ? 'White\'s Turn grid' : 'Black\'s Turn'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildPlayerInfo(
              topPlayer, topTimer, playerNextId == topPlayer['playerId']),

          LayoutBuilder(builder: (context, constraints) {
            final boardDimension = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            final safeBoardDimension =
                boardDimension <= 0 ? 300.0 : boardDimension;
            return Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: safeBoardDimension,
                    height: safeBoardDimension,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 10,
                      ),
                      itemCount: 100, // 10x10 board
                      itemBuilder: (context, index) {
                        int row = index ~/ 10;
                        int col = index % 10;
                        String piece = position[row][col];

                        bool isSelected =
                            selectedRow == row && selectedCol == col;
                        bool isValidMove = validMoves[row][col];

                        Color tileColor = (row + col) % 2 == 0
                            ? const Color(0xFFDCDA5C)
                            : Colors.green; // Chessboard pattern
                        if (isSelected) {
                          tileColor =
                              Colors.yellowAccent; // Highlight selected piece
                        }
                        if (isValidMove) {
                          tileColor =
                              Colors.lightGreenAccent; // Highlight valid moves
                        }

                        return GestureDetector(
                          onTap: () {
                            if (_currentUserDetail!.id == playerNextId &&
                                piece.isNotEmpty &&
                                (piece[0] == 'w' &&
                                        playerNextTurnColor == 'w' ||
                                    piece[0] == 'b' &&
                                        playerNextTurnColor == 'b')) {
                              print(
                                  "Selected piece at row: $row, col: $col, piece: $piece");
                              // If a piece of the current player's color is tapped, select it
                              setState(() {
                                pieceString = piece;
                                selectedRow = row;
                                selectedCol = col;
                                calculateValidMoves(
                                    row, col); // Calculate its valid moves
                              });
                            } else if (selectedRow != null &&
                                selectedCol != null &&
                                validMoves[row][col]) {
                              String piece1 = position[row][col];
                              print(
                                  "Moved to row: $row, col: $col, captured: $piece1");

                              // If a piece is selected and the tapped tile is a valid move, move the piece
                              // movePiece(selectedRow!, selectedCol!, row, col);
                              movePiece(
                                  selectedRow!, selectedCol!, row, col, piece);
                            } else {
                              // If tapped on an empty square, an opponent's piece, or an invalid move, deselect
                              setState(() {
                                selectedRow = null;
                                selectedCol = null;
                                resetValidMoves();
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                  color:
                                      tileColor), // Background color for the tile
                              if (piece.isNotEmpty &&
                                  pieceImages.containsKey(piece))
                                Center(
                                  child: Image.asset(
                                    pieceImages[piece]!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
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
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                ],
              ),
            );
          }),
          _buildPlayerInfo(bottomPlayer, bottomTimer,
              playerNextId == bottomPlayer['playerId']),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Move History:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Horizontal Scrollable Row of Moves
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: moveList.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${moveList[index]}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
          // _buildMoveHistory(),
        ],
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

  @override
  void dispose() {
    socket?.off("playerWon");
    socket?.off("JoinStatus");
    socket?.off("timerIs60");
    socket?.off("abort");
    socket?.off("roomLeftPlayerId");
    socket?.off("checkMate");
    socket?.off("DrawStatus");
    socket?.off("ThreeFold");
    socket?.off("fiveFoldData");
    socket?.off("receive_message");
    socket?.off("rematchResponse");
    socket?.off("rematch");
    socket?.off("turnBackStatus");
    socket?.off("allBoardData");
    socket?.off("castingStatus");
    socket?.disconnect();
    super.dispose();
  }

  Widget buildPromotionMenu(int toRow, int toCol, String colorPrefix) {
    return PopupMenuButton<String>(
      onSelected: (String result) {
        setState(() {
          position[toRow][toCol] = '$colorPrefix$result';
        });
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'q',
          child: Image.asset(pieceImages['$colorPrefix' 'q']!),
        ),
        PopupMenuItem<String>(
          value: 'r',
          child: Image.asset(pieceImages['$colorPrefix' 'r']!),
        ),
        PopupMenuItem<String>(
          value: 'b',
          child: Image.asset(pieceImages['$colorPrefix' 'b']!),
        ),
        PopupMenuItem<String>(
          value: 'n',
          child: Image.asset(pieceImages['$colorPrefix' 'n']!),
        ),
      ],

      offset: const Offset(0, -200), // Show the menu above the square
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      elevation: 8,
      child: Container(
        width: 40,
        height: 40,
        color: Colors.transparent,
        child: const Center(
          child: Text(
            "Pawn Promotion",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
