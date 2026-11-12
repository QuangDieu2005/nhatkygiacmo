# Dream Diary - Flutter + Supabase

## What is connected
- Supabase Auth handles registration, login, persistent sessions and logout.
- `dreams` and `sleep_records` are stored in Supabase PostgreSQL.
- Each row stores `user_id`; Row Level Security (RLS) prevents users from accessing another user's rows.
- Theme preference remains local in SharedPreferences. Passwords are never stored locally.

## 1. Configure Supabase
1. Create a project at https://supabase.com (Singapore region is a reasonable choice for Vietnam).
2. In SQL Editor, run the complete `supabase_schema.sql` file.
3. In Authentication > Providers, enable Email.
4. For quick testing you may temporarily disable email confirmation in Authentication settings. For production, configure email confirmation and SMTP.
5. In Project Settings > API Keys, copy Project URL and the Publishable key (or legacy anon public key). Never use `service_role` / Secret key in a Flutter app.

## 2. Configure .env
Open the `.env` file in the project root and replace the placeholders:

```dotenv
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

The `.env` in this ZIP is a template only. It does not contain your project's credentials. Do not commit `.env` to Git. Flutter assets are bundled into the client app, so only a public/publishable key belongs here; RLS is essential.

## 3. Run
From the folder containing `pubspec.yaml`:

```powershell
flutter clean
flutter pub get
flutter run
```

Enable Windows Developer Mode if Flutter reports that plugins require symlink support.

## 4. Test
1. Register a new email in the app.
2. If email confirmation is enabled, confirm the email and then sign in.
3. Add a dream and a sleep record.
4. In Supabase Table Editor, inspect `public.dreams` and `public.sleep_records`.
5. Register a second account and confirm it cannot see the first account's rows.

## Notes
- The existing app screens and model classes are retained. `DatabaseHelper` now performs Supabase CRUD rather than SQLite/SharedPreferences storage.
- Existing data previously stored in local SQLite / SharedPreferences is not migrated automatically. Export it before removing the old app data if you need to keep it.
- No live connection can be tested until you fill in your own `.env` values and run the app on your machine.
- If signup returns a message asking you to confirm email, that is expected when Supabase email confirmation is enabled.
