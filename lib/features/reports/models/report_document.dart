class ReportDocument {
  const ReportDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.generatedAt,
    required this.sections,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime generatedAt;
  final List<ReportSection> sections;
}

class ReportSection {
  const ReportSection({required this.title, required this.rows});

  final String title;
  final List<ReportRow> rows;
}

class ReportRow {
  const ReportRow({required this.label, required this.value});

  final String label;
  final String value;
}
