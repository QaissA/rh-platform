import '../../../core/error/result.dart';
import '../../auth/domain/entities/user.dart';
import 'entities/team_member.dart';

abstract class PeopleDirectory {
  Future<Result<Map<int, TeamMember>>> load();

  TeamMember? get(int id);

  String nameOf(int id);

  String? jobTitleOf(int id);

  String initialsOf(int id);

  TeamMember toMember(User user);
}
