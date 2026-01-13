import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String emoji;

  late String name;

  late String color;

  late int order;

  Category({
    this.emoji = '',
    this.name = '',
    this.color = '#FF5733',
    this.order = 0,
  });
}
