import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';

/// Detailed view for reading a single devotional Abhang with text scaling and offline favorites.
class AbhangDetailScreen extends StatefulWidget {
  const AbhangDetailScreen({super.key, required this.abhang});

  final Abhang abhang;

  @override
  State<AbhangDetailScreen> createState() => _AbhangDetailScreenState();
}

class _AbhangDetailScreenState extends State<AbhangDetailScreen> {
  double _textScale = 1.0;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.abhang.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final abhang = widget.abhang;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: Text(abhang.titleMarathi),
        actions: [
          IconButton(
            tooltip: 'Text Size Smaller',
            icon: const Icon(Icons.text_format),
            onPressed: () {
              setState(() {
                _textScale = (_textScale - 0.1).clamp(0.8, 1.5);
              });
            },
          ),
          IconButton(
            tooltip: _isFavorite ? 'Remove Favorite' : 'Add Favorite',
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header Card
            WariCard(
              borderColor: WariColors.primary,
              child: Column(
                children: [
                  Text(
                    abhang.titleMarathi,
                    style: WariTypography.headlineMedium.copyWith(
                      color: WariColors.primaryDark,
                      fontSize: 22 * _textScale,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    abhang.titleEnglish,
                    style: WariTypography.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Author: ${abhang.author}',
                    style: WariTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            // Devanagari Lyrics Card
            WariCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_stories, color: WariColors.primary, size: 20),
                      const SizedBox(width: WariSpacing.xs),
                      Text('अभंग (Marathi Devanagari)', style: WariTypography.titleSmall),
                    ],
                  ),
                  const Divider(height: WariSpacing.base),
                  Text(
                    abhang.marathiText,
                    style: TextStyle(
                      fontSize: 16 * _textScale,
                      height: 1.8,
                      fontWeight: FontWeight.w600,
                      color: WariColors.slate900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            // English Meaning Card
            WariCard(
              borderColor: WariColors.slate300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.translate, color: WariColors.primary, size: 20),
                      const SizedBox(width: WariSpacing.xs),
                      Text('English Meaning', style: WariTypography.titleSmall),
                    ],
                  ),
                  const Divider(height: WariSpacing.base),
                  Text(
                    abhang.englishMeaning,
                    style: WariTypography.bodyMedium.copyWith(
                      fontSize: 14 * _textScale,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
