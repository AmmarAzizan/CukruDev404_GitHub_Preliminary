import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../providers/suggestion_provider.dart';
import '../services/suggestion_service.dart';

class SuggestionsCard extends ConsumerWidget {
  const SuggestionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(suggestionProvider);

    return async.when(
      loading: _buildSkeleton,
      error: (_, _) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return _buildCard(suggestions);
      },
    );
  }

  // ─── Card with suggestions ────────────────────────────────────────────────

  Widget _buildCard(List<Suggestion> suggestions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 17,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Smart Suggestions',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Suggestion rows
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: suggestions.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, i) => _SuggestionRow(suggestion: suggestions[i]),
          ),
        ],
      ),
    );
  }

  // ─── Loading skeleton ─────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(width: 140, height: 16),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++) ...[
            Row(
              children: [
                _shimmer(width: 36, height: 36, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmer(width: double.infinity, height: 12),
                      const SizedBox(height: 6),
                      _shimmer(width: 180, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            if (i < 2) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _shimmer({
    required double width,
    required double height,
    double radius = 6,
  }) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─── Single suggestion row ────────────────────────────────────────────────────

class _SuggestionRow extends StatelessWidget {
  final Suggestion suggestion;
  const _SuggestionRow({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured icon bubble
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: suggestion.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              suggestion.icon,
              size: 19,
              color: suggestion.color,
            ),
          ),
          const SizedBox(width: 12),

          // Text + left accent
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left accent bar
                Container(
                  width: 3,
                  height: 40,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: suggestion.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Text(
                    suggestion.text,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF444466),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
