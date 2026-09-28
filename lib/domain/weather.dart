/// A simple forecast for the Today header pill. Travary has no weather
/// service yet: screens take one as an optional input and otherwise show
/// the date or a countdown.
class WeatherReport {
  const WeatherReport({required this.temperature, required this.condition});

  /// Whole degrees, in the unit the source reports.
  final int temperature;
  final WeatherCondition condition;
}

enum WeatherCondition {
  sunny('Sunny'),
  cloudy('Cloudy'),
  rain('Rain'),
  snow('Snow');

  const WeatherCondition(this.label);

  final String label;
}
