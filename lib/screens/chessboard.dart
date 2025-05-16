import 'package:dynamochess/screens/chesspiece.dart';
import 'package:flutter/material.dart';

// class ChessBoard extends StatefulWidget {
//   @override
//   _ChessBoardState createState() => _ChessBoardState();
// }

// class _ChessBoardState extends State<ChessBoard> {
//   // 8x8 chess board
//   List<List<ChessPiece?>> board = List.generate(8, (i) => List.filled(8, null));
//   PieceColor currentPlayer = PieceColor.white;
//   Position? selectedPosition;
//   List<Position> possibleMoves = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeBoard();
//   }

//   void _initializeBoard() {
//     // Initialize pawns
//     for (int i = 0; i < 8; i++) {
//       board[1][i] = ChessPiece(PieceColor.black, PieceType.pawn);
//       board[6][i] = ChessPiece(PieceColor.white, PieceType.pawn);
//     }

//     // Initialize other pieces
//     final piecesOrder = [
//       PieceType.rook,
//       PieceType.knight,
//       PieceType.bishop,
//       PieceType.queen,
//       PieceType.king,
//       PieceType.bishop,
//       PieceType.knight,
//       PieceType.rook
//     ];

//     for (int i = 0; i < 8; i++) {
//       board[0][i] = ChessPiece(PieceColor.black, piecesOrder[i]);
//       board[7][i] = ChessPiece(PieceColor.white, piecesOrder[i]);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chess'),
//         actions: [
//           Text(
//               'Current Player: ${currentPlayer == PieceColor.white ? 'White' : 'Black'}'),
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _resetGame,
//           ),
//         ],
//       ),
//       body: Center(
//         child: AspectRatio(
//           aspectRatio: 1,
//           child: GridView.builder(
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 8,
//             ),
//             itemCount: 64,
//             itemBuilder: (context, index) {
//               final row = index ~/ 8;
//               final col = index % 8;
//               final piece = board[row][col];
//               final isSelected =
//                   selectedPosition?.row == row && selectedPosition?.col == col;
//               final isPossibleMove =
//                   possibleMoves.any((pos) => pos.row == row && pos.col == col);

//               return GestureDetector(
//                 onTap: () => _handleTap(row, col),
//                 child: Container(
//                   color: _getSquareColor(row, col, isSelected, isPossibleMove),
//                   child: Center(
//                     child: piece != null
//                         ? Text(
//                             piece.symbol,
//                             style: TextStyle(
//                               fontSize: 30,
//                               color: piece.color == PieceColor.white
//                                   ? Colors.white
//                                   : Colors.black,
//                             ),
//                           )
//                         : null,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getSquareColor(
//       int row, int col, bool isSelected, bool isPossibleMove) {
//     if (isSelected) return Colors.blue;
//     if (isPossibleMove) return Colors.lightBlue;
//     return (row + col) % 2 == 0 ? Colors.brown[300]! : Colors.brown[100]!;
//   }

//   void _handleTap(int row, int col) {
//     final piece = board[row][col];

//     // If a piece of current player's color is tapped
//     if (piece != null && piece.color == currentPlayer) {
//       setState(() {
//         selectedPosition = Position(row, col);
//         possibleMoves = _getPossibleMoves(row, col);
//       });
//     }
//     // If an empty square or opponent's piece is tapped and a piece is selected
//     else if (selectedPosition != null) {
//       final moveIsValid =
//           possibleMoves.any((pos) => pos.row == row && pos.col == col);
//       if (moveIsValid) {
//         _movePiece(selectedPosition!.row, selectedPosition!.col, row, col);
//       }
//     }
//   }

//   void _movePiece(int fromRow, int fromCol, int toRow, int toCol) {
//     setState(() {
//       board[toRow][toCol] = board[fromRow][fromCol];
//       board[fromRow][fromCol] = null;
//       selectedPosition = null;
//       possibleMoves = [];
//       currentPlayer = currentPlayer == PieceColor.white
//           ? PieceColor.black
//           : PieceColor.white;
//     });
//   }

//   List<Position> _getPossibleMoves(int row, int col) {
//     final piece = board[row][col];
//     if (piece == null) return [];

//     final moves = <Position>[];

