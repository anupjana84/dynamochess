import 'package:flutter/material.dart';

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
}

class ChessPiece {
  final PieceColor color;
  final PieceType type;
  final String symbol;
  final String name;

  ChessPiece(this.color, this.type)
      : symbol = _getSymbol(type, color),
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

class ChessBoardScreen extends StatefulWidget {
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
      PieceType.rook, // 1st (col 0)
      PieceType.knight, // 2nd (col 1)
      PieceType.bishop, // 3rd (col 2)
      PieceType.missile, // 4th (col 3) ✅
      PieceType.queen, // 5th (col 4)
      PieceType.king, // 6th (col 5)
      PieceType.missile, // 7th (col 6) ✅
      PieceType.bishop, // 8th (col 7)
      PieceType.knight, // 9th (col 8)
      PieceType.rook // 10th (col 9)
    ];

    final whitePiecesOrder = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.missile, // 4th (col 3) ✅
      PieceType.king,
      PieceType.queen,
      PieceType.missile, // 7th (col 6) ✅
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
        title: Text('10x10 Chess with Missiles'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final boardDimension = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          return SizedBox(
            width: boardDimension,
            height: boardDimension,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                      color:
                          _getSquareColor(row, col, isSelected, isPossibleMove),
                      border: Border.all(color: Colors.black54, width: 0.5),
                    ),
                    child: Center(
                      child: piece != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  piece.symbol,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: piece.color == PieceColor.white
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                if (piece.type == PieceType.missile)
                                  Text(
                                    'Missile',
                                    style: TextStyle(
                                      fontSize: 7,
                                      color: piece.color == PieceColor.white
                                          ? Colors.white
                                          : Colors.black,
                                    ),
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
    );
  }

  Color _getSquareColor(
      int row, int col, bool isSelected, bool isPossibleMove) {
    if (isSelected) return Colors.blue[400]!;
    if (isPossibleMove) return Colors.blue[200]!;
    return (row + col) % 2 == 0 ? Colors.brown[300]! : Colors.brown[100]!;
  }

  void _handleTap(int row, int col) {
    final piece = board[row][col];
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

  void _movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    setState(() {
      final capturedPiece = board[toRow][toCol];
      if (capturedPiece != null) {
        gameStatus =
            '${currentPlayer == PieceColor.white ? 'White' : 'Black'} captured ${capturedPiece.name}';
      } else {
        gameStatus =
            '${currentPlayer == PieceColor.white ? 'White' : 'Black'}\'s turn';
      }
      board[toRow][toCol] = board[fromRow][fromCol];
      board[fromRow][fromCol] = null;
      selectedPosition = null;
      possibleMoves = [];
      currentPlayer = currentPlayer == PieceColor.white
          ? PieceColor.black
          : PieceColor.white;
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
    if (_isValidPosition(row + direction, col) &&
        board[row + direction][col] == null) {
      moves.add(Position(row + direction, col));
      if ((color == PieceColor.white && row == boardSize - 2) ||
          (color == PieceColor.black && row == 1)) {
        if (board[row + 2 * direction][col] == null) {
          moves.add(Position(row + 2 * direction, col));
        }
      }
    }
    for (final colOffset in [-1, 1]) {
      final newCol = col + colOffset;
      if (newCol >= 0 &&
          newCol < boardSize &&
          _isValidPosition(row + direction, newCol) &&
          board[row + direction][newCol] != null &&
          board[row + direction][newCol]!.color != color) {
        moves.add(Position(row + direction, newCol));
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
      board = List.generate(boardSize, (i) => List.filled(boardSize, null));
      _initializeBoard();
      currentPlayer = PieceColor.white;
      selectedPosition = null;
      possibleMoves = [];
      gameStatus = 'White\'s turn';
    });
  }
}
