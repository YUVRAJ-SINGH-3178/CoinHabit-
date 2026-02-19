# CoinHabit

CoinHabit is a professional, gamified savings app built with Flutter and Supabase. It helps users build consistent habits with goals, streaks, rewards, and weekly insights.

## Highlights

- Goal tracking with deposits and milestones
- Daily check-in streaks and rewards
- Leaderboard, badges, and progress charts
- Offline queueing with automatic sync
- Push notifications and reminders

## Quick Start

### Prerequisites

- Flutter SDK (stable)
- Android Studio or VS Code
- Supabase CLI (optional, for local backend)

### Install & Run

1. Install dependencies
   - `flutter pub get`
2. Configure environment
   - Copy `.env.example` to `.env` and fill in values
3. Launch
   - `flutter run`

## Configuration

Set the following in `.env`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Supabase Backend

This repo includes:

- SQL migrations in `supabase/migrations/`
- Edge Functions in `supabase/functions/`

### Local Supabase Workflow

- Start local Supabase: `supabase start`
- Apply migrations: `supabase db reset`
- Serve Edge Functions: `supabase functions serve`

### Deploy Functions

- `supabase functions deploy process-checkin`
- `supabase functions deploy process-deposit`

## Architecture Notes

- RPCs are preferred (`process_checkin`, `process_deposit`) with client-side fallback
- Weekly chart data uses `get_weekly_savings` RPC with fallback aggregation

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- [SECURITY.md](SECURITY.md)
- [PRIVACY_POLICY.md](PRIVACY_POLICY.md)
- [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md)
- [DATA_REQUESTS.md](DATA_REQUESTS.md)

## License

All rights reserved unless explicitly stated otherwise.
