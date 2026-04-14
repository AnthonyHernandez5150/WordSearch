import 'board_shape.dart';

class PuzzleDefinition {
  const PuzzleDefinition({
    required this.name,
    required this.headline,
    required this.themeLine,
    required this.size,
    required this.words,
    required this.tip,
    this.shape,
  });

  final String name;
  final String headline;
  final String themeLine;
  final int size;
  final List<String> words;
  final String tip;
  final BoardShapeDefinition? shape;

  int get wordCount => words.length;
  bool get isShaped => shape != null;

  static const Object _shapeSentinel = Object();

  PuzzleDefinition copyWith({
    String? name,
    String? headline,
    String? themeLine,
    int? size,
    List<String>? words,
    String? tip,
    Object? shape = _shapeSentinel,
  }) {
    return PuzzleDefinition(
      name: name ?? this.name,
      headline: headline ?? this.headline,
      themeLine: themeLine ?? this.themeLine,
      size: size ?? this.size,
      words: words ?? this.words,
      tip: tip ?? this.tip,
      shape: identical(shape, _shapeSentinel)
          ? this.shape
          : shape as BoardShapeDefinition?,
    );
  }
}
