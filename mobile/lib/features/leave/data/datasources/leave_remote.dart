import 'package:alize_mobile/features/leave/data/models/leave_balance_dto.dart';
import 'package:alize_mobile/features/leave/data/models/leave_request_dto.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:dio/dio.dart';

class LeaveRemote {
  LeaveRemote(this._dio);

  final Dio _dio;

  Future<LeaveBalanceDto> getBalance() async {
    final response = await _dio.get<Map<String, dynamic>>('/leave/balance');
    return LeaveBalanceDto.fromJson(response.data!);
  }

  Future<List<LeaveRequestDto>> getMyRequests() async {
    final response = await _dio.get<List<dynamic>>('/leave/requests');
    return _list(response.data);
  }

  Future<LeaveRequestDto> create(NewLeaveRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/leave/requests',
      data: {
        'start_date': request.startDate,
        'end_date': request.endDate,
        'reason': ?request.reason,
      },
    );
    return LeaveRequestDto.fromJson(response.data!);
  }

  Future<List<LeaveRequestDto>> getTeamRequests({
    List<LeaveStatus>? status,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/leave/requests/team',
      queryParameters: {
        if (status != null && status.isNotEmpty)
          'status': status.map((s) => s.wire).join(','),
      },
    );
    return _list(response.data);
  }

  Future<LeaveRequestDto> approve(int id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leave/requests/$id/approve',
      data: <String, dynamic>{},
    );
    return LeaveRequestDto.fromJson(response.data!);
  }

  Future<LeaveRequestDto> reject(int id, {String? comment}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leave/requests/$id/reject',
      data: {
        'comment': ?comment,
      },
    );
    return LeaveRequestDto.fromJson(response.data!);
  }

  List<LeaveRequestDto> _list(List<dynamic>? data) {
    return (data ?? const [])
        .map(
          (e) => LeaveRequestDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
