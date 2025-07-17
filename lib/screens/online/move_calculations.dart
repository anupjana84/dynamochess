void calculateDiagonalMoves(int row, int col, bool isWhite,
    List<List<String>> position, List<List<bool>> validMoves) {
  List<List<int>> directions = [
    [-1, -1],
    [-1, 1],
    [1, -1],
    [1, 1]
  ];

  for (var dir in directions) {
    int dRow = dir[0], dCol = dir[1];
    for (int i = 1; i < 10; i++) {
      int r = row + i * dRow, c = col + i * dCol;
      if (r >= 0 && r < 10 && c >= 0 && c < 10) {
        String target = position[r][c];
        if (target.isEmpty) {
          validMoves[r][c] = true;
        } else {
          if (target[0] != (isWhite ? 'w' : 'b')) validMoves[r][c] = true;
          break;
        }
      } else {
        break;
      }
    }
  }
}

void resetValidMoves(List<List<bool>> validMoves) {
  for (var i = 0; i < validMoves.length; i++) {
    for (var j = 0; j < validMoves[i].length; j++) {
      validMoves[i][j] = false;
    }
  }
}
