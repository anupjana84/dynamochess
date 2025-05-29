import 'package:flutter/material.dart';

// --- Enums ---
enum PieceColor { white, black }

enum PieceType {
  pawn,
  rook,
  knight,
  bishop,
  queen,
  king,
  missile,
}

// --- Position Class ---
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

// --- ChessPiece Class ---
class ChessPiece {
  final PieceColor color;
  final PieceType type;
  final String symbol;
  final String name;

  // Track movement history for pawns (en passant)
  final int enPassantUsedCount;
  final bool justMovedThreeOrTwoSquares;

  ChessPiece(this.color, this.type)
      : symbol = _getSymbol(type, color),
        name = _getName(type),
        enPassantUsedCount = 0,
        justMovedThreeOrTwoSquares = false;

  ChessPiece.withHistory({
    required this.color,
    required this.type,
    required this.enPassantUsedCount,
    required this.justMovedThreeOrTwoSquares,
  })  : symbol = _getSymbol(type, color),
        name = _getName(type);

  static String _getSymbol(PieceType type, PieceColor color) {
    const whitePieces = ['♙', '♖', '♘', '♗', '♕', '♔', '🚀'];
    const blackPieces = ['♟', '♜', '♞', '♝', '♛', '♚', '🚀'];
    final index = type.index;
    return color == PieceColor.white ? whitePieces[index] : blackPieces[index];
  }

  static String _getName(PieceType type) {
    return type.toString().split('.').last;
  }
}

// --- Move Class ---
class Move {
  final Position from;
  final Position to;
  final ChessPiece? movedPiece;
  final ChessPiece? capturedPiece; // To store if a piece was captured

  Move(this.from, this.to, this.movedPiece, this.capturedPiece);
}

// --- OffLineChessScreen Widget ---
class OffLineChessScreen extends StatefulWidget {
  @override
  _OffLineChessScreenState createState() => _OffLineChessScreenState();
}

class _OffLineChessScreenState extends State<OffLineChessScreen> {
  static const int boardSize = 10;
  List<List<ChessPiece?>> board =
      List.generate(boardSize, (i) => List.filled(boardSize, null));
  PieceColor currentPlayer = PieceColor.white;
  Position? selectedPosition;
  List<Position> possibleMoves = [];
  String gameStatus = 'White\'s turn';

  // --- Move History related variables ---
  List<Move> moveHistory = [];
  int currentMoveIndex = -1; // -1 means no move has been made yet
  // --- End Move History related variables ---

  @override
  void initState() {
    super.initState();
    _initializeBoard();
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
      PieceType.missile, // 4th (col 3)
      PieceType.queen,
      PieceType.king,
      PieceType.missile, // 7th (col 6)
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook
    ];

    final whitePiecesOrder = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.missile, // 4th (col 3)
      PieceType.king,
      PieceType.queen,
      PieceType.missile, // 7th (col 6)
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Dynamic Chess'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(child: Text(gameStatus)),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardDimension =
                    constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight;

