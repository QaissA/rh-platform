import 'dart:async';

import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/documents/data/datasources/document_remote.dart';
import 'package:alize_mobile/features/documents/data/repositories/document_repository_impl.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
import 'package:alize_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final documentRemoteProvider = Provider<DocumentRemote>(
  (ref) => DocumentRemote(ref.watch(dioProvider)),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepositoryImpl(remote: ref.watch(documentRemoteProvider)),
);

class DocumentsViewState {
  const DocumentsViewState({
    this.loading = true,
    this.submitting = false,
    this.formOpen = false,
    this.busyId,
    this.requests = const [],
  });

  final bool loading;
  final bool submitting;
  final bool formOpen;
  final int? busyId;
  final List<DocumentRequest> requests;

  DocumentsViewState copyWith({
    bool? loading,
    bool? submitting,
    bool? formOpen,
    int? busyId,
    bool clearBusyId = false,
    List<DocumentRequest>? requests,
  }) {
    return DocumentsViewState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      formOpen: formOpen ?? this.formOpen,
      busyId: clearBusyId ? null : (busyId ?? this.busyId),
      requests: requests ?? this.requests,
    );
  }
}

final documentsControllerProvider =
    NotifierProvider<DocumentsController, DocumentsViewState>(
  DocumentsController.new,
);

class DocumentsController extends Notifier<DocumentsViewState> {
  bool _disposed = false;

  @override
  DocumentsViewState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const DocumentsViewState();
  }

  Future<void> reload() => _load(showSpinner: true);

  Future<void> _load({bool showSpinner = false}) async {
    if (showSpinner) {
      state = state.copyWith(loading: true);
    }
    final result = await ref.read(documentRepositoryProvider).getRequests();
    if (_disposed) return;
    state = state.copyWith(
      loading: false,
      requests: result.data ?? state.requests,
    );
  }

  void toggleForm() => state = state.copyWith(formOpen: !state.formOpen);

  void closeForm() => state = state.copyWith(formOpen: false);

  Future<Result<DocumentRequest>> submit(NewDocumentRequest request) async {
    state = state.copyWith(submitting: true);
    final result = await ref.read(documentRepositoryProvider).create(request);
    if (_disposed) return result;
    if (result.isOk) {
      state = state.copyWith(submitting: false, formOpen: false);
      await reload();
    } else {
      state = state.copyWith(submitting: false);
    }
    return result;
  }

  Future<Result<DocumentRequest>> cancel(int id) async {
    if (state.busyId == id) {
      return Result.ok(state.requests.firstWhere((r) => r.id == id));
    }
    state = state.copyWith(busyId: id);
    final result = await ref.read(documentRepositoryProvider).cancel(id);
    if (_disposed) return result;
    if (result.isOk && result.data != null) {
      state = state.copyWith(
        clearBusyId: true,
        requests: [
          for (final row in state.requests)
            if (row.id == result.data!.id) result.data! else row,
        ],
      );
    } else {
      state = state.copyWith(clearBusyId: true);
    }
    return result;
  }
}
