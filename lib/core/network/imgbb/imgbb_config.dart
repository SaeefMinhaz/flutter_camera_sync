/// imgBB API key. Prefer overriding via --dart-define=IMGBB_API_KEY=your_key
/// in release builds instead of committing secrets.
const String kImgBbApiKey = String.fromEnvironment(
  'IMGBB_API_KEY',
  defaultValue: '0924395ce1fbcd4ceeaeff93c28f1369',
);
