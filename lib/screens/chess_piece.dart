enum PieceType { pawn, rook, knight, bishop, queen, king, missile }

enum PieceColor { white, black }

class ChessPiece {
  final PieceColor color;
  final PieceType type;

  ChessPiece(this.color, this.type);

  String get imageAsset {
    final colorStr = color == PieceColor.white ? 'white' : 'black';
    String typeStr;

    switch (type) {
      case PieceType.pawn:
        typeStr = 'pawn';
        break;
      case PieceType.rook:
        typeStr = 'rook';
        break;
      case PieceType.knight:
        typeStr = 'knight';
        break;
      case PieceType.bishop:
        typeStr = 'bishop';
        break;
      case PieceType.queen:
        typeStr = 'queen';
        break;
      case PieceType.king:
        typeStr = 'king';
        break;
      case PieceType.missile:
        typeStr = 'missile';
        break;
    }

    return 'assets/images/$colorStr\_$typeStr.png';
  }

  String get name {
    switch (type) {
      case PieceType.pawn:
        return 'Pawn';
      case PieceType.rook:
        return 'Rook';
      case PieceType.knight:
        return 'Knight';
      case PieceType.bishop:
        return 'Bishop';
      case PieceType.queen:
        return 'Queen';
      case PieceType.king:
        return 'King';
      case PieceType.missile:
        return 'Missile';
    }
  }
}