//     switch (piece.type) {
//       case PieceType.pawn:
//         _getPawnMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.rook:
//         _getRookMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.knight:
//         _getKnightMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.bishop:
//         _getBishopMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.queen:
//         _getQueenMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.king:
//         _getKingMoves(row, col, piece.color, moves);
//         break;
//     }

//     return moves;
//   }

//   // Implement movement rules for each piece type
//   void _getPawnMoves(int row, int col, PieceColor color, List<Position> moves) {
//     final direction = color == PieceColor.white ? -1 : 1;

//     // Forward move
//     if (_isValidPosition(row + direction, col) &&
//         board[row + direction][col] == null) {
//       moves.add(Position(row + direction, col));

//       // Double move from starting position
//       if ((color == PieceColor.white && row == 6) ||
//           (color == PieceColor.black && row == 1)) {
//         if (board[row + 2 * direction][col] == null) {
//           moves.add(Position(row + 2 * direction, col));
//         }
//       }
//     }

//     // Capture moves
//     for (final colOffset in [-1, 1]) {
//       final newCol = col + colOffset;
//       if (newCol >= 0 &&
//           newCol < 8 &&
//           _isValidPosition(row + direction, newCol) &&
//           board[row + direction][newCol] != null &&
//           board[row + direction][newCol]!.color != color) {
//         moves.add(Position(row + direction, newCol));
//       }
//     }
//   }

//   void _getRookMoves(int row, int col, PieceColor color, List<Position> moves) {
//     const directions = [
//       [1, 0],
//       [-1, 0],
//       [0, 1],
//       [0, -1]
//     ];

//     _getSlidingMoves(row, col, color, directions, moves);
//   }

//   void _getKnightMoves(
//       int row, int col, PieceColor color, List<Position> moves) {
//     const knightMoves = [
//       [2, 1],
//       [2, -1],
//       [-2, 1],
//       [-2, -1],
//       [1, 2],
//       [1, -2],
//       [-1, 2],
//       [-1, -2]
//     ];

//     for (final move in knightMoves) {
//       final newRow = row + move[0];
//       final newCol = col + move[1];

//       if (_isValidPosition(newRow, newCol)) {
//         // Corrected: Added missing parenthesis
//         final piece = board[newRow][newCol];
//         if (piece == null || piece.color != color) {
//           moves.add(Position(newRow, newCol));
//         }
//       }
//     }
//   }

//   void _getBishopMoves(
//       int row, int col, PieceColor color, List<Position> moves) {
//     const directions = [
//       [1, 1],
//       [1, -1],
//       [-1, 1],
//       [-1, -1]
//     ];

//     _getSlidingMoves(row, col, color, directions, moves);
//   }

//   void _getQueenMoves(
//       int row, int col, PieceColor color, List<Position> moves) {
//     const directions = [
//       [1, 0],
//       [-1, 0],
//       [0, 1],
//       [0, -1],
//       [1, 1],
//       [1, -1],
//       [-1, 1],
//       [-1, -1]
//     ];

//     _getSlidingMoves(row, col, color, directions, moves);
//   }

//   void _getKingMoves(int row, int col, PieceColor color, List<Position> moves) {
//     for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
//       for (int colOffset = -1; colOffset <= 1; colOffset++) {
//         if (rowOffset == 0 && colOffset == 0) continue;

//         final newRow = row + rowOffset;
//         final newCol = col + colOffset;

//         if (_isValidPosition(newRow, newCol)) {
//           final piece = board[newRow][newCol];
//           if (piece == null || piece.color != color) {
//             moves.add(Position(newRow, newCol));
//           }
//         }
//       }
//     }
//   }

//   void _getSlidingMoves(int row, int col, PieceColor color,
//       List<List<int>> directions, List<Position> moves) {
//     for (final direction in directions) {
//       for (int i = 1; i < 8; i++) {
//         final newRow = row + direction[0] * i;
//         final newCol = col + direction[1] * i;

//         if (!_isValidPosition(newRow, newCol)) break;

//         final piece = board[newRow][newCol];
//         if (piece == null) {
//           moves.add(Position(newRow, newCol));
//         } else {
//           if (piece.color != color) {
//             moves.add(Position(newRow, newCol));
//           }
//           break;
//         }
//       }
//     }
//   }

