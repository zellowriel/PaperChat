/// Override at run time with API_URL (or the legacy API_BASE_URL).
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5016',
  ),
);
