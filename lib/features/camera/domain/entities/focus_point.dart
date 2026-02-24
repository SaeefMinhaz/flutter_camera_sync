import 'package:equatable/equatable.dart';

/// Normalized focus point within the camera preview.
///
/// Both [x] and [y] are in the range 0.0–1.0 where (0, 0) is the
/// top-left corner and (1, 1) is the bottom-right corner.
class FocusPoint extends Equatable {
  final double x;
  final double y;

  const FocusPoint({
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => <Object?>[x, y];
}