//   bool _isValidPosition(int row, int col) {
//     return row >= 0 && row < 8 && col >= 0 && col < 8;
//   }

//   void _resetGame() {
//     setState(() {
//       board = List.generate(8, (i) => List.filled(8, null));
//       _initializeBoard();
//       currentPlayer = PieceColor.white;
//       selectedPosition = null;
//       possibleMoves = [];
//     });
//   }
// }

// class Position {
//   final int row;
//   final int col;

//   Position(this.row, this.col);
// }

// class ChessBoardScreen extends StatefulWidget {
//   @override
//   _ChessBoardScreenState createState() => _ChessBoardScreenState();
// }

// class _ChessBoardScreenState extends State<ChessBoardScreen> {
//   static const int boardSize = 10;
//   List<List<ChessPiece?>> board =
//       List.generate(boardSize, (i) => List.filled(boardSize, null));
//   PieceColor currentPlayer = PieceColor.white;
//   Position? selectedPosition;
//   List<Position> possibleMoves = [];
//   String gameStatus = 'White\'s turn';

//   @override
//   void initState() {
//     super.initState();
//     _initializeBoard();
//   }

//   void _initializeBoard() {
//     // Clear the board
//     board = List.generate(boardSize, (i) => List.filled(boardSize, null));

//     // Pawns
//     for (int i = 0; i < boardSize; i++) {
//       board[1][i] = ChessPiece(PieceColor.black, PieceType.pawn);
//       board[boardSize - 2][i] = ChessPiece(PieceColor.white, PieceType.pawn);
//     }

//     // Standard pieces
//     final piecesOrder = [
//       PieceType.rook,
//       PieceType.knight,
//       PieceType.bishop,
//       PieceType.queen,
//       PieceType.king,
//       PieceType.missile,
//       PieceType.bishop,
//       PieceType.knight,
//       PieceType.rook
//     ];

//     // Adjust for 10x10 board (add extra pieces)
//     for (int i = 0; i < boardSize; i++) {
//       if (i < piecesOrder.length) {
//         board[0][i] = ChessPiece(PieceColor.black, piecesOrder[i]);
//         board[boardSize - 1][i] = ChessPiece(PieceColor.white, piecesOrder[i]);
//       } else {
//         // Add extra queens for the 10th column
//         board[0][i] = ChessPiece(PieceColor.black, PieceType.queen);
//         board[boardSize - 1][i] = ChessPiece(PieceColor.white, PieceType.queen);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Custom Chess (10x10)'),
//         actions: [
//           Padding(
//             padding: EdgeInsets.only(right: 20),
//             child: Center(child: Text(gameStatus)),
//             // IconButton(
//             //   icon: Icon(Icons.refresh),
//             //   onPressed: _resetGame,
//             // ),
//           ),
//         ],
//       ),
//     );
//     body:
//     Center(
//       child: AspectRatio(
//         aspectRatio: 1,
//         child: GridView.builder(
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: boardSize,
//           ),
//           itemCount: boardSize * boardSize,
//           itemBuilder: (context, index) {
//             final row = index ~/ boardSize;
//             final col = index % boardSize;
//             final piece = board[row][col];
//             final isSelected =
//                 selectedPosition?.row == row && selectedPosition?.col == col;
//             final isPossibleMove =
//                 possibleMoves.any((pos) => pos.row == row && pos.col == col);

