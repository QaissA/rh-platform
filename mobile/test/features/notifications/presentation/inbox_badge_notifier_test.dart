import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
import 'package:alize_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_balance.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:alize_mobile/features/leave/domain/repositories/leave_repository.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

User _user(String role) => User(
      id: 1,
      email: 'a@b.com',
      role: role,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );

class ScriptedAuth extends AuthNotifier {
  ScriptedAuth(this.role);

  final String role;

  @override
  AuthState build() => AuthSignedIn(Session(token: 'jwt', user: _user(role)));

  void signOut() => state = const AuthSignedOut();
}

class FakeLeaveRepository implements LeaveRepository {
  FakeLeaveRepository({this.team = const [], this.teamResult});

  List<LeaveRequest> team;
  Result<List<LeaveRequest>>? teamResult;
  List<LeaveStatus>? lastStatus;
  int teamCalls = 0;

  @override
  Future<Result<LeaveBalance>> getBalance() async =>
      const Result.ok(LeaveBalance(userId: 1, daysRemaining: 0));

  @override
  Future<Result<List<LeaveRequest>>> getMyRequests() async =>
      const Result.ok([]);

  @override
  Future<Result<LeaveRequest>> create(NewLeaveRequest request) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<List<LeaveRequest>>> getTeamRequests({
    List<LeaveStatus>? status,
  }) async {
    teamCalls++;
    lastStatus = status;
    return teamResult ?? Result.ok(team);
  }

  @override
  Future<Result<LeaveRequest>> approve(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<LeaveRequest>> reject(int id, {String? comment}) async =>
      const Result.err(Failure.network());
}

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({this.inbox = const [], this.inboxResult});

  List<DocumentRequest> inbox;
  Result<List<DocumentRequest>>? inboxResult;
  int inboxCalls = 0;

  @override
  Future<Result<List<DocumentRequest>>> getRequests() async =>
      const Result.ok([]);

  @override
  Future<Result<List<DocumentRequest>>> getInbox({String? status}) async {
    inboxCalls++;
    return inboxResult ?? Result.ok(inbox);
  }

  @override
  Future<Result<DocumentRequest>> create(NewDocumentRequest request) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> getRequest(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> cancel(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> update(
    int id, {
    Map<String, String>? fields,
    String? status,
    String? decisionComment,
  }) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> reject(int id, {String? comment}) async =>
      const Result.err(Failure.network());
}

LeaveRequest _leave(int id, LeaveStatus status) => LeaveRequest(
      id: id,
      userId: 8,
      startDate: '2026-09-15',
      endDate: '2026-09-17',
      status: status,
    );

DocumentRequest _doc(int id, DocumentStatus status) => DocumentRequest(
      id: id,
      userId: 8,
      docType: 'work_certificate',
      status: status,
    );

void main() {
  late FakeLeaveRepository leave;
  late FakeDocumentRepository docs;
  late ScriptedAuth auth;

  ProviderContainer createContainer(String role) {
    auth = ScriptedAuth(role);
    leave = FakeLeaveRepository(
      team: [
        _leave(1, LeaveStatus.pending),
        _leave(2, LeaveStatus.pending),
        _leave(3, LeaveStatus.pendingHr),
      ],
    );
    docs = FakeDocumentRepository(
      inbox: [
        _doc(11, DocumentStatus.pending),
        _doc(12, DocumentStatus.processing),
        _doc(13, DocumentStatus.ready),
        _doc(14, DocumentStatus.cancelled),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => auth),
        leaveRepositoryProvider.overrideWithValue(leave),
        documentRepositoryProvider.overrideWithValue(docs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('manager counts pending leave only and skips the doc inbox', () async {
    final container = createContainer('manager');

    await container.read(inboxBadgeProvider.notifier).refresh();

    expect(leave.lastStatus, [LeaveStatus.pending]);
    expect(leave.teamCalls, 1);
    expect(docs.inboxCalls, 0);
    expect(container.read(inboxBadgeProvider).leaveQueue, 3);
    expect(container.read(inboxBadgeProvider).docQueue, 0);
  });

  test('rh counts pending_hr leave and pending+processing docs', () async {
    final container = createContainer('rh');

    await container.read(inboxBadgeProvider.notifier).refresh();

    expect(leave.lastStatus, [LeaveStatus.pendingHr]);
    expect(docs.inboxCalls, 1);
    expect(container.read(inboxBadgeProvider).leaveQueue, 3);
    expect(container.read(inboxBadgeProvider).docQueue, 2);
  });

  test('admin counts pending+pending_hr leave and pending+processing docs',
      () async {
    final container = createContainer('admin');

    await container.read(inboxBadgeProvider.notifier).refresh();

    expect(
      leave.lastStatus,
      [LeaveStatus.pending, LeaveStatus.pendingHr],
    );
    expect(docs.inboxCalls, 1);
    expect(container.read(inboxBadgeProvider).leaveQueue, 3);
    expect(container.read(inboxBadgeProvider).docQueue, 2);
  });

  test('employee leaves both queues at 0 without calling APIs', () async {
    final container = createContainer('employee');

    await container.read(inboxBadgeProvider.notifier).refresh();

    expect(leave.teamCalls, 0);
    expect(docs.inboxCalls, 0);
    expect(container.read(inboxBadgeProvider).leaveQueue, 0);
    expect(container.read(inboxBadgeProvider).docQueue, 0);
  });

  test('failures set the matching queue to 0', () async {
    final container = createContainer('admin');
    leave.teamResult = const Result.err(Failure.network());
    docs.inboxResult = const Result.err(Failure.server(status: 500));

    await container.read(inboxBadgeProvider.notifier).refresh();

    expect(container.read(inboxBadgeProvider).leaveQueue, 0);
    expect(container.read(inboxBadgeProvider).docQueue, 0);
  });

  test('logout clears both queues', () async {
    final container = createContainer('rh');
    await container.read(inboxBadgeProvider.notifier).refresh();
    expect(container.read(inboxBadgeProvider).leaveQueue, 3);
    expect(container.read(inboxBadgeProvider).docQueue, 2);

    auth.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(inboxBadgeProvider).leaveQueue, 0);
    expect(container.read(inboxBadgeProvider).docQueue, 0);
  });
}