                return SizedBox(
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
                            border:
                                Border.all(color: Colors.black54, width: 0.5),
                          ),
                          child: Center(
                            child: piece != null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                );
              },
            ),
          ),
          // --- Move History UI ---
          _buildMoveHistory(),
          // --- End Move History UI ---
        ],
      ),
    );
  }

  // --- Helper for Piece Image Assets ---
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

    return assetPath;
  }

  // --- Helper for Square Colors ---
  Color _getSquareColor(
      int row, int col, bool isSelected, bool isPossibleMove) {
    if (isSelected) return Colors.blue[400]!;
    if (isPossibleMove) return Colors.blue[200]!;
    return (row + col) % 2 == 0 ? Colors.yellow : Colors.green;
  }

  // --- Handle Tap on a Square ---
  void _handleTap(int row, int col) {
    final piece = board[row][col];

    // If we are currently viewing a past move, we need to return to the present
    // before allowing new moves.
    if (currentMoveIndex != moveHistory.length - 1) {
      setState(() {
        gameStatus = 'Return to present to make a new move.';
      });
      return;
    }

    if (piece != null && piece.color == currentPlayer) {
      setState(() {
        selectedPosition = Position(row, col);
        possibleMoves = _getPossibleMoves(row, col);
        gameStatus = 'Selected: ${piece.name}';
      });
    } else if (selectedPosition != null) {
      final moveIsValid =
          possibleMoves.any((pos) => pos.row == row && pos.col == col);
      if (moveIsValid) {
        _movePiece(selectedPosition!.row, selectedPosition!.col, row, col);
      }
    }
  }

  // --- Move Piece Logic ---
  void _movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    setState(() {
      final movingPiece = board[fromRow][fromCol];
      final capturedPiece = board[toRow][toCol];

      // Record the move before making it on the board
      moveHistory.add(Move(Position(fromRow, fromCol), Position(toRow, toCol),
          movingPiece, capturedPiece));
      currentMoveIndex =
          moveHistory.length - 1; // Update currentMoveIndex to the latest move

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
      selectedPosition = null;
      possibleMoves = [];
      currentPlayer = currentPlayer == PieceColor.white
          ? PieceColor.black
          : PieceColor.white;
      _checkPawnPromotion(toRow, toCol);
    });
  }

  // --- Pawn Promotion Check ---
  void _checkPawnPromotion(int row, int col) {
    final piece = board[row][col];
    if (piece?.type == PieceType.pawn && (row == 0 || row == boardSize - 1)) {
      board[row][col] = ChessPiece(piece!.color, PieceType.queen);
      gameStatus = 'Pawn promoted to Queen!';
    }
  }

  // --- Get Possible Moves for a Piece ---
  List<Position> _getPossibleMoves(int row, int col) {
    final piece = board[row][col];
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

  // --- Missile Moves ---
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

  // --- Pawn Moves ---
  void _getPawnMoves(int row, int col, PieceColor color, List<Position> moves) {
    final direction = color == PieceColor.white ? -1 : 1;

    // Normal forward move
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

  // --- Rook Moves ---
  void _getRookMoves(int row, int col, PieceColor color, List<Position> moves) {
    const directions = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1]
    ];
    _getSlidingMoves(row, col, color, directions, moves);
  }

  // --- Knight Moves ---
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

  // --- Bishop Moves ---
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

  // --- Queen Moves ---
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

  // --- King Moves ---
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

  // --- Sliding Moves Helper (for Rook, Bishop, Queen, Missile) ---
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

  // --- Check if Position is Valid on Board ---
  bool _isValidPosition(int row, int col) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }

  // --- Reset Game ---
  void _resetGame() {
    setState(() {
      board = List.generate(boardSize, (i) => List.filled(boardSize, null));
      _initializeBoard();
      currentPlayer = PieceColor.white;
      selectedPosition = null;
      possibleMoves = [];
      gameStatus = 'White\'s turn';
      moveHistory.clear();
      currentMoveIndex = -1;
    });
  }

  // --- Move History UI ---
  Widget _buildMoveHistory() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            'Move History:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 180, // Adjust height as needed
            child: ListView.builder(
              itemCount: moveHistory.length,
              itemBuilder: (context, index) {
                final move = moveHistory[index];
                final isCurrentMove = index == currentMoveIndex;
                return GestureDetector(
                  onTap: () => _goToMove(index),
                  child: Container(
                    color: isCurrentMove
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      '${index + 1}. ${move.movedPiece?.name} ${move.movedPiece?.symbol}   ${move.to.algebraic}',
                      style: TextStyle(
                        fontWeight:
                            isCurrentMove ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: currentMoveIndex > 0 ? _goToPreviousMove : null,
                child: Text('Previous'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: currentMoveIndex < moveHistory.length - 1
                    ? _goToNextMove
                    : null,
                child: Text('Next'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: currentMoveIndex != moveHistory.length - 1 &&
                        moveHistory.isNotEmpty
                    ? _goToLastMove
                    : null,
                child: Text('Last Move'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Navigate to Previous Move ---
  void _goToPreviousMove() {
    if (currentMoveIndex > 0) {
      setState(() {
        final lastMove = moveHistory[currentMoveIndex];
        // Undo the move
        board[lastMove.from.row][lastMove.from.col] = lastMove.movedPiece;
        board[lastMove.to.row][lastMove.to.col] = lastMove.capturedPiece;
        currentMoveIndex--;
        // Toggle player back
        currentPlayer = currentPlayer == PieceColor.white
            ? PieceColor.black
            : PieceColor.white;
        gameStatus = 'Viewing past move.';
      });
    }
  }

  // --- Navigate to Next Move ---
  void _goToNextMove() {
    if (currentMoveIndex < moveHistory.length - 1) {
      setState(() {
        currentMoveIndex++;
        final nextMove = moveHistory[currentMoveIndex];
        // Redo the move
        board[nextMove.to.row][nextMove.to.col] = nextMove.movedPiece;
        board[nextMove.from.row][nextMove.from.col] = null;
        // Toggle player forward
        currentPlayer = currentPlayer == PieceColor.white
            ? PieceColor.black
            : PieceColor.white;
        gameStatus = 'Viewing past move.';
      });
    } else {
      // If we are at the last move, then we are at the current state of the game
      setState(() {
        gameStatus = currentPlayer == PieceColor.white
            ? 'White\'s turn'
            : 'Black\'s turn';
      });
    }
  }

  // --- Navigate to a Specific Move by Index ---
  void _goToMove(int index) {
    setState(() {
      // If going to a move before the current index, undo moves
      while (currentMoveIndex > index) {
        _goToPreviousMove(); // This will decrement currentMoveIndex
      }
      // If going to a move after the current index, redo moves
      while (currentMoveIndex < index) {
        _goToNextMove(); // This will increment currentMoveIndex
      }
    });
  }

  // --- Navigate to the Last Move (Current Game State) ---
  void _goToLastMove() {
    _goToMove(moveHistory.length - 1);
  }
}
