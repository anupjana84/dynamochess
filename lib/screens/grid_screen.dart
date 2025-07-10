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

  // New getter to convert to algebraic notation
  String get algebraic {
    if (row < 0 || row >= 10 || col < 0 || col >= 10) {
      return 'Invalid'; // Should not happen with valid game logic
    }
    // 'a' for col 0, 'b' for col 1, etc.
    final colChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    // For a 10x10 board, row 0 (top) is rank 10, row 9 (bottom) is rank 1
    final rowNum = 10 - row;
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
  late List<List<String>> position;
  int? selectedRow;
  int? selectedCol;
  bool isWhiteTurn = true;
  io.Socket? socket;

  //
  var timer1;
  var timer2;

  // Booleans
  bool isSound = true;
  bool isNavigation = true;
  bool gameAborted = false;
  bool leaveRoom = false;
  bool leave = false;

  // Lists
  List<dynamic> players = [];

  // Strings
  String playernextTurn = "";
  String playernextId = "";

  var newBoardData = [];
  var movePosition = '';

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
  List<String> moveList = [];

  String? gameStatus;
  bool showboard = false;
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
      'autoConnect': false,
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
      // print("initialBoard ${initialBoard}");
      // showboard = true;
      // position = createPositionfirst(initialBoard);
      // final String opponentPlayerId = data['positions'][0]['playerId']; // This is not directly used for board setup here

      setState(() {
        //startGame = true;
        // isPopupDisabled = true; // Hide "Please wait" popup
        // Set the current player ID based on who is 'w' or 'b'
        // This logic needs to match the backend's assignment of 'w' and 'b'
        // if (players.isNotEmpty && _currentUserDetail != null) {
        // Here, we assume 'players' list is populated correctly and contains the color for the current user
        // final currentPlayerAssignedColor = players.firstWhere(
        //    (p) => p['playerId'] == _currentUserDetail!.id,
        //   orElse: () => {'colour': 'w'})['colour'];

        // The backend sends the board from white's perspective.
        // If current user is black, reverse the board for display.
        //  if (currentPlayerAssignedColor == 'b') {
        //   board = _convertBackendBoard(initialBoard, reverse: true);
        //  } else {
        //   board = _convertBackendBoard(initialBoard, reverse: false);
        // }
        //    }
        // Initialize playerNextId and playerNextTurnColor based on the start of the game
        // Usually, white starts, so 'w' and the ID of the white player
        // playerNextId = players.firstWhere((p) => p['colour'] == 'w',
        //         orElse: () => {})['playerId'] ??
        //     '';
        // playerNextTurnColor = 'w';
      });
    });

    socket?.on('receive_boardData', (data) {
      final List<dynamic> newPositionData = data['data']['newPosition'];
      debugPrint("newPositionData $newPositionData");
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
        if (newPositionData.isNotEmpty) {
          bool isCurrentUserBlack = players.isNotEmpty &&
              players.any((p) =>
                  p['playerId'] == _currentUserDetail?.id &&
                  p['colour'] == 'w');
          print("isCurrentUserBlack $isCurrentUserBlack");
          position = _convertBackendBoard(newPositionData,
              reverse: isCurrentUserBlack);
          isWhiteTurn = true;
        }
      });
    });

    socket?.on('updatedRoom', (data) {
      // print("updatedRoom $data");
      print('Updated Room: allBoardData: ${data['allBoardData']}');
      // roomId = data['_id'];
      // List<dynamic>? playersData = data['players'];
      // print("playersData $playersData");
      // List<dynamic>? newMoveList = data['moveList'];
      // print("newMoveList $newMoveList");
      // List<dynamic>? allBoardData = data['allBoardData'];
      // print("allBoardData $allBoardData");
      // List<List<dynamic>> newPosition = [];
      // if (allBoardData != null) {
      //   newPosition = allBoardData.map((item) {
      //     List<dynamic> pos = item['newPosition'] ?? [];
      //     return List<dynamic>.from(pos); // Copy list
      //   }).toList();
      // }
      // print("newPosition $newPosition");
      // String? nextPlayerColor = data['nextPlayerColor'];
      // int timer1InSeconds = data['timer1'] ?? 0;
      // int timer2InSeconds = data['timer2'] ?? 0;

      // print("timer1InSeconds $timer1InSeconds");
      // print("timer2InSeconds $timer2InSeconds");
      // print("nextPlayerColor $nextPlayerColor");

      // if (newPosition.isNotEmpty &&
      //     playersData != null &&
      //     playersData.length >= 2) {
      //   var player1 = playersData[0];
      //   var player2 = playersData[1];

      //   String? userId =
      //       _currentUserDetail?.id; // Replace with actual user ID getter

      //   bool isCurrentUser(dynamic player) {
      //     return player['playerId'] == userId;
      //   }

      //   // Determine board update logic based on color and current user
      //   if (player1['colour'] == "b") {
      //     if (isCurrentUser(player1)) {
      //       // Player 1 (Black) is current user
      //       List<List<dynamic>> reversePosition = newPosition
      //           .map((item) => List<dynamic>.from(item.reversed))
      //           .toList();

      //       final List<dynamic> latestBoardData =
      //           data['allBoardData'].last['newPosition'];

      //       print("reversePosition hhh: $reversePosition");
      //       position = _convertBackendBoard(latestBoardData, reverse: true);
      //       // dispatch(setPlayerId(player1['playerId']));
      //       // dispatch(UpdateBoard(reversePosition, newMoveList, nextPlayerColor));
      //     } else if (isCurrentUser(player2) && player2['colour'] == "w") {
      //       // Player 2 (White) is current user
      //       //  dispatch(UpdateBoard(newPosition, newMoveList, nextPlayerColor));
      //     }
      //   } else {
      //     // Player 1 is white
      //     if (isCurrentUser(player1)) {
      //       // dispatch(UpdateBoard(newPosition, newMoveList, nextPlayerColor));
      //     } else if (isCurrentUser(player2) && player2['colour'] == "b") {
      //       List<List<dynamic>> reversePosition = newPosition
      //           .map((item) => List<dynamic>.from(item.reversed))
      //           .toList();
      //       final List<dynamic> latestBoardData =
      //           data['allBoardData'].last['newPosition'];
      //       print("reversePosition ggg: $reversePosition");
      //       position = _convertBackendBoard(reversePosition, reverse: false);
      //       // dispatch(setPlayerId(player2['playerId']));
      //       //dispatch(UpdateBoard(reversePosition, newMoveList, nextPlayerColor));
      //     }
      //   }
      // }

      setState(() {
        players = List<Map<String, dynamic>>.from(data['players']);
        moveList = List<String>.from(data['moveList'] ?? []);

        if (data['allBoardData'] != null && data['allBoardData'].isNotEmpty) {
          final List<dynamic> latestBoardData =
              data['allBoardData'].last['newPosition'];
          print("object $latestBoardData");

          bool isCurrentUserBlack = players.isNotEmpty &&
              players.any((p) =>
                  p['playerId'] == _currentUserDetail?.id &&
                  p['colour'] == 'w');
          print("isCurrentUserBlack $isCurrentUserBlack");
          position = _convertBackendBoard(latestBoardData,
              reverse: isCurrentUserBlack);
          isWhiteTurn = isCurrentUserBlack;
        }

        showboard = true;
      });
    });

    socket?.on('startGame', (data) {
      print(data);
      setState(() {
        // startGame = data['start'];
        // isPopupDisabled = true; // Hide "Please wait" popup
        // });
      });

      socket?.on('timer1', (data) {
        setState(() {
          //   timer1 = data;
        });
      });

      socket?.on('timer2', (data) {
        setState(() {
          // timer2 = data;
        });
      });

      socket?.on('nextPlayerTurn', (data) {
        setState(() {
          playerNextTurnColor = data['playerColour'];
          playerNextId = data['playerId'];
          //  gameStatus =
          // '${playerNextTurnColor == 'w' ? 'White' : 'Black'}\'s turn';
        });
      });

      socket?.on('playerWon', (data) {
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
    print("Current Board State:");
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
        // Changed direction for pawns: white moves up (decreasing row), black moves down (increasing row)
        int direction = isWhite ? -1 : 1;
        // Move forward
        if (row + direction >= 0 && row + direction < 10) {
          if (position[row + direction][col].isEmpty) {
            validMoves[row + direction][col] = true;
            // First move can be up to 3 squares
            // Adjusted starting rows for initial 3-square move
            if ((isWhite && row == 8) || (!isWhite && row == 1)) {
              int maxSteps = 3;
              for (int steps = 2; steps <= maxSteps; steps++) {
                if (row + steps * direction >= 0 &&
                    row + steps * direction < 10 &&
                    position[row + steps * direction][col].isEmpty) {
                  validMoves[row + steps * direction][col] = true;
                } else {
                  break; // Stop if there's a piece in the way
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

  void movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    print("Moving piece from ($fromRow, $fromCol) to ($toRow, $toCol)");
    setState(() {
      position[toRow][toCol] = position[fromRow][fromCol];
      position[fromRow][fromCol] = '';
      // isWhiteTurn = isWhiteTurn; // Toggle turn
      selectedRow = null; // Deselect piece
      selectedCol = null; // Deselect piece
      resetValidMoves(); // Clear valid moves highlights
      selectedPosition = Position(toRow, toCol);
      final move = toAlgebraicNotation(fromRow, fromCol);
      final boardd = printBoardState();

      newBoardData = boardd;
      movePosition = move;
    });
    if (socket != null && roomId != null && _currentUserDetail != null) {
      // print("newBoardData ${newBoardData} movePosition ${movePosition}");
      // List<List<dynamic>> reversePosition = newBoardData
      //     .map((item) => item.reversed.toList())
      //     .toList()
      //     .cast<List<dynamic>>();
      final ddddd = printBoardState().reversed.toList();

      print("reversePosition ${ddddd}");

      socket?.emit('boardUpdate', {
        'roomId': roomId,
        'boardData': {"newPosition": ddddd},
        'playerId': _currentUserDetail!.id,
        'move': movePosition,
      });
    }
    // print(
    //     "Moving piece ${newBoardData} ${movePosition} from ${toAlgebraicNotation(fromRow, fromCol)} to ${toAlgebraicNotation(toRow, toCol)}");
    // // printBoardState(); // Print the updated board state to console
  }

  String toAlgebraicNotation(int row, int col) {
    // Convert column to letter (0-9 -> a-j)
    String columnLetter = String.fromCharCode('a'.codeUnitAt(0) + col);

    // Convert row to number (0-9 -> 10-1)
    // Since row 0 is the "first rank" (like standard chess)
    int rowNumber = 10 - row;

    return '$columnLetter$rowNumber';
  }

  Position fromAlgebraicNotation(String notation) {
    if (notation.length < 2) return Position(-1, -1); // Invalid

    // Get column (letter)
    String colChar = notation.substring(0, 1).toLowerCase();
    int col = colChar.codeUnitAt(0) - 'a'.codeUnitAt(0);

    // Get row (number)
    int rowNumber = int.tryParse(notation.substring(1)) ?? 0;
    int row = 10 - rowNumber;

    return Position(row, col);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isWhiteTurn ? 'White\'s Turn grid' : 'Black\'s Turn'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
        ),
        itemCount: 100, // 10x10 board
        itemBuilder: (context, index) {
          int row = index ~/ 10;
          int col = index % 10;
          String piece = position[row][col];
          bool isSelected = selectedRow == row && selectedCol == col;
          bool isValidMove = validMoves[row][col];

          Color tileColor = (row + col) % 2 == 0
              ? Colors.brown[300]!
              : Colors.white; // Chessboard pattern
          if (isSelected)
            tileColor = Colors.yellowAccent; // Highlight selected piece
          if (isValidMove)
            tileColor = Colors.lightGreenAccent; // Highlight valid moves

          return showboard
              ? GestureDetector(
                  onTap: () {
                    if (piece.isNotEmpty &&
                        piece[0] == (isWhiteTurn ? 'w' : 'b')) {
                      // If a piece of the current player's color is tapped, select it
                      setState(() {
                        selectedRow = row;
                        selectedCol = col;
                        calculateValidMoves(
                            row, col); // Calculate its valid moves
                      });
                    } else if (selectedRow != null &&
                        selectedCol != null &&
                        validMoves[row][col]) {
                      // If a piece is selected and the tapped tile is a valid move, move the piece
                      movePiece(selectedRow!, selectedCol!, row, col);
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
                          color: tileColor), // Background color for the tile
                      if (piece.isNotEmpty && pieceImages.containsKey(piece))
                        Center(
                          child: Image.asset(
                            pieceImages[piece]!,
                            fit: BoxFit.contain,
                          ),
                        ),
                    ],
                  ),
                )
              : null;
        },
      ),
    );
  }
}
