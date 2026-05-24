import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/budget_model.dart';

/// Centralised AI service — Gemini-powered features.
/// Receipt parsing has been moved to OcrService (offline, ML Kit only).
class AiService {
  static const _model = 'gemini-2.0-flash-lite';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent';

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ─── Budget generator ─────────────────────────────────────────────────────

  Future<List<BudgetCategory>> generateBudget({
    required String profileType,
    required double monthlyBudget,
    required double savingTarget,
  }) async {
    // Skip API if key is missing
    if (_apiKey.isEmpty) {
      return _generateBudgetLocally(
          profileType: profileType,
          monthlyBudget: monthlyBudget,
          savingTarget: savingTarget);
    }

    final typeLabel = const {
      'student': 'pelajar',
      'employed': 'bekerja',
      'unemployed': 'tidakBekerja',
    }[profileType] ?? 'bekerja';

    final prompt = '''
You are a personal finance assistant. Based on the user profile below, suggest a monthly budget breakdown.

User Profile:
- Profile type: $typeLabel (pelajar/bekerja/tidakBekerja)
- Monthly budget: RM $monthlyBudget
- Saving target: RM $savingTarget

Return ONLY a valid JSON array with no explanation:
[
  { "category": "Food", "icon": "restaurant", "amount": 0.00, "color": "#FF6B6B" },
  { "category": "Transport", "icon": "directions_car", "amount": 0.00, "color": "#4ECDC4" }
]

Rules:
- Total of all amounts must not exceed monthly budget: RM $monthlyBudget
- Always include Savings category with icon "savings" and color "#2ECC71"
- For pelajar: focus on Food, Transport, Education, Entertainment, Savings
- For bekerja: focus on Food, Transport, Bills, Shopping, Savings, Health
- For tidakBekerja: focus on Food, Transport, Daily Needs, Savings
- Amount must be realistic based on Malaysian cost of living
- Return between 4 to 7 categories only
- Use only these icon values: restaurant, directions_car, school, movie, savings, local_hospital, shopping_bag, home, electric_bolt, fitness_center, coffee, sports_esports, category
- Use distinct hex colors for each category
''';

    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.2,
                'maxOutputTokens': 1024,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
            'Gemini API error ${response.statusCode}: ${response.body}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          body['candidates'][0]['content']['parts'][0]['text'] as String;

      final jsonStr = _extractJson(text);
      final parsed = jsonDecode(jsonStr) as List<dynamic>;
      return parsed
          .map((c) => BudgetCategory.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback to local algorithm when API is unavailable
      return _generateBudgetLocally(
        profileType: profileType,
        monthlyBudget: monthlyBudget,
        savingTarget: savingTarget,
      );
    }
  }

  // ─── Local fallback (no API needed) ──────────────────────────────────────

  List<BudgetCategory> _generateBudgetLocally({
    required String profileType,
    required double monthlyBudget,
    required double savingTarget,
  }) {
    final templates = <String, List<Map<String, dynamic>>>{
      'student': [
        {'category': 'Food', 'icon': 'restaurant', 'color': '#FF6B6B', 'pct': 0.30},
        {'category': 'Transport', 'icon': 'directions_car', 'color': '#4ECDC4', 'pct': 0.15},
        {'category': 'Education', 'icon': 'school', 'color': '#5C6BC0', 'pct': 0.20},
        {'category': 'Entertainment', 'icon': 'movie', 'color': '#FFE66D', 'pct': 0.10},
        {'category': 'Savings', 'icon': 'savings', 'color': '#2ECC71', 'pct': 0.25},
      ],
      'employed': [
        {'category': 'Food', 'icon': 'restaurant', 'color': '#FF6B6B', 'pct': 0.25},
        {'category': 'Transport', 'icon': 'directions_car', 'color': '#4ECDC4', 'pct': 0.15},
        {'category': 'Bills', 'icon': 'electric_bolt', 'color': '#5C6BC0', 'pct': 0.20},
        {'category': 'Shopping', 'icon': 'shopping_bag', 'color': '#E67E22', 'pct': 0.10},
        {'category': 'Health', 'icon': 'local_hospital', 'color': '#9B59B6', 'pct': 0.10},
        {'category': 'Savings', 'icon': 'savings', 'color': '#2ECC71', 'pct': 0.20},
      ],
      'unemployed': [
        {'category': 'Food', 'icon': 'restaurant', 'color': '#FF6B6B', 'pct': 0.35},
        {'category': 'Transport', 'icon': 'directions_car', 'color': '#4ECDC4', 'pct': 0.15},
        {'category': 'Daily Needs', 'icon': 'home', 'color': '#E67E22', 'pct': 0.25},
        {'category': 'Savings', 'icon': 'savings', 'color': '#2ECC71', 'pct': 0.25},
      ],
    };

    final template = templates[profileType] ?? templates['employed']!;
    return template.map((t) {
      double amount = monthlyBudget * (t['pct'] as double);
      if (t['category'] == 'Savings' && savingTarget > 0) {
        amount = savingTarget.clamp(0, monthlyBudget * 0.40);
      }
      return BudgetCategory(
        category: t['category'] as String,
        icon: t['icon'] as String,
        amount: double.parse(amount.toStringAsFixed(2)),
        color: t['color'] as String,
      );
    }).toList();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _extractJson(String text) {
    final fenced =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
    if (fenced != null) return fenced.group(1)!.trim();

    // Try array first, then object
    final arr = RegExp(r'\[[\s\S]*\]').firstMatch(text);
    if (arr != null) return arr.group(0)!.trim();

    final obj = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (obj != null) return obj.group(0)!.trim();

    return text.trim();
  }
}
