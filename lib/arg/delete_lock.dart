import 'arg.dart';

class DeleteLock extends Argument<bool> {
  @override
  String? get abbr => null;

  @override
  bool get defaultsTo => false;

  @override
  String get help => 'Whether delete lock file';

  @override
  String get name => 'delete-lock';
}
