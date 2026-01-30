import 'package:isar/isar.dart';

part 'check_box.g.dart';

@collection
class CheckBox {
  Id id = Isar.autoIncrement;

  late String name;

  late int order;

  CheckBox({
    this.name = '',
    this.order = 0,
  });
}
