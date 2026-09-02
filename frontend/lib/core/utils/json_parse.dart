// lib/core/utils/json_parse.dart
//
// Small helpers shared by every model's fromJson.
//
// Two things here are specific to how this backend talks:
//
//  * Ids are integers on the wire (Postgres BIGINT). The app only ever passes
//    them around and puts them in URLs, so we keep them as String and convert
//    once, here, instead of sprinkling int/String casts through the UI.
//
//  * Business dates (serviceDate, period, joinedDate, startDate, endDate) are
//    plain calendar days - 'YYYY-MM-DD' with no time and no zone. They must
//    NOT go through DateTime.parse and local-time conversion, or a date can
//    slide by a day. Keep them as strings; use [parseCalendarDate] only when
//    you need to do date arithmetic, and note it returns a UTC-midnight
//    DateTime purely so the arithmetic is stable.

/// Ids arrive as integers; the app treats them as opaque strings.
String asId(dynamic value) => value?.toString() ?? '';

String? asNullableId(dynamic value) => value?.toString();

double? asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool asBool(dynamic value) =>
    value == true || (value is String && value.toLowerCase() == 'true');

List<String> asStringList(dynamic value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return const <String>[];
}

/// A plain calendar date as the backend sent it: 'YYYY-MM-DD'.
/// Postgres DATE columns serialise as a full ISO timestamp in some drivers, so
/// trim anything after the day rather than trusting the whole string.
String? asCalendarDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}

/// Parses a calendar date for arithmetic/comparison only. UTC on purpose:
/// these are days, not instants, and local-time parsing is what causes
/// off-by-one-day display bugs.
DateTime? parseCalendarDate(dynamic value) {
  final text = asCalendarDate(value);
  if (text == null || text.isEmpty) return null;
  final parts = text.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime.utc(year, month, day);
}

/// Formats a DateTime as the 'YYYY-MM-DD' the backend expects in request
/// bodies and query strings.
String formatCalendarDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Audit timestamps (createdAt / updatedAt) ARE real instants, so these go
/// through normal parsing.
DateTime? parseTimestamp(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
