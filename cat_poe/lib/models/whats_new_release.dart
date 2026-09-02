class WhatsNewRelease {
  const WhatsNewRelease({
    required this.version,
    required this.dateLabel,
    required this.notes,
  });

  final String version;
  final String dateLabel;
  final List<String> notes;

  factory WhatsNewRelease.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['notes'];
    return WhatsNewRelease(
      version: json['version'] as String,
      dateLabel: json['date_label'] as String,
      notes: notesRaw is List
          ? notesRaw.map((e) => e.toString()).toList()
          : <String>[],
    );
  }
}
