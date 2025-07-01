import 'package:dynamochess/utils/api_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket socket;

  //
  String? playerId;
  String? userName;
  String? userProfileImage;
  double? userRating;
  String? countryIcon;
  String? dynamoCoin;
  List<List<bool>> validMoves =
      List.generate(10, (_) => List.filled(10, false));

  @override
  void initState() {
    super.initState();
    position = createPosition();
    _loadUserData().then((_) {
      if (playerId != null) {
        connectToSocket();
      } else {
        Get.snackbar("Error", "User not logged in");
        // Get.offAllNamed('/login');
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      playerId = prefs.getString('_id');
      userName = prefs.getString('name');
      userProfileImage = prefs.getString('profileImageUrl');
      userRating = prefs.getDouble('rating');
      countryIcon = prefs.getString('countryIcon');
      dynamoCoin = prefs.getString('ountryIcon');
    });
    print(playerId);
  }

  void _joinRoom() {
    print(playerId);
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
      // socket.on('updatedRoom', (data) {
      //   print('Room updated: $data');
      //   // Save roomId, update UI, etc.
      // });

      // socket.on("updatedRoom", (data) {
      //   final dd = data?._id;
      //   debugPrint("updatedRoom");
      //   debugPrint("data ${dd}");
      //   debugPrint("updatedRoom");
      // });
    });

    socket.on("updatedRoom", (data) {
      if (data is Map<String, dynamic>) {
        // Check if data is a map
        final String? roomId =
            data['_id'] as String?; // Access '_id' as a string
        debugPrint("updatedRoom");
        debugPrint("Room ID: $roomId"); // Now you can print the roomId
        debugPrint(
            "Full data: $data"); // Print the entire map to see its structure
        debugPrint("updatedRoom");

        // You can also access other properties if they exist in the 'data' map
        // For example:
        // final List<dynamic>? players = data['players'] as List<dynamic>?;
        // if (players != null) {
        //   debugPrint("Players: $players");
        // }
      } else {
        debugPrint("updatedRoom: Received data is not a map: $data");
      }
    });
    // socket.('')
    // socket.emit("boardUpdate");
    socket.on("reJoinRoomData", (roomData) {
      setState(() {
        // final players = roomData['players'];
        // for (var p in players) {
        //   if (p['playerId'] == playerId) {
        //     playerColor = p['colour'];
        //     break;
        //   }
        // }

        final data = List<List<String>>.from(
          (roomData['allBoardData'].last['newPosition'] as List)
              .map((row) => List<String>.from(row as List)),
        );
        // board = playerColor == 'w' ? data : reverseBoard(data);
        // roomCode = roomData['_id'];
        // currentTurnColor = roomData['turn']; // Get current turn on rejoin
        // isJoined = true;
        // isInitialized = true;
        // isKingInCheckFlag = isKingInCheck(board, playerColor);
        // debugPrint(
        //     "Rejoined room: $roomCode. My color: $playerColor. Turn: $currentTurnColor");
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
        // currentTurnColor =
        //     data; // Ensure this data is just the color 'w' or 'b'
        // debugPrint("It's $currentTurnColor's turn.");
      });
    });

    socket.on("gameEnded", (data) {
      setState(() {
        // isGameOver = true;
        // gameResult = data['message'] ?? "Game Over!";
      });
    });
  }

  void resetValidMoves() {
    validMoves = List.generate(10, (_) => List.filled(10, false));
  }

  void printBoardState() {
    print("Current Board State:");
    for (int i = 0; i < 10; i++) {
      String row = "";
      for (int j = 0; j < 10; j++) {
        String piece = position[i][j];
        row += piece.isEmpty ? ".. " : "${piece} ";
      }
      print(row);
    }
    print(""); // Empty line for separation
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
    setState(() {
      position[toRow][toCol] = position[fromRow][fromCol];
      position[fromRow][fromCol] = '';
      isWhiteTurn = !isWhiteTurn; // Toggle turn
      selectedRow = null; // Deselect piece
      selectedCol = null; // Deselect piece
      resetValidMoves(); // Clear valid moves highlights
    });
    print("Piece moved from ($fromRow, $fromCol) to ($toRow, $toCol)");
    printBoardState(); // Print the updated board state to console
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

          return GestureDetector(
            onTap: () {
              if (piece.isNotEmpty && piece[0] == (isWhiteTurn ? 'w' : 'b')) {
                // If a piece of the current player's color is tapped, select it
                setState(() {
                  selectedRow = row;
                  selectedCol = col;
                  calculateValidMoves(row, col); // Calculate its valid moves
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
                Container(color: tileColor), // Background color for the tile
                if (piece.isNotEmpty && pieceImages.containsKey(piece))
                  Center(
                    child: Image.asset(
                      pieceImages[piece]!,
                      fit: BoxFit.contain,
                    ),
                  ),
                // Optional: Display coordinates for debugging
                // Positioned(
                //   bottom: 2,
                //   right: 2,
                //   child: Text('$row,$col', style: TextStyle(fontSize: 8, color: Colors.grey[700])),
                // )
              ],
            ),
          );
        },
      ),
    );
  }
}
