import 'package:isar/isar.dart';

part 'daily_record.g.dart';

@collection
class DailyRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late String date;

  String? message;

  List<TimeEntry>? timeRecords;

  DailyRecord({
    this.date = '',
    this.message,
    this.timeRecords,
  });
}

@embedded
class TimeEntry {
  late int categoryId;

  late int minutes;

  TimeEntry({
    this.categoryId = 0,
    this.minutes = 0,
  });
}
