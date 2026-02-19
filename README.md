# CoinHabit (version)

Gamified savings app built with Flutter + Supabase.

## Run the app

1. Install Flutter SDK and project dependencies:
	 - `flutter pub get`
2. Add your environment values in `.env` (see `.env.example` if present).
3. Launch:
	 - `flutter run`

## Supabase backend scaffolding

This repository includes:

- SQL migrations in `supabase/migrations/`
	- `20260218_production_core_schema.sql`
	- `20260219_phase4_rpc_scaffold.sql`
- Edge Functions in `supabase/functions/`
	- `process-checkin`
	- `process-deposit`

### Local Supabase workflow

From the project root:

- Start local Supabase: `supabase start`
- Apply migrations: `supabase db reset`
- Serve Edge Functions: `supabase functions serve`

### Deploy functions

- `supabase functions deploy process-checkin`
- `supabase functions deploy process-deposit`

## Notes

- App logic prefers RPCs (`process_checkin`, `process_deposit`) and gracefully falls back in the Flutter repositories when unavailable.
- Weekly chart data uses `get_weekly_savings` RPC, with client-side fallback aggregation if RPC is not deployed.
