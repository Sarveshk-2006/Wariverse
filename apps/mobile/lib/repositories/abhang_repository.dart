import '../models/models_exports.dart';

/// Offline repository bundling curated Marathi Wari Abhangs and devotional hymns.
class AbhangRepository {
  final List<Abhang> _abhangs = [
    const Abhang(
      id: 'abh-001',
      titleMarathi: 'सुंदर ते ध्यान उभे विटेवरी',
      titleEnglish: 'Sundar Te Dhyan Ubhe Vitevari',
      marathiText: '''सुंदर ते ध्यान उभे विटेवरी ।
कर कटावरी ठेवोनिया ॥१॥

तुळशीची माळ गळां कासे पितांबर ।
आवडे निरंतर हेचि रूप ॥२॥

मकरकुंडलें तळपती श्रवणीं ।
कौस्तुभमणि शोभे गळां ॥३॥

तुका म्हणे माझें हेचि सर्व सुख ।
पाहीन श्रीमुख आवडीनें ॥४॥''',
      englishMeaning: 'Beautiful is the form standing on the brick, with hands rested on hips. Wearing a garland of Tulsi leaves and yellow silk garments, this eternal form fills my heart with joy. Tukaram says this sight is my ultimate bliss.',
      author: 'Sant Tukaram Maharaj',
      category: 'Vitthal',
    ),
    const Abhang(
      id: 'abh-002',
      titleMarathi: 'आनंदाचे डोही आनंदतरंग',
      titleEnglish: 'Anandache Dohi Ananda Taranga',
      marathiText: '''आनंदाचे डोही आनंदतरंग ।
आनंदचि अंग आपुलिया ॥१॥

हसणे रडणे आनंदचि होय ।
काहीच न राहे दुजेपण ॥२॥

तुका म्हणे देवा आनंद स्वरूप ।
न राहे पाप-ताप काही ॥३॥''',
      englishMeaning: 'In the ocean of bliss, waves of joy rise continuously. Our very inner being becomes bliss itself. Laughing or crying, all dissolves into divine joy with Sant Tukaram.',
      author: 'Sant Tukaram Maharaj',
      category: 'Vitthal',
    ),
    const Abhang(
      id: 'abh-003',
      titleMarathi: 'रूप पाहता लोचनी',
      titleEnglish: 'Roop Pahata Lochani',
      marathiText: '''रूप पाहतां लोचनीं ।
सुख जालें वो साजिणी ॥१॥

तो हा विठ्ठल बरवा ।
तो हा विठ्ठल बरवा ॥२॥

बहुतां सुकृतांची जोडी ।
म्हणूनि विठ्ठलीं आवडी ॥३॥

ज्ञानदेव म्हणे साच ।
माझा विठ्ठलचि वांच ॥४॥''',
      englishMeaning: 'Beholding the divine form of Vitthal with these eyes brings supreme peace and bliss. Dnyaneshwar says by immense past good virtues, this love for Lord Vitthal blooms.',
      author: 'Sant Dnyaneshwar Maharaj',
      category: 'Dnyaneshwar',
    ),
    const Abhang(
      id: 'abh-004',
      titleMarathi: 'माझे माहेर पंढरपूर',
      titleEnglish: 'Majhe Maher Pandharpur',
      marathiText: '''माझे माहेर पंढरपूर ।
काय वाणू त्याचे सुख ॥१॥

विठू माझा लेकुरवाळा ।
संगे गोपाळांचा मेळा ॥२॥

एका जनार्दनी शरण ।
विठ्ठल चरणीं माझे मन ॥३॥''',
      englishMeaning: 'Pandharpur is my maternal home of eternal solace. Lord Vitthal stands as a loving parent surrounded by all devotees. Eknath submits his heart at the lotus feet of Vitthal.',
      author: 'Sant Eknath Maharaj',
      category: 'Prayer',
    ),
  ];

  /// Returns all bundled offline Abhangs.
  Future<List<Abhang>> fetchAbhangs() async {
    return _abhangs;
  }

  /// Searches Abhangs locally across Marathi title, English title, author, and category.
  Future<List<Abhang>> searchAbhangs(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _abhangs;

    return _abhangs.where((a) {
      return a.titleMarathi.toLowerCase().contains(q) ||
          a.titleEnglish.toLowerCase().contains(q) ||
          a.author.toLowerCase().contains(q) ||
          a.category.toLowerCase().contains(q) ||
          a.marathiText.toLowerCase().contains(q);
    }).toList();
  }
}
