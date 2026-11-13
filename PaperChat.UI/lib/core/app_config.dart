/// Override at run time:
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5016
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5016',
);
