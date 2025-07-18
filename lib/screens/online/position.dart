class Position {
  final int row;
  final int col;
  final bool isBlackAtBottom;

  const Position(this.row, this.col, {this.isBlackAtBottom = false});

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
    final rowNum = row + 1;
    return '$colChar$rowNum';
  }
}
