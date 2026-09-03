# To Do App

A Flutter task and assignment planner built for keeping coursework and everyday work in one place. It supports a fast local-first experience and can sync data securely with Supabase when configured.

## Features

- Create, edit, complete, filter, and delete tasks with priorities and due dates.
- Track assignments by platform, priority, submission status, and deadline.
- See tasks and assignments together in a monthly calendar.
- View today's work, upcoming assignments, and task progress from the home dashboard.
- Receive local deadline reminders for tasks and pending assignments.
- Sign up, sign in, reset passwords, and use Google or Apple sign-in through Supabase.
- Cache tasks and assignments locally for a responsive offline experience.
- Select light, dark, or system theme, and optionally sign out after inactivity.

## Tech stack

- [Flutter](https://flutter.dev/) and Dart
- [Riverpod](https://riverpod.dev/) for state management
- [Supabase](https://supabase.com/) for authentication and cloud data
- Drift / SQLite for local persistence
- `flutter_local_notifications` for reminders

## Prerequisites

- Flutter SDK (stable channel)
- A Supabase project for authentication and cloud sync (optional for local-only use)

## Getting started

1. Clone the repository and open the project folder.

   ```bash
   git clone https://github.com/VenkatalakshmiRM/to-do-app.git
   cd to-do-app
   ```

2. Install dependencies.

   ```bash
   flutter pub get
   ```

3. To enable Supabase, create a `.env` file in the project root. This file is intentionally ignored by Git.

   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

4. Apply the database migration in `supabase/migrations/` to your Supabase project.

5. Run the app.

   ```bash
   flutter run
   ```

## Authentication setup

Email/password authentication works once Supabase is configured. For Google and Apple OAuth, follow the detailed provider and redirect URL setup in [AUTH_PROVIDER_SETUP.md](AUTH_PROVIDER_SETUP.md).

## Verification

Run the test suite with:

```bash
flutter test
```

For static analysis:

```bash
flutter analyze
```

## Security notes

- Never commit `.env` or real API keys.
- Use only the Supabase **anon** key in the client app; never expose a service-role key.
- The app stores authenticated sessions using OS-backed secure storage.

## Project structure

```text
lib/
  models/       Task and assignment data models
  screens/      Authentication, task, assignment, calendar, and profile UI
  services/     Supabase, local database, notifications, and preferences
  state/        Riverpod providers and application state
  theme/        App theming
  widgets/      Shared interface components
supabase/
  migrations/   Database schema migrations
test/           Unit and widget tests
```

