class CentralReplayReport {
  const CentralReplayReport({
    required this.examined,
    required this.replayed,
    required this.remaining,
    required this.stoppedForConnectivity,
  });

  final int examined;
  final int replayed;
  final int remaining;
  final bool stoppedForConnectivity;
}
