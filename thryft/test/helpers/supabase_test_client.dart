import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Test Supabase client
//
// Pass credentials in at test-run time with --dart-define so we never
// hard-code keys in source. Example:
//
//   flutter test \
//     --dart-define=TEST_SUPABASE_URL=https://xxx.supabase.co \
//     --dart-define=TEST_SUPABASE_ANON_KEY=sb_publishable_...
//
// The client is a singleton — Supabase.initialize() can only be called once
// per Dart isolate, so we guard it with a bool flag.
// ---------------------------------------------------------------------------

const _url = String.fromEnvironment('TEST_SUPABASE_URL');
const _anonKey = String.fromEnvironment('TEST_SUPABASE_ANON_KEY');

bool _initialised = false;

/// Returns a [SupabaseClient] connected to the test Supabase project.
///
/// Safe to call from [setUpAll] in multiple test files — initialisation only
/// runs once per test process.
Future<SupabaseClient> getTestClient() async {
  assert(
    _url.isNotEmpty && _anonKey.isNotEmpty,
    'Missing test credentials.\n'
    'Run tests with:\n'
    '  flutter test \\\n'
    '    --dart-define=TEST_SUPABASE_URL=<url> \\\n'
    '    --dart-define=TEST_SUPABASE_ANON_KEY=<key>',
  );

  if (!_initialised) {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
    _initialised = true;
  }

  return Supabase.instance.client;
}
