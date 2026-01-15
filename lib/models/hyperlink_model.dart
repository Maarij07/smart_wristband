class HyperlinkModel {
  final String title;
  final String content;
  final DateTime lastUpdated;

  HyperlinkModel({
    required this.title,
    required this.content,
    required this.lastUpdated,
  });

  factory HyperlinkModel.fromJson(Map<String, dynamic> json) {
    return HyperlinkModel(
      title: json['title'],
      content: json['content'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}