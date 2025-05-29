// online_chess_screen.dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum PieceColor { white, black }

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);
}

class ChessPiece {
  final PieceColor color;
  final String type;

  ChessPiece(this.color, this.type);

  ChessPiece.fromJson(Map<String, dynamic> json)
      : color = getPieceColor(json['color']),
        type = json['type'];

  Map<String, dynamic> toJson() {
    return {
      'color': color.name,
      'type': type,
    };
  }

  static PieceColor getPieceColor(String colorStr) {
    switch (colorStr) {
      case 'white':
        return PieceColor.white;
      case 'black':
        return PieceColor.black;
      default:
        throw Exception('Unknown piece color: $colorStr');
    }
  }
}

class OnlineChessScreen extends StatefulWidget {
  final String roomId;

  const OnlineChessScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  _OnlineChessScreenState createState() => _OnlineChessScreenState();
}

class _OnlineChessScreenState extends State<OnlineChessScreen> {
  late IO.Socket socket;
  static const int boardSize = 10;
  List<List<dynamic>> board = [];
  String currentPlayer = 'white';
  String gameStatus = 'Waiting for opponent...';
  bool isMyTurn = false;
  String? myColor;
  bool opponentConnected = false;

  @override
  void initState() {
    super.initState();
    connectToSocket();
  }

  void connectToSocket() {
    // Use your Mac's local IP address instead of localhost
    // You can find this in System Preferences > Network
    socket = IO.io(
        'https://5002-2409-40e1-106a-560b-4897-bdeb-5ec2-a48d.ngrok-free.app',
        <String, dynamic>{
          'transports': ['websocket'],
        });

    socket.onConnect((_) {
      print('Connected to server');
      socket.emit("joinGame", widget.roomId);
    });

    socket.on("gameState", (data) {
      setState(() {
        updateBoardFromData(data['board']);
        currentPlayer = data['currentPlayer'];
        gameStatus = '$currentPlayer\'s turn';
        myColor = data['assignedColor'];
        isMyTurn = (myColor == currentPlayer);
        opponentConnected = true;
      });
    });

    socket.on("moveMade", (data) {
      setState(() {
        updateBoardFromData(data['board']);
        currentPlayer = data['currentPlayer'];
        gameStatus = '$currentPlayer\'s turn';
        isMyTurn = (myColor == currentPlayer);
      });
    });

    socket.on("gameReset", (data) {
      setState(() {
        updateBoardFromData(data['board']);
        currentPlayer = data['currentPlayer'];
        gameStatus = '$currentPlayer\'s turn';
        isMyTurn = (myColor == currentPlayer);
      });
    });

    // socket.on("gameFull", () {
    //   setState(() {
    //     gameStatus = 'Game is full!';
    //   });
    // });

    // socket.on("opponentDisconnected", () {
    //   setState(() {
    //     opponentConnected = false;
    //     gameStatus = 'Opponent disconnected';
    //   });
    // });

    socket.on("playerJoined", (data) {
      setState(() {
        gameStatus = '${data['color']} has joined. Game starting!';
      });
    });

    socket.onDisconnect((_) {
      print("Socket disconnected");
      setState(() {
        gameStatus = 'Disconnected from server';
      });
    });
  }

  void updateBoardFromData(List<dynamic> dataBoard) {
    board = List.generate(boardSize, (i) => List.filled(boardSize, null));

    for (int row = 0; row < boardSize; row++) {
      List<dynamic> rowData = dataBoard[row];
      for (int col = 0; col < boardSize; col++) {
        dynamic pieceData = rowData[col];
        if (pieceData != null) {
          String colorStr = pieceData['color'];
          String typeStr = pieceData['type'];

          PieceColor color = PieceColor.values.firstWhere(
              (e) => e.name == colorStr,
              orElse: () => PieceColor.white);

          board[row][col] = {
            'color': color,
            'type': typeStr,
          };
        } else {
          board[row][col] = null;
        }
      }
    }
  }

  void sendMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (isMyTurn && opponentConnected) {
      socket.emit("makeMove", {
        "roomId": widget.roomId,
        "from": {"row": fromRow, "col": fromCol},
        "to": {"row": toRow, "col": toCol},
      });
    }
  }

  void resetGame() {
    socket.emit("resetGame", widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Online Chess - Room: ${widget.roomId}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: opponentConnected ? resetGame : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              gameStatus,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: boardSize,
                  childAspectRatio: 1.0,
                ),
                itemCount: boardSize * boardSize,
                itemBuilder: (context, index) {
                  final row = index ~/ boardSize;
                  final col = index % boardSize;
                  final piece = board[row][col];

                  return GestureDetector(
                    onTap: () {
                      handleTap(row, col);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: getSquareColor(row, col, false, false),
                        border: Border.all(color: Colors.black54, width: 0.5),
                      ),
                      child: Center(
                        child: piece != null
                            ? Image.asset(
                                'assets/images/${piece['color']}_${piece['type']}.png',
                                width: 30,
                                height: 30,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            if (!opponentConnected)
              Text(
                'Waiting for opponent to join...',
                style: TextStyle(color: Colors.orange),
              ),
            if (isMyTurn && opponentConnected)
              Text(
                'Your turn ($myColor)',
                style:
                    TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Color getSquareColor(int row, int col, bool isSelected, bool isPossibleMove) {
    if (isSelected) return Colors.blue[400]!;
    if (isPossibleMove) return Colors.blue[200]!;
    return (row + col) % 2 == 0 ? Colors.yellow : Colors.green;
  }

  void handleTap(int row, int col) {
    // Implement piece selection and move logic
    // This is simplified - you'll need to add proper move validation
    if (board[row][col] != null && board[row][col]['color'] == myColor) {
      // Show possible moves for selected piece
      // For simplicity, we're not implementing full move logic here
    } else {
      // Try to make a move if there's a selected piece
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }
}
