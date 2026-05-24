# Spendly 💸

**Spendly** is an AI-powered personal finance tracker app built with Flutter and Firebase, designed to help Malaysians manage their money smarter. It features real-time expense tracking, intelligent budget planning, financial health scoring, streak-based motivation, and gig income suggestions — all in a clean, modern UI.

> Built by **CukruDev404** for Hackathon UMP 2026.

---

## Features

- 🔐 **Authentication** — Email/password sign-up, login, and password reset via Firebase Auth
- 👤 **Profile Setup** — Onboarding flow with profile type (Student / Employed / Unemployed), monthly budget, and saving target
- 💳 **Expense Tracker** — Add, edit, and delete expenses with category chips, date picker, and optional notes
- 🧾 **Receipt Scanner** — Scan physical receipts using Google ML Kit OCR; auto-extracts amount, merchant, and date (fully offline)
- 📊 **Dashboard** — Monthly spending overview with interactive charts, recent transactions, streak chip, and profile shortcut
- 🗂️ **Budget Planner** — AI-generated (Gemini) or locally computed budget breakdown per category; syncs category list to Add Expense screen
- ❤️ **Financial Health Score** — Monthly score (0–100) based on budget adherence, saving progress, and spending consistency; includes trend and personalised tips
- 🔔 **Overspending Alerts** — Local push notifications when a category hits 80% or 100% of its budget; tapping notification navigates to Profile
- 🔥 **Rewards & Streak System** — TikTok-style daily streak tracking; badges for milestones (First Step, 7-Day, 30-Day Streak, Budget Master, Saving Hero, Health Champion)
- 💡 **Smart Suggestions** — Local algorithm generates 2–3 personalised spending tips per month based on actual spending data (no API required)
- 💰 **Earn Extra Income** — Profile-aware gig card recommendations (Grab, Lalamove, Fiverr, Carousell, Upwork); highlighted with warning banner when overspending is detected

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3) |
| Backend / Database | Firebase (Auth + Firestore) |
| State Management | Riverpod 2.x (flutter_riverpod) |
| Navigation | Go Router 14 |
| AI / Budget | Gemini 2.0 Flash Lite (REST API via `http`) |
| OCR | Google ML Kit Text Recognition (offline) |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| URL Handling | url_launcher |
| Fonts | Google Fonts (Poppins) |
| Environment | flutter_dotenv (.env file) |

---

## Firestore Database Schema

```
users/
  {uid}/                          ← created on registration
    name: String
    email: String
    profileType: String           ← "student" | "employed" | "unemployed"
    monthlyBudget: Number
    savingTarget: Number
    profileCompletedAt: Timestamp

    transactions/
      {txId}/
        amount: Number
        category: String          ← e.g. "Food", "Transport"
        note: String?
        date: Timestamp
        source: String            ← "manual" | "receipt"
        createdAt: Timestamp (server)

    budgets/
      {YYYY-MM}/                  ← e.g. "2025-05"
        month: String
        generatedAt: Timestamp (server)
        isAIGenerated: Boolean
        categories: Array
          [
            {
              category: String,   ← e.g. "Food"
              icon: String,       ← icon key e.g. "restaurant"
              amount: Number,
              color: String,      ← hex e.g. "#FF6B6B"
              spent: Number       ← always 0 on write; computed at runtime
            }
          ]

    healthScores/
      {YYYY-MM}/
        month: String
        score: Number             ← 0–100
        status: String            ← "Excellent" | "Good" | "Fair" | "Needs Improvement"
        budgetAdherence: Number   ← 0–40
        savingProgress: Number    ← 0–35
        spendingConsistency: Number  ← 0–25
        trend: String             ← "improving" | "stable" | "declining"
        tips: Array<String>
        calculatedAt: Timestamp

    rewards/
      data/
        currentStreak: Number
        longestStreak: Number
        lastRecordedDate: Timestamp
        badges: Array
          [
            {
              id: String,         ← e.g. "first_step", "streak_7", "budget_master_2025-05"
              name: String,
              earnedAt: Timestamp
            }
          ]

    alerts/
      {YYYY-MM}/
        {alertKey}: Timestamp     ← key e.g. "cat_Food_100", "overall_80"
                                  ← value is server timestamp (dedup sentinel)
```

---

## Project Structure

