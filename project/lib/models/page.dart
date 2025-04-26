class PageModel {
  final int id;
  final String title;
  final String content;

  PageModel({required this.id, required this.title, required this.content});

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
    );
  }
}


