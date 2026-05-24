import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class GigInfo {
  final String emoji;
  final String title;
  final String earning;
  final String description;
  final String buttonLabel;
  final String url;

  const GigInfo({
    required this.emoji,
    required this.title,
    required this.earning,
    required this.description,
    required this.buttonLabel,
    required this.url,
  });
}

// ─── Per-profile gig lists ────────────────────────────────────────────────────

const _pelajarGigs = [
  GigInfo(
    emoji: '🚗',
    title: 'Grab Driver',
    earning: 'Earn RM50-150/day',
    description: 'Flexible hours',
    buttonLabel: 'Sign Up →',
    url: 'https://www.grab.com/my/drive',
  ),
  GigInfo(
    emoji: '📦',
    title: 'Lalamove',
    earning: 'Earn RM30-100/day',
    description: 'Work anytime',
    buttonLabel: 'Sign Up →',
    url: 'https://driver.lalamove.com',
  ),
  GigInfo(
    emoji: '🎨',
    title: 'Fiverr Freelance',
    earning: 'Sell your skills online',
    description: 'Work from anywhere',
    buttonLabel: 'Explore →',
    url: 'https://www.fiverr.com',
  ),
  GigInfo(
    emoji: '🛍️',
    title: 'Carousell',
    earning: 'Sell unused items',
    description: 'Easy setup',
    buttonLabel: 'Start Selling →',
    url: 'https://www.carousell.com.my',
  ),
  GigInfo(
    emoji: '📝',
    title: 'Upwork',
    earning: 'Find freelance projects',
    description: 'Get paid in USD',
    buttonLabel: 'Explore →',
    url: 'https://www.upwork.com',
  ),
];

const _employedGigs = [
  GigInfo(
    emoji: '💻',
    title: 'Upwork',
    earning: 'Freelance using your skills',
    description: 'Get paid in USD',
    buttonLabel: 'Explore →',
    url: 'https://www.upwork.com',
  ),
  GigInfo(
    emoji: '🎨',
    title: 'Fiverr Freelance',
    earning: 'Sell your skills online',
    description: 'Work from anywhere',
    buttonLabel: 'Explore →',
    url: 'https://www.fiverr.com',
  ),
  GigInfo(
    emoji: '🛍️',
    title: 'Carousell',
    earning: 'Sell unused items',
    description: 'Easy setup',
    buttonLabel: 'Start Selling →',
    url: 'https://www.carousell.com.my',
  ),
  GigInfo(
    emoji: '🚗',
    title: 'Grab Driver',
    earning: 'Earn RM50-150/day',
    description: 'Flexible hours',
    buttonLabel: 'Sign Up →',
    url: 'https://www.grab.com/my/drive',
  ),
  GigInfo(
    emoji: '📦',
    title: 'Lalamove',
    earning: 'Earn RM30-100/day',
    description: 'Work anytime',
    buttonLabel: 'Sign Up →',
    url: 'https://driver.lalamove.com',
  ),
];

const _unemployedGigs = [
  GigInfo(
    emoji: '🚗',
    title: 'Grab Driver',
    earning: 'Earn RM50-150/day',
    description: 'Flexible hours',
    buttonLabel: 'Sign Up →',
    url: 'https://www.grab.com/my/drive',
  ),
  GigInfo(
    emoji: '📦',
    title: 'Lalamove',
    earning: 'Earn RM30-100/day',
    description: 'Work anytime',
    buttonLabel: 'Sign Up →',
    url: 'https://driver.lalamove.com',
  ),
  GigInfo(
    emoji: '🛍️',
    title: 'Carousell',
    earning: 'Sell unused items',
    description: 'Easy setup',
    buttonLabel: 'Start Selling →',
    url: 'https://www.carousell.com.my',
  ),
  GigInfo(
    emoji: '🎨',
    title: 'Fiverr Freelance',
    earning: 'Sell your skills online',
    description: 'Work from anywhere',
    buttonLabel: 'Explore →',
    url: 'https://www.fiverr.com',
  ),
  GigInfo(
    emoji: '📝',
    title: 'Upwork',
    earning: 'Find freelance projects',
    description: 'Get paid in USD',
    buttonLabel: 'Explore →',
    url: 'https://www.upwork.com',
  ),
];

List<GigInfo> gigsForProfile(String profileType) => switch (profileType) {
      'employed' => _employedGigs,
      'unemployed' => _unemployedGigs,
      _ => _pelajarGigs,
    };

// ─── Card widget ──────────────────────────────────────────────────────────────

class GigCard extends StatelessWidget {
  final GigInfo gig;
  const GigCard({super.key, required this.gig});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gig.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 10),
          Text(
            gig.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            gig.earning,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            gig.description,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _launch(gig.url),
              style: OutlinedButton.styleFrom(
                side:
                    const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                gig.buttonLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