//             return GestureDetector(
//               onTap: () => _handleTap(row, col),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: _getSquareColor(row, col, isSelected, isPossibleMove),
//                   border: Border.all(color: Colors.black54, width: 0.5),
//                 ),
//                 child: Center(
//                   child: piece != null
//                       ? Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               piece.symbol,
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 color: piece.color == PieceColor.white
//                                     ? Colors.white
//                                     : Colors.black,
//                               ),
//                             ),
//                             if (piece.type == PieceType.missile)
//                               Text(
//                                 'Missile',
//                                 style: TextStyle(
//                                   fontSize: 8,
//                                   color: piece.color == PieceColor.white
//                                       ? Colors.white
//                                       : Colors.black,
//                                 ),
//                               ),
//                           ],
//                         )
//                       : null,
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Color _getSquareColor(
//       int row, int col, bool isSelected, bool isPossibleMove) {
//     if (isSelected) return Colors.blue[400]!;
//     if (isPossibleMove) return Colors.blue[200]!;
//     return (row + col) % 2 == 0 ? Colors.brown[300]! : Colors.brown[100]!;
//   }

//   void _handleTap(int row, int col) {
//     final piece = board[row][col];

//     // If a piece of current player's color is tapped
//     if (piece != null && piece.color == currentPlayer) {
//       setState(() {
//         selectedPosition = Position(row, col);
//         possibleMoves = _getPossibleMoves(row, col);
//         gameStatus = 'Selected: ${piece.name}';
//       });
//     }
//     // If an empty square or opponent's piece is tapped and a piece is selected
//     else if (selectedPosition != null) {
//       final moveIsValid =
//           possibleMoves.any((pos) => pos.row == row && pos.col == col);
//       if (moveIsValid) {
//         _movePiece(selectedPosition!.row, selectedPosition!.col, row, col);
//       }
//     }
//   }

//   void _movePiece(int fromRow, int fromCol, int toRow, int toCol) {
//     setState(() {
//       // Check if this is a capture
//       final capturedPiece = board[toRow][toCol];
//       if (capturedPiece != null) {
//         gameStatus =
//             '${currentPlayer == PieceColor.white ? 'White' : 'Black'} captured ${capturedPiece.name}';
//       } else {
//         gameStatus =
//             '${currentPlayer == PieceColor.white ? 'White' : 'Black'}\'s turn';
//       }

//       // Move the piece
//       board[toRow][toCol] = board[fromRow][fromCol];
//       board[fromRow][fromCol] = null;

//       selectedPosition = null;
//       possibleMoves = [];
//       currentPlayer = currentPlayer == PieceColor.white
//           ? PieceColor.black
//           : PieceColor.white;

//       // Check for pawn promotion (for standard pawns)
//       _checkPawnPromotion(toRow, toCol);
//     });
//   }

//   void _checkPawnPromotion(int row, int col) {
//     final piece = board[row][col];
//     if (piece?.type == PieceType.pawn && (row == 0 || row == boardSize - 1)) {
//       // Promote to queen (or let player choose in a more advanced version)
//       board[row][col] = ChessPiece(piece!.color, PieceType.queen);
//       gameStatus = 'Pawn promoted to Queen!';
//     }
//   }

//   List<Position> _getPossibleMoves(int row, int col) {
//     final piece = board[row][col];
//     if (piece == null) return [];

//     final moves = <Position>[];

//     switch (piece.type) {
//       case PieceType.pawn:
//         _getPawnMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.rook:
//         _getRookMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.knight:
//         _getKnightMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.bishop:
//         _getBishopMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.queen:
//         _getQueenMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.king:
//         _getKingMoves(row, col, piece.color, moves);
//         break;
//       case PieceType.missile:
//         _getMissileMoves(row, col, piece.color, moves);
//         break;
//     }

//     return moves;
//   }

//   // Missile piece moves (Bishop + Knight)
//   void _getMissileMoves(
//       int row, int col, PieceColor color, List<Position> moves) {
//     // Bishop moves
//     const bishopDirections = [
//       [1, 1],
//       [1, -1],
//       [-1, 1],
//       [-1, -1]
//     ];
//     _getSlidingMoves(row, col, color, bishopDirections, moves);

//     // Knight moves
//     const knightMoves = [
//       [2, 1],
//       [2, -1],
//       [-2, 1],
//       [-2, -1],
//       [1, 2],
//       [1, -2],
//       [-1, 2],
//       [-1, -2]
//     ];

//     for (final move in knightMoves) {
//       final newRow = row + move[0];
//       final newCol = col + move[1];

//       if (_isValidPosition(newRow, newCol)) {
//         final piece = board[newRow][newCol];
//         if (piece == null || piece.color != color) {
//           moves.add(Position(newRow, newCol));
//         }
//       }
//     }
//   }

//   // Standard piece movement implementations (adjusted for 10x10 board)
//   void _getPawnMoves(int row, int col, PieceColor color, List<Position> moves) {
//     final direction = color == PieceColor.white ? -1 : 1;

//     // Forward move
//     if (_isValidPosition(row + direction, col) &&
//         board[row + direction][col] == null) {
//       moves.add(Position(row + direction, col));

//       // Double move from starting position
//       if ((color == PieceColor.white && row == boardSize - 2) ||
//           (color == PieceColor.black && row == 1)) {
//         if (board[row + 2 * direction][col] == null) {
//           moves.add(Position(row + 2 * direction, col));
//         }
//       }
//     }

//     // Capture moves
//     for (final colOffset in [-1, 1]) {
//       final newCol = col + colOffset;
//       if (newCol >= 0 &&
//           newCol < boardSize &&
//           _isValidPosition(row + direction, newCol) &&
//           board[row + direction][newCol] != null &&
//           board[row + direction][newCol]!.color != color) {
//         moves.add(Position(row + direction, newCol));
//       }
//     }
//   }

//   void _getRookMoves(int row, int col, PieceColor color, List<Position> moves) {
//     const directions = [
//       [1, 0],
//       [-1, 0],
//       [0, 1],
//       [0, -1]
//     ];
//     _getSlidingMoves(row, col, color, directions, moves);
//   }

//   void _getKnightMoves(
//       int row, int col, PieceColor color, List<Position> moves) {
//     const knightMoves = [
//       [2, 1],
//       [2, -1],
//       [-2, 1],
//       [-2, -1],
//       [1, 2],
//       [1, -2],
//       [-1, 2],
//       [-1, -2]
//     ];

//     for (final move in knightMoves) {
//       final newRow = row + move[0];
//       final newCol = col + move[1];

//       if (_isValidPosition(newRow, newCol)) {
//         final piece = board[newRow][newCol];
//         if (piece == null || piece.color != color) {
//           moves.add(Position(newRow, newCol));
//         }
//       }
//     }
//   }

//   void _getBishopMoves(
//       int row, int col, PieceColor color, List<Position> moves) {
//     const directions = [
//       [1, 1],
//       [1, -1],
//       [-1, 1],
//       [-1, -1]
//     ];
//     _getSlidingMoves(row, col, color, directions, moves);
//   }

//   void _getQueenMoves(
//       int row, int col, PieceColor color, List<Position> moves) {
//     const directions = [
//       [1, 0],
//       [-1, 0],
//       [0, 1],
//       [0, -1],
//       [1, 1],
//       [1, -1],
//       [-1, 1],
//       [-1, -1]
//     ];
//     _getSlidingMoves(row, col, color, directions, moves);
//   }

//   void _getKingMoves(int row, int col, PieceColor color, List<Position> moves) {
//     for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
//       for (int colOffset = -1; colOffset <= 1; colOffset++) {
//         if (rowOffset == 0 && colOffset == 0) continue;

//         final newRow = row + rowOffset;
//         final newCol = col + colOffset;

//         if (_isValidPosition(newRow, newCol)) {
//           final piece = board[newRow][newCol];
//           if (piece == null || piece.color != color) {
//             moves.add(Position(newRow, newCol));
//           }
//         }
//       }
//     }
//   }

//   void _getSlidingMoves(int row, int col, PieceColor color,
//       List<List<int>> directions, List<Position> moves) {
//     for (final direction in directions) {
//       for (int i = 1; i < boardSize; i++) {
//         final newRow = row + direction[0] * i;
//         final newCol = col + direction[1] * i;

//         if (!_isValidPosition(newRow, newCol)) break;

//         final piece = board[newRow][newCol];
//         if (piece == null) {
//           moves.add(Position(newRow, newCol));
//         } else {
//           if (piece.color != color) {
//             moves.add(Position(newRow, newCol));
//           }
//           break;
//         }
//       }
//     }
//   }

//   bool _isValidPosition(int row, int col) {
//     return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
//   }

//   void _resetGame() {
//     setState(() {
//       board = List.generate(boardSize, (i) => List.filled(boardSize, null));
//       _initializeBoard();
//       currentPlayer = PieceColor.white;
//       selectedPosition = null;
//       possibleMoves = [];
//       gameStatus = 'White\'s turn';
//     });
//   }
// }
