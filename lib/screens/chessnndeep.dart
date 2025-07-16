// import 'package:flutter/material.dart';

// void toastInfo(String message) {
//   // Toast implementation
// }

// class Position {
//   final int row;
//   final int col;
//   final bool isBlackAtBottom;
//   Position(this.row, this.col, {this.isBlackAtBottom = false});

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is Position &&
//           runtimeType == other.runtimeType &&
//           row == other.row &&
//           col == other.col;

//   @override
//   int get hashCode => row.hashCode ^ col.hashCode;

//   String get algebraic {
//     if (row < 0 || row >= 10 || col < 0 || col >= 10) {
//       return 'Invalid';
//     }
//     final colChar = String.fromCharCode('a'.codeUnitAt(0) + col);
//     final rowNum = isBlackAtBottom ? row + 1 : 10 - row;
//     return '$colChar$rowNum';
//   }
// }

// List<List<String>> createPosition() {
//   List<List<String>> position = List.generate(10, (_) => List.filled(10, ''));

//   // Setup pawns
//   for (int i = 0; i < 10; i++) {
//     position[1][i] = 'bp'; // Black pawns
//     position[8][i] = 'wp'; // White pawns
//   }

//   // Setup black pieces
//   position[0][0] = 'br'; // Rook
//   position[0][1] = 'bn'; // Knight
//   position[0][2] = 'bb'; // Bishop
//   position[0][3] = 'bm'; // missile
//   position[0][4] = 'bq'; // Queen
//   position[0][5] = 'bk'; // King
//   position[0][6] = 'bm'; // missile
//   position[0][7] = 'bb'; // Bishop
//   position[0][8] = 'bn'; // Knight
//   position[0][9] = 'br'; // Rook

//   // Setup white pieces
//   position[9][0] = 'wr'; // Rook
//   position[9][1] = 'wn'; // Knight
//   position[9][2] = 'wb'; // Bishop
//   position[9][3] = 'wm'; // missile
//   position[9][4] = 'wq'; // Queen
//   position[9][5] = 'wk'; // King
//   position[9][6] = 'wm'; // missile
//   position[9][7] = 'wb'; // Bishop
//   position[9][8] = 'wn'; // Knight
//   position[9][9] = 'wr'; // Rook

//   return position;
// }

// const Map<String, String> pieceImages = {
//   'bp': 'assets/ducpices/BLACK/bp2.png',
//   'br': 'assets/ducpices/BLACK/br2.png',
//   'bn': 'assets/ducpices/BLACK/bn.png',
//   'bb': 'assets/ducpices/BLACK/bb.png',
//   'bq': 'assets/ducpices/BLACK/bq2.png',
//   'bk': 'assets/ducpices/BLACK/bk2.png',
//   'bm': 'assets/ducpices/BLACK/bm.png',
//   'wp': 'assets/ducpices/WHITE/wp2.png',
//   'wr': 'assets/ducpices/WHITE/wr2.png',
//   'wn': 'assets/ducpices/WHITE/wn.png',
//   'wb': 'assets/ducpices/WHITE/wb.png',
//   'wq': 'assets/ducpices/WHITE/wq2.png',
//   'wk': 'assets/ducpices/WHITE/wk2.png',
//   'wm': 'assets/ducpices/WHITE/wm.png',
// };

// class GridScreen extends StatefulWidget {
//   const GridScreen({super.key});

//   @override
//   State<GridScreen> createState() => _GridScreenState();
// }

// class _GridScreenState extends State<GridScreen> {
//   late List<List<String>> position;
//   int? selectedRow;
//   int? selectedCol;
//   bool isWhiteTurn = true;
//   List<List<bool>> validMoves = List.generate(10, (_) => List.filled(10, false));
//   Position? selectedPosition;
//   List<dynamic> moveList = [];
//   String? pieceString;
//   bool currentPlayerIsWhite = true;

//   @override
//   void initState() {
//     super.initState();
//     position = createPosition();
//   }

//   void resetValidMoves() {
//     validMoves = List.generate(10, (_) => List.filled(10, false));
//   }

//   void resetBoardWithCustomPosition() {
//     setState(() {
//       // Clear the board
//       position = List.generate(10, (_) => List.filled(10, ''));
      
