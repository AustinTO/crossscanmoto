/// Unit conversions for values returned by a decoded, ECU-backed definition.
/// No sensor readings, ranges, nominal values or DID assignments are guessed.
abstract final class BmwUnitConverter {
  static double toImperial(double metric, String unit) => switch (unit) {
        '°C' => metric * 9 / 5 + 32,
        'km/h' || 'km' => metric * 0.621371,
        'bar' => metric * 14.5038,
        _ => metric,
      };
}
