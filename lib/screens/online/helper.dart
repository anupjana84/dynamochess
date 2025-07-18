List<List<String>> createPosition({bool isBlackAtBottom = false}) {
  List<List<String>> position = List.generate(10, (_) => List.filled(10, ''));

  if (isBlackAtBottom) {
    // Place pawns
    for (int i = 0; i < 10; i++) {
      position[1][i] = 'bp';
      position[8][i] = 'wp';
    }

    // Black pieces on row 0
    position[0] = ['br', 'bn', 'bb', 'bm', 'bq', 'bk', 'bm', 'bb', 'bn', 'br'];
    // White pieces on row 9
    position[9] = ['wr', 'wn', 'wb', 'wm', 'wq', 'wk', 'wm', 'wb', 'wn', 'wr'];
  } else {
    // Place pawns
    for (int i = 0; i < 10; i++) {
      position[1][i] = 'wp';
      position[8][i] = 'bp';
    }

    // White pieces on row 0
    position[0] = ['wr', 'wn', 'wb', 'wm', 'wq', 'wk', 'wm', 'wb', 'wn', 'wr'];
    // Black pieces on row 9
    position[9] = ['br', 'bn', 'bb', 'bm', 'bq', 'bk', 'bm', 'bb', 'bn', 'br'];
  }

  return position;
}

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
