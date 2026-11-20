class MachineMedia {
  const MachineMedia({
    this.model3dUrl,
    this.posterUrl,
    this.spinFrames,
    this.hotspots,
    this.iosModelUrl,
  });

  final String? model3dUrl;
  final String? posterUrl;
  final List<String>? spinFrames;
  final List<MachineHotspot>? hotspots;
  final String? iosModelUrl;
}

class MachineHotspot {
  const MachineHotspot({
    required this.label,
    required this.position,
    this.normal = '0m 1m 0m',
    this.description,
  });

  final String label;
  final String position;
  final String normal;
  final String? description;
}
