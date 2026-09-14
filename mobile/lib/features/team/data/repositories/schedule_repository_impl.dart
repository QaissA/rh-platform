import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/team/data/datasources/schedule_remote.dart';
import 'package:alize_mobile/features/team/domain/entities/new_presence.dart';
import 'package:alize_mobile/features/team/domain/entities/schedule_entry.dart';
import 'package:alize_mobile/features/team/domain/repositories/schedule_repository.dart';
import 'package:dio/dio.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({required ScheduleRemote remote}) : _remote = remote;

  final ScheduleRemote _remote;

  @override
  Future<Result<ScheduleSnapshot>> getSchedule({
    required String start,
    required String end,
  }) =>
      _guard(() async => (await _remote.getSchedule(start: start, end: end)).toDomain());

  @override
  Future<Result<List<ScheduleEntry>>> declarePresence(NewPresence presence) =>
      _guard(
        () async => (await _remote.declarePresence(presence))
            .map((e) => e.toDomain())
            .toList(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