```
lib/
├── main.dart                     ← App entry point, Firebase init, notification setup
├── firebase_options.dart         ← Generated Firebase config
├── core/
│   ├── constants/app_colors.dart ← Colour palette & gradient constants
│   ├── router/app_router.dart    ← GoRouter config, all named routes
│   └── utils/snackbars.dart      ← Success / error snackbar helpers
├── models/
│   ├── budget_model.dart         ← BudgetModel, BudgetCategory
│   ├── expense_model.dart        ← ExpenseModel, ExpenseCategory, kCategories
│   ├── health_score_model.dart   ← HealthScoreModel
│   ├── receipt_data.dart         ← ReceiptData (OCR output)
│   └── reward_model.dart         ← RewardData, EarnedBadge, BadgeDefinition
├── providers/
│   ├── auth_provider.dart        ← authStateProvider, userNameProvider
│   ├── budget_provider.dart      ← currentBudgetProvider, BudgetNotifier
│   ├── expense_provider.dart     ← expensesStreamProvider, categoryListProvider
│   ├── health_score_provider.dart
│   ├── profile_provider.dart     ← userProfileProvider, ProfileSetupNotifier
│   ├── receipt_provider.dart     ← receiptScannerProvider, ScannerState
│   ├── reward_provider.dart      ← rewardStreamProvider, RewardNotifier
│   └── suggestion_provider.dart  ← suggestionProvider (derived)
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── onboarding/profile_setup_screen.dart
│   ├── home/home_screen.dart     ← Dashboard (charts, streak chip, profile button)
│   ├── expense/
│   │   ├── add_expense_screen.dart
│   │   ├── edit_expense_screen.dart
│   │   ├── expense_list_screen.dart
│   │   ├── receipt_scanner_screen.dart
│   │   └── receipt_preview_screen.dart
│   ├── budget/
│   │   ├── budget_screen.dart
│   │   └── budget_review_screen.dart
│   ├── health/health_score_screen.dart
│   ├── profile/profile_screen.dart  ← Edit icon, gig cards, red sign out
│   ├── rewards/rewards_screen.dart  ← TikTok-style streak, no-spend button
│   └── settings/edit_profile_screen.dart
├── services/
│   ├── ai_service.dart           ← Gemini API (budget generation only)
│   ├── alert_service.dart        ← Budget alert detection + local notifications
│   ├── auth_service.dart
│   ├── budget_service.dart
│   ├── expense_service.dart
│   ├── health_score_service.dart ← Score calculation algorithm
│   ├── ocr_service.dart          ← ML Kit OCR + receipt text parser (offline)
│   ├── profile_service.dart
│   ├── reward_service.dart       ← Streak logic + badge award engine
│   └── suggestion_service.dart   ← Local spending suggestion algorithm
└── widgets/
    ├── bottom_nav_bar.dart       ← Custom FAB bottom nav (Home/Expenses/Budget/Rewards)
    ├── budget_card.dart
    ├── gig_card.dart             ← GigInfo model + horizontal gig cards
    ├── gradient_button.dart
    ├── health_score_card.dart
    ├── main_shell.dart           ← Shell scaffold with bottom nav
    ├── recent_transactions.dart
    ├── spending_alert_banner.dart
    ├── suggestions_card.dart     ← Smart suggestions card (home screen)
    └── swipeable_chart.dart      ← Bar / line chart with swipe toggle
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.11.4`
- Android Studio or VS Code with Flutter extension
- A Firebase project with **Authentication** (Email/Password) and **Firestore** enabled
- *(Optional)* A Gemini API key for AI budget generation

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/spendly.git
   cd spendly
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Download `google-services.json` from your Firebase project console
   - Place it at `android/app/google-services.json`
   - See `android/app/google-services.json.example` for the expected structure

4. **Set up environment variables**
   - Create a `.env` file in the project root:
     ```
     GEMINI_API_KEY=your_gemini_api_key_here
     ```
   - If the key is omitted, budget generation falls back to a local algorithm automatically

5. **Run the app**
   ```bash
   flutter run
   ```

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GEMINI_API_KEY` | Optional | Gemini 2.0 Flash Lite API key for AI budget generation. Falls back to a built-in local algorithm if not set. |

The `.env` file is listed in `.gitignore` and will not be committed to the repository.

---

## Team

**CukruDev404** — Hackathon UMP 2026
