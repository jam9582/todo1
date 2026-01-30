import 'package:isar/isar.dart';

part 'daily_record.g.dart';

@collection
class DailyRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late String date;

  String? message;

  List<TimeEntry>? timeRecords;

  List<CheckEntry>? checkRecords;

  DailyRecord({
    this.date = '',
    this.message,
    this.timeRecords,
    this.checkRecords,
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

@embedded
class CheckEntry {
  late int checkBoxId;

  late bool isCompleted;

  CheckEntry({
    this.checkBoxId = 0,
    this.isCompleted = false,
  });
}
