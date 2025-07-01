class ChessBoard {
  List<List<String>> board;

  ChessBoard(this.board);

  factory ChessBoard.createInitialPosition() {
    var b = List<List<String>>.generate(10, (_) => List<String>.filled(10, ""));
    for (int i = 0; i < 10; i++) {
      b[8][i] = "bp";
      b[1][i] = "wp";
    }

    b[0] = ["wr", "wn", "wb", "wm", "wq", "wk", "wm", "wb", "wn", "wr"];
    b[9] = ["br", "bn", "bb", "bm", "bq", "bk", "bm", "bb", "bn", "br"];

    return ChessBoard(b);
  }

  factory ChessBoard.fromJson(List<dynamic> json) {
    List<List<String>> board = [];
    for (var row in json) {
      board.add(List<String>.from(row));
    }
    return ChessBoard(board);
  }

  List<List<String>> toJson() => board;
}
