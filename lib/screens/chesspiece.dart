// enum PieceColor { white, black }

// enum PieceType { pawn, rook, knight, bishop, queen, king }

// class ChessPiece {
//   final PieceColor color;
//   final PieceType type;
//   final String symbol;

//   ChessPiece(this.color, this.type) : symbol = _getSymbol(type, color);

//   static String _getSymbol(PieceType type, PieceColor color) {
//     // Unicode chess symbols
//     const whitePieces = ['♙', '♖', '♘', '♗', '♕', '♔'];
//     const blackPieces = ['♟', '♜', '♞', '♝', '♛', '♚'];

//     final index = type.index;
//     return color == PieceColor.white ? whitePieces[index] : blackPieces[index];
//   }
// }

enum PieceColor { white, black }

enum PieceType { pawn, rook, knight, bishop, queen, king, missile }

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
