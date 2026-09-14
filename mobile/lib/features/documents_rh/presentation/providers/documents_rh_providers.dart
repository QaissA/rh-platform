import 'dart:async';

import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DocumentsRhFilter { open, all }

class DocumentsRhState {
  const DocumentsRhState({
    this.loading = true,
    this.filter = DocumentsRhFilter.open,
    this.requests = const [],
    this.busyId,
    this.rejectingId,
  });

  final bool loading;
  final DocumentsRhFilter filter;
  final List<DocumentRequest> requests;
  final int? busyId;
  final int? rejectingId;

  int get openCount => requests.where((r) => r.status.isOpen).length;

  List<DocumentRequest> get openRows =>
      requests.where((r) => r.status.isOpen).toList(growable: false);

  List<DocumentRequest> get readyRows => requests
      .where((r) => r.status == DocumentStatus.ready)
      .toList(growable: false);

  List<DocumentRequest> get closedRows => requests
      .where(
        (r) =>
            r.status == DocumentStatus.rejected ||
            r.status == DocumentStatus.cancelled,
      )
      .toList(growable: false);

  DocumentsRhState copyWith({
    bool? loading,
    DocumentsRhFilter? filter,
    List<DocumentRequest>? requests,
    int? busyId,
    int? rejectingId,
    bool clearBusy = false,
    bool clearRejecting = false,
  }) {
    return DocumentsRhState(
      loading: loading ?? this.loading,
      filter: filter ?? this.filter,
      requests: requests ?? this.requests,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      rejectingId: clearRejecting ? null : (rejectingId ?? this.rejectingId),
    );
  }
}

final documentsRhControllerProvider =
    NotifierProvider<DocumentsRhController, DocumentsRhState>(
  DocumentsRhController.new,
);

class DocumentsRhController extends Notifier<DocumentsRhState> {
  bool _disposed = false;

  @override
  DocumentsRhState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_fetch(DocumentsRhFilter.open));
    return const DocumentsRhState();
  }

  Future<void> reload({bool showSpinner = true}) async {
    if (showSpinner) {
      state = state.copyWith(loading: true);
    }
    await _fetch(state.filter);
  }

  Future<void> setFilter(DocumentsRhFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(
      filter: filter,
      loading: true,
      clearRejecting: true,
    );
    await _fetch(filter);
  }

  Future<void> _fetch(DocumentsRhFilter filter) async {
    await ref.read(peopleDirectoryProvider).load();
    if (_disposed) return;
    final result = await ref.read(documentRepositoryProvider).getInbox();
    if (_disposed) return;
    final list = result.data ?? state.requests;
    state = state.copyWith(
      loading: false,
      requests: filter == DocumentsRhFilter.open
          ? list.where((r) => r.status.isOpen).toList(growable: false)
          : list,
    );
  }

  void askReject(int id) {
    state = state.copyWith(rejectingId: id);
  }

  void cancelReject() {
    state = state.copyWith(clearRejecting: true);
  }

  Future<Result<DocumentRequest>> reject(int id, {String? comment}) async {
    state = state.copyWith(busyId: id);
    final result = await ref.read(documentRepositoryProvider).reject(
          id,
          comment: comment,
        );
    if (_disposed) return result;
    if (result.isOk) {
      state = state.copyWith(clearBusy: true, clearRejecting: true);
      await reload(showSpinner: false);
      if (!_disposed) {
        await ref.read(inboxBadgeProvider.notifier).refresh();
      }
    } else {
      state = state.copyWith(clearBusy: true);
    }
    return result;
  }
}
