import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/leave/data/datasources/leave_remote.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_balance.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:alize_mobile/features/leave/domain/repositories/leave_repository.dart';
import 'package:dio/dio.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  LeaveRepositoryImpl({required LeaveRemote remote}) : _remote = remote;

  final LeaveRemote _remote;

  @override
  Future<Result<LeaveBalance>> getBalance() => _guard(
        () async => (await _remote.getBalance()).toDomain(),
      );

  @override
  Future<Result<List<LeaveRequest>>> getMyRequests() => _guard(
        () async =>
            (await _remote.getMyRequests()).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Result<LeaveRequest>> create(NewLeaveRequest request) => _guard(
        () async => (await _remote.create(request)).toDomain(),
      );

  @override
  Future<Result<List<LeaveRequest>>> getTeamRequests({
    List<LeaveStatus>? status,
  }) =>
      _guard(
        () async => (await _remote.getTeamRequests(status: status))
            .map((e) => e.toDomain())
            .toList(),
      );

  @override
  Future<Result<LeaveRequest>> approve(int id) => _guard(
        () async => (await _remote.approve(id)).toDomain(),
      );

  @override
  Future<Result<LeaveRequest>> reject(int id, {String? comment}) => _guard(
        () async => (await _remote.reject(id, comment: comment)).toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
