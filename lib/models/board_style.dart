enum BoardStyle {
  classic,
  shaped;

  String get label {
    switch (this) {
      case BoardStyle.classic:
        return 'Classic';
      case BoardStyle.shaped:
        return 'Shaped';
    }
  }
}
