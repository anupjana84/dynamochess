import 'package:flutter/material.dart';

class Position {
  final int row;
  final int col;
  final bool isBlackAtBottom;

  const Position(this.row, this.col, {this.isBlackAtBottom = false});

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
    final rowNum = isBlackAtBottom ? row + 1 : 10 - row;
    return '$colChar$rowNum';
  }
}

List<List<String>> createPosition({bool isBlackAtBottom = false}) {
  List<List<String>> position = List.generate(10, (_) => List.filled(10, ''));

  // Always use standard positioning - the visual flip is handled in the display
  // Black pieces always on rows 0-1, White pieces always on rows 8-9

  // Place pawns
  for (int i = 0; i < 10; i++) {
    position[1][i] = 'bp'; // Black pawns on row 1
    position[8][i] = 'wp'; // White pawns on row 8
  }

  // Black pieces on row 0 (back rank)
  position[0][0] = 'br';
  position[0][1] = 'bn';
  position[0][2] = 'bb';
  position[0][3] = 'bm';
  position[0][4] = 'bq';
  position[0][5] = 'bk';
  position[0][6] = 'bm';
  position[0][7] = 'bb';
  position[0][8] = 'bn';
  position[0][9] = 'br';

  // White pieces on row 9 (back rank)
  position[9][0] = 'wr';
  position[9][1] = 'wn';
  position[9][2] = 'wb';
  position[9][3] = 'wm';
  position[9][4] = 'wq';
  position[9][5] = 'wk';
  position[9][6] = 'wm';
  position[9][7] = 'wb';
  position[9][8] = 'wn';
  position[9][9] = 'wr';

  return position;
}

// Fallback piece symbols for when images aren't available
const Map<String, String> pieceSymbols = {
  'bp': '♟',
  'br': '♜',
  'bn': '♞',
  'bb': '♝',
  'bq': '♛',
  'bk': '♚',
  'bm': '🚀',
  'wp': '♙',
  'wr': '♖',
  'wn': '♘',
  'wb': '♗',
  'wq': '♕',
  'wk': '♔',
  'wm': '🚀',
};

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

  List<List<bool>> validMoves =
      List.generate(10, (_) => List.filled(10, false));

  @override
  void initState() {
    super.initState();
    isBlackAtBottom = widget.isBlackAtBottom;
    position = createPosition(isBlackAtBottom: isBlackAtBottom);
    isWhiteTurn = true; // White always starts
  }

  void resetValidMoves() {
    validMoves = List.generate(10, (_) => List.filled(10, false));
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
    // Pawn movement is always the same regardless of board orientation
    // White pawns move toward row 0, Black pawns move toward row 9
    int direction = isWhite ? -1 : 1;
    int startRow = isWhite ? 8 : 1;

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

  void movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    String piece = position[fromRow][fromCol];
    String capturedPiece = position[toRow][toCol];

    // Create move notation
    Position fromPos =
        Position(fromRow, fromCol, isBlackAtBottom: isBlackAtBottom);
    Position toPos = Position(toRow, toCol, isBlackAtBottom: isBlackAtBottom);
    String moveNotation = '${fromPos.algebraic}-${toPos.algebraic}';
    if (capturedPiece.isNotEmpty) {
      moveNotation += ' (captured ${capturedPiece.toUpperCase()})';
    }

    setState(() {
      position[toRow][toCol] = piece;
      position[fromRow][fromCol] = '';
      selectedRow = null;
      selectedCol = null;
      resetValidMoves();
      isWhiteTurn = !isWhiteTurn;
      moveHistory.add(moveNotation);
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
    });
  }

  Widget _buildPieceWidget(String piece) {
    if (piece.isEmpty) return const SizedBox();

    return Image.asset(
      pieceImages[piece]!,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text symbols if image fails to load
        return Text(
          pieceSymbols[piece] ?? piece,
          style: const TextStyle(fontSize: 24),
        );
      },
    );
  }

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
                // Calculate row and col based on board orientation
                int displayRow, displayCol;
                if (isBlackAtBottom) {
                  // Flip the board: bottom-left becomes top-right
                  displayRow = 9 - (index ~/ 10);
                  displayCol = 9 - (index % 10);
                } else {
                  // Standard orientation
                  displayRow = index ~/ 10;
                  displayCol = index % 10;
                }

                int row = displayRow;
                int col = displayCol;
                String piece = position[row][col];
                bool isSelected = selectedRow == row && selectedCol == col;
                bool isValidMove = validMoves[row][col];

                Color tileColor = ((displayRow + displayCol) % 2 == 0)
                    ? const Color(0xFFDCDA5C)
                    : const Color(0xFF769656);

                if (isSelected) {
                  tileColor = Colors.yellowAccent;
                } else if (isValidMove) {
                  tileColor = Colors.lightGreenAccent;
                }

                return GestureDetector(
                  onTap: () {
                    if (selectedRow != null &&
                        selectedCol != null &&
                        isValidMove) {
                      // Make the move
                      movePiece(selectedRow!, selectedCol!, row, col);
                    } else if (piece.isNotEmpty) {
                      // Check if it's the correct player's turn
                      bool isPieceWhite = piece.startsWith('w');
                      if (isPieceWhite == isWhiteTurn) {
                        setState(() {
                          selectedRow = row;
                          selectedCol = col;
                          calculateValidMoves(row, col);
                        });
                      } else {
                        // Show message for wrong turn
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'It\'s ${isWhiteTurn ? 'White' : 'Black'}\'s turn!'),
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
                          Center(child: _buildPieceWidget(piece)),
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
            child: Text(
              'Turn: ${isWhiteTurn ? 'White' : 'Black'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Board
          Expanded(child: _buildBoard()),
          // Move history
          if (moveHistory.isNotEmpty)
            Container(
              height: 80,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last moves:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: moveHistory.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}. ${moveHistory[index]}',
                            style: const TextStyle(fontSize: 12),
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
