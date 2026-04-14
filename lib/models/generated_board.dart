import 'cell_pos.dart';

class GeneratedBoard {
  const GeneratedBoard({
    required this.cells,
    required this.paths,
    required this.activeCells,
  });

  final List<List<String>> cells;
  final Map<String, List<CellPos>> paths;
  final Set<CellPos> activeCells;
}
