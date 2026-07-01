/// Copy this file to supabase_config.dart and fill in your project's values
/// (Supabase dashboard → Project Settings → API).
///
/// supabase_config.dart is gitignored — these values are specific to your
/// own free Supabase project, not secrets, but kept out of version control
/// so each dev/deployment points at their own backend.
class SupabaseConfig {
  static const url = 'https://YOUR_PROJECT_REF.supabase.co';
  static const anonKey = 'YOUR_ANON_PUBLIC_KEY';

  /// False while the placeholder values above haven't been replaced yet.
  /// The app uses this to fall back to bundled demo data instead of trying
  /// (and failing) to reach a Supabase project that doesn't exist.
  static const isConfigured = url != 'https://YOUR_PROJECT_REF.supabase.co';
}
