import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String emoji;

  late String name;

  late int order;

  Category({
    this.emoji = '',
    this.name = '',
    this.order = 0,
  });
}
