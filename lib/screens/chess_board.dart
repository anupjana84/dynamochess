// import 'package:flutter/material.dart';
// import 'dart:async';

// class ChessBoardScreen extends StatefulWidget {
//   @override
//   _ChessBoardScreenState createState() => _ChessBoardScreenState();
// }

// class _ChessBoardScreenState extends State<ChessBoardScreen> {
//   // Game state
//   List<List<String>> chessboard = [
//     ['r', 'n', 'b', 'q', 'k', 'qb', 'q', 'b', 'n', 'r'],
//     ['a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a'],
//     ['', '', '', '', '', '', '', '', '', ''],
//     ['', '', '', '', '', '', '', '', '', ''],
//     ['', '', '', '', '', '', '', '', '', ''],
//     ['', '', '', '', '', '', '', '', '', ''],
//     ['', '', '', '', '', '', '', '', '', ''],
//     ['', '', '', '', '', '', '', '', '', ''],
//     ['c', 'c', 'c', 'c', 'c', 'c', 'c', 'c', 'c', 'c'],
//     ['rw', 'nw', 'bw', 'qw', 'kb', 'qbb', 'qw', 'bw', 'nw', 'rw'],
//   ];

//   int? selectedRow;
//   int? selectedCol;

//   // Player turn: true = Player 1 (bottom), false = Player 2 (top)
//   bool isPlayerOneTurn = true;

//   // Timer settings (e.g., 60 seconds per player)
//   late Timer timer;
//   int playerOneTime = 60; // in seconds
//   int playerTwoTime = 60;

//   void startTimer() {
//     timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       setState(() {
//         if (isPlayerOneTurn && playerOneTime > 0) {
//           playerOneTime--;
//         } else if (!isPlayerOneTurn && playerTwoTime > 0) {
//           playerTwoTime--;
//         }
//       });
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     startTimer();
//   }

//   @override
//   void dispose() {
//     timer.cancel();
//     super.dispose();
//   }

//   void applyMove(int fromRow, int fromCol, int toRow, int toCol) {
//     if (fromRow < 0 ||
//         fromRow >= 10 ||
//         fromCol < 0 ||
//         fromCol >= 10 ||
//         toRow < 0 ||
//         toRow >= 10 ||
//         toCol < 0 ||
//         toCol >= 10) return;

//     String piece = chessboard[fromRow][fromCol];
//     if (piece.isEmpty) return;

//     String targetPiece = chessboard[toRow][toCol];

//     if (targetPiece.isNotEmpty && isSameColor(piece, targetPiece)) {
//       return; // Can't capture own piece
//     }

//     setState(() {
//       chessboard[toRow][toCol] = piece;
//       chessboard[fromRow][fromCol] = '';
//       switchTurn(); // Switch turn after valid move
//     });

//     selectedRow = null;
//     selectedCol = null;
//   }

//   void switchTurn() {
//     isPlayerOneTurn = !isPlayerOneTurn;
//   }

//   bool isSameColor(String p1, String p2) {
//     bool isBlack1 = p1.toLowerCase() == p1;
//     bool isBlack2 = p2.toLowerCase() == p2;
//     return isBlack1 == isBlack2;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Two Player Chess')),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             // Timer Display
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Column(
//                   children: [
//                     Text("Player 1", style: TextStyle(fontSize: 18)),
//                     Text("$playerOneTime sec"),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     Text("Player 2", style: TextStyle(fontSize: 18)),
//                     Text("$playerTwoTime sec"),
//                   ],
//                 ),
//               ],
//             ),

//             // Active player indicator
//             Container(
//               margin: EdgeInsets.symmetric(vertical: 10),
//               padding: EdgeInsets.all(8),
//               color: isPlayerOneTurn
//                   ? Colors.blue.withOpacity(0.2)
//                   : Colors.red.withOpacity(0.2),
//               alignment: Alignment.center,
//               child: Text(
//                 isPlayerOneTurn ? "Player 1's Turn" : "Player 2's Turn",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),

//             // Chessboard
//             Expanded(
//               child: GridView.builder(
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 10,
//                   childAspectRatio: 1.0,
//                 ),
//                 itemCount: 10 * 10,
//                 itemBuilder: (context, index) {
//                   int row = index ~/ 10;
//                   int col = index % 10;

//                   String piece = chessboard[row][col];
//                   Color squareColor =
//                       (row + col).isEven ? Colors.yellow : Colors.green;
//                   bool isSelected = selectedRow == row && selectedCol == col;

//                   // Determine if current piece belongs to the active player
//                   bool isMyTurn = isPlayerOneTurn
//                       ? piece.isNotEmpty && piece == piece.toLowerCase()
//                       : piece.isNotEmpty && piece != piece.toLowerCase();

//                   return GestureDetector(
//                     onTap: () {
//                       if (isMyTurn) {
//                         if (piece.isNotEmpty) {
//                           setState(() {
//                             selectedRow = row;
//                             selectedCol = col;
//                           });
//                         } else if (selectedRow != null && selectedCol != null) {
//                           applyMove(selectedRow!, selectedCol!, row, col);
//                         }
//                       }
//                     },
//                     child: Container(
//                       color: isSelected ? Colors.orange : squareColor,
//                       alignment: Alignment.center,
//                       child: piece.isNotEmpty
//                           ? Image.asset(
//                               'assets/images/$piece.png',
//                               width: 32,
//                               height: 32,
//                             )
//                           : null,
//                     ),
//                   );
//                 },
//               ),
//             ),

//             // Column Labels (a-j)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(
//                   10,
//                   (index) => Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Text(
//                           String.fromCharCode(97 + index),
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       )),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
