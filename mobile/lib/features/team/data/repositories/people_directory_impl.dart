import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/team/data/datasources/users_remote.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/people_directory.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart' as format;
import 'package:alize_mobile/features/team/domain/repositories/team_repository.dart';
import 'package:dio/dio.dart';

class PeopleDirectoryImpl implements PeopleDirectory {
  PeopleDirectoryImpl({
    required TeamRepository teamRepository,
    required UsersRemote usersRemote,
    required User? Function() currentUser,
    required String Function(int id) collaboratorName,
  })  : _teamRepository = teamRepository,
        _usersRemote = usersRemote,
        _currentUser = currentUser,
        _collaboratorName = collaboratorName;

  final TeamRepository _teamRepository;
  final UsersRemote _usersRemote;
  final User? Function() _currentUser;
  final String Function(int id) _collaboratorName;

  Map<int, TeamMember> _directory = {};

  @override
  Future<Result<Map<int, TeamMember>>> load() async {
    final me = _currentUser();
    if (me?.role == 'admin' || me?.role == 'rh') {
      try {
        final users = await _usersRemote.list();
        final next = <int, TeamMember>{
          for (final user in users) user.id: toMember(user.toDomain()),
        };
        return Result.ok(_remember(next));
      } on DioException {
        return Result.ok(_remember(_selfMap(me)));
      }
    }

    final team = await _teamRepository.getMine();
    if (!team.isOk) {
      return Result.ok(_remember(_selfMap(me)));
    }
    final next = _selfMap(me);
    for (final member in team.data?.members ?? const []) {
      next[member.id] = member;
    }
    return Result.ok(_remember(next));
  }

  @override
  TeamMember? get(int id) => _directory[id];

  @override
  String nameOf(int id) {
    final member = get(id);
    return member == null ? _collaboratorName(id) : format.fullName(member);
  }

  @override
  String? jobTitleOf(int id) => format.jobTitleOf(get(id));

  @override
  String initialsOf(int id) {
    final member = get(id);
    return member == null ? '?' : format.initialsOf(member);
  }

  @override
  TeamMember toMember(User user) {
    return TeamMember(
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      jobTitle: user.jobTitle,
      pendingJobTitle: user.pendingJobTitle,
    );
  }

  Map<int, TeamMember> _selfMap(User? me) {
    final next = <int, TeamMember>{};
    if (me != null) next[me.id] = toMember(me);
    return next;
  }

  Map<int, TeamMember> _remember(Map<int, TeamMember> next) {
    _directory = next;
    return next;
  }
}
