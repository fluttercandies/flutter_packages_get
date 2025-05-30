import 'arg.dart';

class Sdk extends Argument<String?> {
  @override
  String? get abbr => null;

  @override
  String? get defaultsTo => null;

  @override
  String get help => 'Flutter SDK path, include flutter executable file';

  @override
  String get name => 'sdk';
}
