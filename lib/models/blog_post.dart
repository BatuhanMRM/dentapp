class BlogPost {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String category;
  final List<String> tags;
  final String imageUrl;
  final String authorName;
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final int readTimeMinutes;
  final bool isFeatured;
  final int views;
  final int likes;

  BlogPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.category,
    required this.tags,
    required this.imageUrl,
    required this.authorName,
    required this.publishedAt,
    this.updatedAt,
    required this.readTimeMinutes,
    this.isFeatured = false,
    this.views = 0,
    this.likes = 0,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      title: json['title'],
      excerpt: json['excerpt'],
      content: json['content'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'],
      authorName: json['authorName'],
      publishedAt: DateTime.parse(json['publishedAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      readTimeMinutes: json['readTimeMinutes'],
      isFeatured: json['isFeatured'] ?? false,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'category': category,
      'tags': tags,
      'imageUrl': imageUrl,
      'authorName': authorName,
      'publishedAt': publishedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'readTimeMinutes': readTimeMinutes,
      'isFeatured': isFeatured,
      'views': views,
      'likes': likes,
    };
  }

  BlogPost copyWith({
    String? id,
    String? title,
    String? excerpt,
    String? content,
    String? category,
    List<String>? tags,
    String? imageUrl,
    String? authorName,
    DateTime? publishedAt,
    DateTime? updatedAt,
    int? readTimeMinutes,
    bool? isFeatured,
    int? views,
    int? likes,
  }) {
    return BlogPost(
      id: id ?? this.id,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      authorName: authorName ?? this.authorName,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      isFeatured: isFeatured ?? this.isFeatured,
      views: views ?? this.views,
      likes: likes ?? this.likes,
    );
  }
}

enum BlogCategory {
  preventive('Koruyucu Diş Hekimliği'),
  treatment('Tedavi'),
  oralHealth('Ağız Sağlığı'),
  nutrition('Beslenme'),
  children('Çocuk Diş Hekimliği'),
  cosmetic('Estetik Diş Hekimliği'),
  emergency('Acil Durumlar'),
  generalInfo('Genel Bilgiler');

  const BlogCategory(this.displayName);
  final String displayName;
}
