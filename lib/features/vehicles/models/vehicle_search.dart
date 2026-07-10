class VehicleSearch {
  final String query;

  const VehicleSearch({
    this.query = '',
  });

  bool get isEmpty => query.trim().isEmpty;

  VehicleSearch copyWith({
    String? query,
  }) {
    return VehicleSearch(
      query: query ?? this.query,
    );
  }
}