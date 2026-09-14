import 'dart:convert';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:alize_mobile/features/auth/data/datasources/auth_remote.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemote remote,
    required SessionStore sessionStore,
  })  : _remote = remote,
        _sessionStore = sessionStore;

  final AuthRemote _remote;
  final SessionStore _sessionStore;

  @override
  Future<Result<Session>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remote.login(email: email, password: password);
      await _sessionStore.save(
        token: result.token,
        userJson: jsonEncode(result.user.toJson()),
      );
      return Result.ok(
        Session(token: result.token, user: result.user.toDomain()),
      );
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }

  @override
  Future<Result<User>> me() async {
    try {
      final dto = await _remote.me();
      return Result.ok(dto.toDomain());
    } on DioException catch (e) {
      final failure = mapDio(e);
      if (failure is UnauthorizedFailure) {
        await _sessionStore.clear();
      }
      return Result.err(failure);
    }
  }

  @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final dto = await _remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return Result.ok(dto.toDomain());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
