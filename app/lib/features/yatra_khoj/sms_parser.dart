/// On-device SMS/email parser for journey detection.
/// Parses IRCTC confirmation messages to extract PNR, train number,
/// boarding/destination stations, berth info, and journey date.
class SMSParser {
  static final _pnrPattern = RegExp(r'PNR[:\s]*(\d{10})', caseSensitive: false);
  static final _trainPattern =
      RegExp(r'Train[:\s]*(\d{5})', caseSensitive: false);
  static final _datePattern =
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})', caseSensitive: false);
  static final _berthPattern =
      RegExp(r'(S\d+|B\d+|[SRUL]\d+|RAC\s*\d+)', caseSensitive: false);
  static final _stationPattern =
      RegExp(r'([A-Z]{2,5})\s*to\s*([A-Z]{2,5})', caseSensitive: false);

  /// Parse a single SMS message body and return extracted journey details.
  static Map<String, String?> parse(String message) {
    final result = <String, String?>{};

    final pnrMatch = _pnrPattern.firstMatch(message);
    result['pnr'] = pnrMatch?.group(1);

    final trainMatch = _trainPattern.firstMatch(message);
    result['train_number'] = trainMatch?.group(1);

    final dateMatch = _datePattern.firstMatch(message);
    result['journey_date'] = dateMatch?.group(1);

    final berthMatch = _berthPattern.firstMatch(message);
    result['berth_info'] = berthMatch?.group(1);

    final stationMatch = _stationPattern.firstMatch(message);
    result['boarding_station'] = stationMatch?.group(1);
    result['destination_station'] = stationMatch?.group(2);

    return result;
  }

  /// Check if a message looks like an IRCTC booking confirmation.
  static bool isBookingMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('irctc') ||
        lower.contains('pnr') ||
        (lower.contains('train') && lower.contains('booked'));
  }
}
