import '../models/models_exports.dart';

/// Voice Threat AI Detector ported from WoShield2 (SurakshaVoiceAI).
/// Analyzes voice speech text / spoken phrases for emergency keywords in English, Hindi, and Marathi.
class SurakshaVoiceAiService {
  static final Map<String, String> _threatKeywords = {
    // Immediate Distress / SOS (Highest Priority)
    'help': 'EMERGENCY',
    'save me': 'EMERGENCY',
    'bachao': 'EMERGENCY',
    'madat kara': 'EMERGENCY',
    'danger': 'EMERGENCY',
    'emergency': 'EMERGENCY',
    'i am in trouble': 'EMERGENCY',
    'call the police': 'SECURITY',
    'police': 'SECURITY',
    'doctor': 'MEDICAL',
    'ambulance': 'MEDICAL',
    'collapsed': 'MEDICAL',
    'heart attack': 'MEDICAL',
    'stampede': 'STAMPEDE',
    'crowd bottleneck': 'STAMPEDE',
    'fire': 'FIRE',
    'ag lagli': 'FIRE',

    // Physical & Verbal Assault
    'get away from me': 'THREAT',
    'leave me alone': 'THREAT',
    'stop following me': 'THREAT',
    "don't touch me": 'ASSAULT',
    'he is attacking me': 'ASSAULT',
    'let me go': 'ABDUCTION',
  };

  /// Analyzes input text and returns matching threat category or null if clean.
  static String? detectThreatCategory(String text) {
    final lowerText = text.toLowerCase();
    for (final entry in _threatKeywords.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Returns the specific keyword that matched the threat.
  static String? getMatchingKeyword(String text) {
    final lowerText = text.toLowerCase();
    for (final keyword in _threatKeywords.keys) {
      if (lowerText.contains(keyword)) {
        return keyword;
      }
    }
    return null;
  }

  /// Maps threat category string to WariVerse SOSCategory enum.
  static SOSCategory mapToSosCategory(String? categoryStr) {
    if (categoryStr == null) return SOSCategory.OTHER;
    switch (categoryStr.toUpperCase()) {
      case 'MEDICAL': return SOSCategory.MEDICAL;
      case 'SECURITY':
      case 'THREAT':
      case 'ASSAULT':
      case 'ABDUCTION': return SOSCategory.WOMEN_SAFETY;
      case 'STAMPEDE': return SOSCategory.ACCIDENT;
      case 'FIRE': return SOSCategory.ACCIDENT;
      default: return SOSCategory.MEDICAL;
    }
  }
}