//       // Add specific pieces at bottom (row 9)
//       position[9][0] = 'wp'; // Pawn at 9,0 (a1)
//       position[9][1] = 'wp'; // Pawn at 9,1 (b1)
//       position[9][2] = 'wr'; // Rook at 9,2 (c1)
//       position[9][3] = 'wn'; // Knight at 9,3 (d1)
//       position[9][4] = 'wb'; // Bishop at 9,4 (e1)
//       position[9][5] = 'wq'; // Queen at 9,5 (f1)
//       position[9][6] = 'wk'; // King at 9,6 (g1)
//       position[9][7] = 'wm'; // Missile at 9,7 (h1)
//       position[9][8] = 'wb'; // Bishop at 9,8 (i1)
//       position[9][9] = 'wn'; // Knight at 9,9 (j1)
      
//       // Reset game state
//       isWhiteTurn = true;
//       selectedRow = null;
//       selectedCol = null;
//       resetValidMoves();
//       moveList.clear();
//     });
//   }

//   // ... [Keep all the existing move calculation methods unchanged] ...

//   void movePiece(int fromRow, int fromCol, int toRow, int toCol, String piece) {
//     bool isCapture = position[toRow][toCol].isNotEmpty;

//     setState(() {
//       position[toRow][toCol] = position[fromRow][fromCol];
//       position[fromRow][fromCol] = '';

//       // Check for pawn promotion
//       String movedPiece = position[toRow][toCol];
//       if (movedPiece == 'wp' && toRow == 0) {
//         _showPromotionDialog(context, toRow, toCol, 'w');
//       } else if (movedPiece == 'bp' && toRow == 9) {
//         _showPromotionDialog(context, toRow, toCol, 'b');
//       }

//       // Update game state
//       selectedRow = null;
//       selectedCol = null;
//       resetValidMoves();
//       isWhiteTurn = !isWhiteTurn;
      
//       // Add to move history
//       moveList.add(generateMoveNotation(
//         fromRow,
//         fromCol,
//         toRow,
//         toCol,
//         piece,
//         isCapture: isCapture,
//         isBlackAtBottom: !currentPlayerIsWhite,
//       ));
//     });
//   }

//   // ... [Keep all other existing methods unchanged] ...

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(isWhiteTurn ? 'White\'s Turn' : 'Black\'s Turn'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: resetBoardWithCustomPosition,
//             tooltip: 'Reset Board',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Player info can be simplified or removed for offline play
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   isWhiteTurn ? 'Your Turn (White)' : 'Your Turn (Black)',
//                   style: const TextStyle(fontSize: 18),
//                 ),
//               ],
//             ),
//           ),

//           // Chess board
//           Expanded(
//             child: Center(
//               child: AspectRatio(
//                 aspectRatio: 1,
//                 child: GridView.builder(
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 10,
//                   ),
//                   itemCount: 100,
//                   itemBuilder: (context, index) {
//                     int row = index ~/ 10;
//                     int col = index % 10;
//                     String piece = position[row][col];

//                     bool isSelected = selectedRow == row && selectedCol == col;
//                     bool isValidMove = validMoves[row][col];

//                     Color tileColor = (row + col) % 2 == 0
//                         ? const Color(0xFFDCDA5C)
//                         : Colors.green;
//                     if (isSelected) tileColor = Colors.yellowAccent;
//                     if (isValidMove) tileColor = Colors.lightGreenAccent;

//                     return GestureDetector(
//                       onTap: () {
//                         if (piece.isNotEmpty && 
//                             ((piece[0] == 'w' && isWhiteTurn) || 
//                              (piece[0] == 'b' && !isWhiteTurn))) {
//                           setState(() {
//                             pieceString = piece;
//                             selectedRow = row;
//                             selectedCol = col;
//                             calculateValidMoves(row, col);
//                           });
//                         } else if (selectedRow != null && 
//                                   selectedCol != null && 
//                                   validMoves[row][col]) {
//                           movePiece(selectedRow!, selectedCol!, row, col, piece);
//                         } else {
//                           setState(() {
//                             selectedRow = null;
//                             selectedCol = null;
//                             resetValidMoves();
//                           });
//                         }
//                       },
//                       child: Stack(
//                         children: [
//                           Container(color: tileColor),
//                           if (piece.isNotEmpty && pieceImages.containsKey(piece))
//                             Center(
//                               child: Image.asset(
//                                 pieceImages[piece]!,
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),

//           // Move history
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Move History:',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 SizedBox(
//                   height: 40,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: moveList.length,
//                     itemBuilder: (context, index) {
//                       return Container(
//                         margin: const EdgeInsets.only(right: 10),
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Center(
//                           child: Text('${moveList[index]}'),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ... [Keep all other existing methods unchanged] ...
// }