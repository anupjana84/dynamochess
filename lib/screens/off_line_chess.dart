import 'package:dynamochess/utils/api_list.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:audioplayers/audioplayers.dart';

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

  String get algebraic {
    if (row < 0 || row >= 10 || col < 0 || col >= 10) {
      return 'Invalid';
    }
    final colChar = String.fromCharCode('a'.codeUnitAt(0) + col);
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
  final ChessPiece? capturedPiece;

  Move(this.from, this.to, this.movedPiece, this.capturedPiece);
}

// --- OffLineChessScreen Widget ---
class OffLineChessScreen extends StatefulWidget {
  const OffLineChessScreen({super.key});

  @override
  _OffLineChessScreenState createState() => _OffLineChessScreenState();
}

class _OffLineChessScreenState extends State<OffLineChessScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const int boardSize = 10;
  List<List<ChessPiece?>> board =
      List.generate(boardSize, (i) => List.filled(boardSize, null));
  PieceColor currentPlayer = PieceColor.white;
  Position? selectedPosition;
  List<Position> possibleMoves = [];
  String gameStatus = 'White\'s turn';
  io.Socket? socket;

  // --- Move History related variables ---
  List<Move> moveHistory = [];
  int currentMoveIndex = -1; // -1 means no move has been made yet

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _connectSocket();
  }

  void _connectSocket() {
    debugPrint("object");
    socket = io.io(ApiList.baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'reconnection': true,
      'timeout': 20000,
    });
    socket?.connect();
    socket?.onConnect((_) {
      debugPrint('Connected to Socket.IO');
    });
  }

  void _initializeBoard() {
    board = List.generate(boardSize, (i) => List.filled(boardSize, null));
    for (int i = 0; i < boardSize; i++) {
      board[1][i] = ChessPiece(PieceColor.black, PieceType.pawn);
      board[boardSize - 2][i] = ChessPiece(PieceColor.white, PieceType.pawn);
    }

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

    for (int i = 0; i < boardSize; i++) {
      board[0][i] = ChessPiece(PieceColor.black, blackPiecesOrder[i]);
    }

    for (int i = 0; i < boardSize; i++) {
      board[boardSize - 1][i] =
          ChessPiece(PieceColor.white, whitePiecesOrder[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        title: const Text(
          'DYNAMO CHESS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Row(
            children: [
              Text(
                gameStatus,
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  onPressed: _resetGame),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final boardDimension =
                  constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight * 0.5;
              return SizedBox(
                width: boardDimension,
                height: boardDimension,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          shape: _isKingInCheckForPosition(row, col)
                              ? BoxShape.circle
                              : BoxShape.rectangle,
                          border: Border.all(color: Colors.black54, width: 0.5),
                        ),
                        child: Center(
                          child: piece != null
                              ? Image.asset(
                                  _getPieceImageAsset(piece),
                                  width: 30,
                                  height: 30,
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
          Expanded(
            child: _buildMoveHistory(),
          ),
        ],
      ),
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
    return 'assets/images/${colorString}_$type.png';
  }

  Color _getSquareColor(
      int row, int col, bool isSelected, bool isPossibleMove) {
    if (isSelected) return Colors.blue[400]!;
    if (isPossibleMove) return Colors.blue[200]!;

    final piece = board[row][col];
    if (piece?.type == PieceType.king &&
        piece?.color == currentPlayer &&
        _isKingInCheck(piece!.color)) {
      return Colors.red;
    }
    return (row + col) % 2 == 0 ? const Color(0xFFDCDA5C) : Colors.green;
  }

  void _handleTap(int row, int col) {
    final piece = board[row][col];
    if (currentMoveIndex != moveHistory.length - 1) {
      setState(() {
        gameStatus = 'Return to present to make a new move.';
      });
      return;
    }

    if (piece != null && piece.color == currentPlayer) {
      setState(() {
        selectedPosition = Position(row, col);
        possibleMoves = _getValidMoves(row, col); // Only valid moves allowed
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
      final movingPiece = board[fromRow][fromCol];
      final capturedPiece = board[toRow][toCol];
      moveHistory.add(Move(Position(fromRow, fromCol), Position(toRow, toCol),
          movingPiece, capturedPiece));
      currentMoveIndex = moveHistory.length - 1;

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
      // Now get the updated board
      debugPrint("Updated board: $board");

      // If you want to print each row for clarity:
      for (int i = 0; i < board.length; i++) {
        debugPrint("Row $i: ${board[i]}");
      }
      board[fromRow][fromCol] = null;
      selectedPosition = null;
      possibleMoves = [];
      currentPlayer = currentPlayer == PieceColor.white
          ? PieceColor.black
          : PieceColor.white;

      _checkPawnPromotion(toRow, toCol);
      _checkMissileCaptureWin();
      _checkMissileMate();
      _playMoveSound();
    });
  }

  void _checkPawnPromotion(int row, int col) {
    final piece = board[row][col];
    print(board[row][col]);
    print("piece ${piece}");
    if (piece?.type == PieceType.pawn && (row == 0 || row == boardSize - 1)) {
      board[row][col] = ChessPiece(piece!.color, PieceType.missile);
      gameStatus = 'Pawn promoted to Missile!';
    }
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
    _checkCastling(row, col, color, moves);
  }

  void _checkCastling(
      int row, int col, PieceColor color, List<Position> moves) {
    final rank = color == PieceColor.white ? boardSize - 1 : 0;
    if (row != rank || selectedPosition != null) return;

    // Kingside castling
    if (board[row][col + 1] == null &&
        board[row][col + 2] == null &&
        board[row][col + 3]?.type == PieceType.rook &&
        board[row][col + 3]?.color == color) {
      moves.add(Position(row, col + 3));
    }

    // Queenside castling
    if (board[row][col - 1] == null &&
        board[row][col - 2] == null &&
        board[row][col - 3] == null &&
        board[row][col - 4]?.type == PieceType.rook &&
        board[row][col - 4]?.color == color) {
      moves.add(Position(row, col - 4));
    }
  }

  void _castle(int kingRow, int kingCol, int rookRow, int rookCol) {
    setState(() {
      final isKingside = rookCol > kingCol;
      final kingNewCol = isKingside ? kingCol + 3 : kingCol - 3;
      final rookNewCol = isKingside ? kingCol + 2 : kingCol - 2;
      final movingKing = board[kingRow][kingCol];
      final movingRook = board[rookRow][rookCol];
      board[kingNewCol][kingNewCol] = movingKing;
      board[rookRow][rookNewCol] = movingRook;
      board[kingRow][kingCol] = null;
      board[rookRow][rookCol] = null;
      selectedPosition = null;
      possibleMoves = [];
      currentPlayer = currentPlayer == PieceColor.white
          ? PieceColor.black
          : PieceColor.white;
    });
  }

  void _checkMissileCaptureWin() {
    int whiteMissiles = 0;
    int blackMissiles = 0;
    for (var row in board) {
      for (var piece in row) {
        if (piece?.type == PieceType.missile) {
          if (piece!.color == PieceColor.white)
            whiteMissiles++;
          else
            blackMissiles++;
        }
      }
    }
    if (whiteMissiles == 0) {
      gameStatus = 'Black wins by capturing both Missiles!';
    } else if (blackMissiles == 0) {
      gameStatus = 'White wins by capturing both Missiles!';
    }
  }

  void _checkMissileMate() {
    ChessPiece? missile;
    Position? missilePos;
    ChessPiece? enemyKing;
    Position? enemyKingPos;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final piece = board[r][c];
        if (piece != null) {
          if (piece.type == PieceType.missile) {
            missile = piece;
            missilePos = Position(r, c);
          } else if (piece.type == PieceType.king) {
            enemyKing = piece;
            enemyKingPos = Position(r, c);
          }
        }
      }
    }
    if (missile != null &&
        enemyKing != null &&
        missilePos != null &&
        enemyKingPos != null) {
      final isCorner =
          (enemyKingPos.row == 0 || enemyKingPos.row == boardSize - 1) &&
              (enemyKingPos.col == 0 || enemyKingPos.col == boardSize - 1);
      final distance = (missilePos.row - enemyKingPos.row).abs() +
          (missilePos.col - enemyKingPos.col).abs();
      if (isCorner && distance <= 2) {
        gameStatus =
            '${missile.color == PieceColor.white ? "White" : "Black"} wins with Missile Mate!';
      }
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

  List<Position> _getValidMoves(int row, int col) {
    final piece = board[row][col];
    if (piece == null) return [];

    final rawMoves = _getPossibleMoves(row, col);
    final validMoves = <Position>[];

    for (final move in rawMoves) {
      final capturedPiece = board[move.row][move.col];
      board[move.row][move.col] = piece;
      board[row][col] = null;

      if (!_isKingInCheck(piece.color)) {
        validMoves.add(move);
      }

      board[row][col] = piece;
      board[move.row][move.col] = capturedPiece;
    }

    return validMoves;
  }

  void _getMissileMoves(
      int row, int col, PieceColor color, List<Position> moves) {
    const bishopDirections = [
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1]
    ];
    _getSlidingMoves(row, col, color, bishopDirections, moves);

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

      final bool isStartingWhite = row == boardSize - 2 || row == boardSize - 3;
      final bool isStartingBlack = row == 1 || row == 2;

      if ((color == PieceColor.white && isStartingWhite) ||
          (color == PieceColor.black && isStartingBlack)) {
        if (_isValidPosition(row + 2 * direction, col) &&
            board[row + 2 * direction][col] == null) {
          moves.add(Position(row + 2 * direction, col));
        }
        if (_isValidPosition(row + 3 * direction, col) &&
            board[row + 3 * direction][col] == null) {
          moves.add(Position(row + 3 * direction, col));
        }
      }
    }

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

    for (var colOffset in [-1, 1]) {
      final adjCol = col + colOffset;
      if (adjCol >= 0 && adjCol < boardSize) {
        final enemyPawn = board[row][adjCol];
        if (enemyPawn is ChessPiece &&
            enemyPawn.type == PieceType.pawn &&
            enemyPawn.color != color &&
            enemyPawn.justMovedThreeOrTwoSquares) {
          final enPassantRow = row + (color == PieceColor.white ? -1 : 1);
          final enPassantCol = adjCol;
          if (_isValidPosition(enPassantRow, enPassantCol) &&
              board[enPassantRow][enPassantCol] == null) {
            moves.add(Position(enPassantRow, enPassantCol));
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
      moveHistory.clear();
      currentMoveIndex = -1;
    });
  }

  Widget _buildMoveHistory() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Move History:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                // children: List.generate(
                //   moveHistory.length,
                //   (index) {
                //     final move = moveHistory[index];
                //     final isCurrentMove = index == currentMoveIndex;
                //     return GestureDetector(
                //       onTap: () => _goToMove(index),
                //       child: Container(
                //         decoration: BoxDecoration(
                //           color: isCurrentMove
                //               ? Colors.blue.withOpacity(0.3)
                //               : Colors.transparent,
                //           borderRadius: BorderRadius.circular(4),
                //         ),
                //         padding: const EdgeInsets.symmetric(
                //             vertical: 4, horizontal: 8),
                //         width: MediaQuery.of(context).size.width / 2 - 20,
                //         child: Text(
                //           '${index + 1}. ${move.movedPiece?.name} ${move.movedPiece?.symbol} ${move.from.algebraic} → ${move.to.algebraic}',
                //           style: TextStyle(
                //             fontWeight: isCurrentMove
                //                 ? FontWeight.bold
                //                 : FontWeight.normal,
                //           ),
                //         ),
                //       ),
                //     );
                //   },
                // ),
                children: List.generate(moveHistory.length, (index) {
                  final move = moveHistory[index];
                  final isCurrentMove = index == currentMoveIndex;
                  final notation = getAlgebraicNotation(move);

                  return GestureDetector(
                    onTap: () => _goToMove(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrentMove
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      width: MediaQuery.of(context).size.width / 2 - 20,
                      child: Text(
                        '${index + 1}. $notation',
                        style: TextStyle(
                          fontWeight: isCurrentMove
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: currentMoveIndex > 0 ? _goToPreviousMove : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: currentMoveIndex < moveHistory.length - 1
                    ? _goToNextMove
                    : null,
                child: const Text('Next'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: currentMoveIndex != moveHistory.length - 1 &&
                        moveHistory.isNotEmpty
                    ? _goToLastMove
                    : null,
                child: const Text('Last Move'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPreviousMove() {
    if (currentMoveIndex > 0) {
      setState(() {
        final lastMove = moveHistory[currentMoveIndex];
        board[lastMove.from.row][lastMove.from.col] = lastMove.movedPiece;
        board[lastMove.to.row][lastMove.to.col] = lastMove.capturedPiece;
        currentMoveIndex--;
        currentPlayer = currentPlayer == PieceColor.white
            ? PieceColor.black
            : PieceColor.white;
        gameStatus = 'Viewing past move.';
      });
    }
  }

  void _goToNextMove() {
    if (currentMoveIndex < moveHistory.length - 1) {
      setState(() {
        currentMoveIndex++;
        final nextMove = moveHistory[currentMoveIndex];
        board[nextMove.to.row][nextMove.to.col] = nextMove.movedPiece;
        board[nextMove.from.row][nextMove.from.col] = null;
        currentPlayer = currentPlayer == PieceColor.white
            ? PieceColor.black
            : PieceColor.white;
        gameStatus = 'Viewing past move.';
      });
    } else {
      setState(() {
        gameStatus = currentPlayer == PieceColor.white
            ? 'White\'s turn'
            : 'Black\'s turn';
      });
    }
  }

  void _goToMove(int index) {
    setState(() {
      while (currentMoveIndex > index) _goToPreviousMove();
      while (currentMoveIndex < index) _goToNextMove();
    });
  }

  void _goToLastMove() {
    _goToMove(moveHistory.length - 1);
  }

  bool _isKingInCheck(PieceColor color) {
    Position? kingPos;
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        final piece = board[row][col];
        if (piece?.type == PieceType.king && piece?.color == color) {
          kingPos = Position(row, col);
          break;
        }
      }
      if (kingPos != null) break;
    }
    if (kingPos == null) return false;

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        final piece = board[row][col];
        if (piece != null && piece.color != color) {
          final moves = _getPossibleMoves(row, col);
          if (moves.any(
              (move) => move.row == kingPos!.row && move.col == kingPos.col)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _isKingInCheckForPosition(int row, int col) {
    final piece = board[row][col];
    return piece?.type == PieceType.king &&
        piece?.color == currentPlayer &&
        _isKingInCheck(piece!.color);
  }

  void _playMoveSound() async {
    try {
      await _audioPlayer.play(AssetSource('sound/move.mp3'));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

//
  String getAlgebraicNotation(Move move) {
    final movingPiece = move.movedPiece;
    final capturedPiece = move.capturedPiece;

    String piecePrefix = '';

    if (movingPiece != null && movingPiece.type == PieceType.pawn) {
      // For pawns, use file (column letter) only if there's a capture
      final fromColChar =
          String.fromCharCode('a'.codeUnitAt(0) + move.from.col);
      final toColChar = String.fromCharCode('a'.codeUnitAt(0) + move.to.col);
      if (capturedPiece != null || toColChar != fromColChar) {
        return '${fromColChar}x$toColChar${move.to.algebraic[1]}';
      }
    }

    // If not a pawn, just add normal prefix
    String targetSquare = move.to.algebraic;

    if (capturedPiece != null) {
      return '${piecePrefix}x$targetSquare';
    }

    return '$piecePrefix$targetSquare';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
