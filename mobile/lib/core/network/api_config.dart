/// Base URL of the GMAO backend API.
///
/// - Android emulator: use 10.0.2.2 to reach the host machine's localhost.
/// - Physical device: use your machine's LAN IP (e.g. http://192.168.1.10:8000/api).
/// - iOS simulator / desktop / web: http://127.0.0.1:8000/api works directly.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);

const String apiOrigin = String.fromEnvironment(
  'API_ORIGIN',
  defaultValue: 'http://10.0.2.2:8000',
);
