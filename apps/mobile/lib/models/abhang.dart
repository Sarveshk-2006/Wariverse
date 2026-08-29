/// Represents a Marathi devotional hymn for offline Abhangavali.
class Abhang {
  final String id;
  final String titleMarathi;
  final String titleEnglish;
  final String marathiText;
  final String englishMeaning;
  final String author;
  final String category;
  final bool isFavorite;

  const Abhang({
    required this.id,
    required this.titleMarathi,
    required this.titleEnglish,
    required this.marathiText,
    required this.englishMeaning,
    required this.author,
    required this.category,
    this.isFavorite = false,
  });

  Abhang copyWith({bool? isFavorite}) {
    return Abhang(
      id: id,
      titleMarathi: titleMarathi,
      titleEnglish: titleEnglish,
      marathiText: marathiText,
      englishMeaning: englishMeaning,
      author: author,
      category: category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Abhang.fromJson(Map<String, dynamic> json) => Abhang(
        id: json['id'] as String? ?? '',
        titleMarathi: json['title_marathi'] as String? ?? '',
        titleEnglish: json['title_english'] as String? ?? '',
        marathiText: json['marathi_text'] as String? ?? '',
        englishMeaning: json['english_meaning'] as String? ?? '',
        author: json['author'] as String? ?? 'Sant Tukaram',
        category: json['category'] as String? ?? 'Vitthal',
        isFavorite: json['is_favorite'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title_marathi': titleMarathi,
        'title_english': titleEnglish,
        'marathi_text': marathiText,
        'english_meaning': englishMeaning,
        'author': author,
        'category': category,
        'is_favorite': isFavorite,
      };
}
