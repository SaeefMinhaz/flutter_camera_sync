import 'package:equatable/equatable.dart';

/// Lightweight description of a physical camera on the device.
class CameraDevice extends Equatable {
  final String id;
  final String name;
  final bool isBackCamera;

  const CameraDevice({
    required this.id,
    required this.name,
    required this.isBackCamera,
  });

  @override
  List<Object?> get props => <Object?>[id, name, isBackCamera];
}

