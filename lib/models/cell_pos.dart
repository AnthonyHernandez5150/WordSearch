class CellPos {
  const CellPos(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is CellPos && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}
