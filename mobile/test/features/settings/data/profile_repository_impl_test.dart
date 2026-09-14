import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/features/settings/data/datasources/profile_remote.dart';
import 'package:alize_mobile/features/settings/data/models/user_profile_dto.dart';
import 'package:alize_mobile/features/settings/data/repositories/profile_repository_impl.dart';
import 'package:alize_mobile/features/settings/domain/entities/update_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRemote extends Mock implements ProfileRemote {}

const _profileJson = {
  'id': 1,
  'email': 'a@b.com',
  'role': 'employee',
  'team_id': 2,
  'business_unit_id': 3,
  'project_id': 4,
  'first_name': 'Ada',
  'last_name': 'Lovelace',
  'job_title': 'Engineer',
  'pending_job_title': 'Staff Engineer',
  'must_change_password': false,
  'address_line': '12 rue X',
  'postal_code': '75001',
  'city': 'Paris',
  'country': 'FR',
  'signature_png': 'data:image/png;base64,abc',
  'signature_locked': true,
};

void main() {
  late MockProfileRemote remote;
  late ProfileRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(const UpdateProfile());
  });

  setUp(() {
    remote = MockProfileRemote();
    repo = ProfileRepositoryImpl(remote: remote);
  });

  test('getMine maps snake_case profile JSON to UserProfile', () async {
    when(() => remote.getMine()).thenAnswer(
      (_) async => UserProfileDto.fromJson(_profileJson),
    );

    final result = await repo.getMine();

    expect(result.isOk, isTrue);
    final profile = result.data!;
    expect(profile.id, 1);
    expect(profile.email, 'a@b.com');
    expect(profile.role, 'employee');
    expect(profile.teamId, 2);
    expect(profile.businessUnitId, 3);
    expect(profile.projectId, 4);
    expect(profile.firstName, 'Ada');
    expect(profile.lastName, 'Lovelace');
    expect(profile.jobTitle, 'Engineer');
    expect(profile.pendingJobTitle, 'Staff Engineer');
    expect(profile.mustChangePassword, isFalse);
    expect(profile.addressLine, '12 rue X');
    expect(profile.postalCode, '75001');
    expect(profile.city, 'Paris');
    expect(profile.country, 'FR');
    expect(profile.signaturePng, 'data:image/png;base64,abc');
    expect(profile.signatureLocked, isTrue);
  });

  test('updateMine maps returned snake_case JSON and forwards payload', () async {
    const payload = UpdateProfile(
      addressLine: '1 Avenue',
      postalCode: '69001',
      city: 'Lyon',
      country: 'FR',
      pendingJobTitle: 'Lead',
      signaturePng: 'data:image/png;base64,xx',
    );
    when(() => remote.updateMine(any())).thenAnswer(
      (_) async => UserProfileDto.fromJson({
        ..._profileJson,
        'address_line': '1 Avenue',
        'postal_code': '69001',
        'city': 'Lyon',
        'country': 'FR',
        'pending_job_title': 'Lead',
        'signature_png': 'data:image/png;base64,xx',
        'signature_locked': false,
      }),
    );

    final result = await repo.updateMine(payload);

    expect(result.isOk, isTrue);
    final profile = result.data!;
    expect(profile.addressLine, '1 Avenue');
    expect(profile.postalCode, '69001');
    expect(profile.city, 'Lyon');
    expect(profile.country, 'FR');
    expect(profile.pendingJobTitle, 'Lead');
    expect(profile.signaturePng, 'data:image/png;base64,xx');
    expect(profile.signatureLocked, isFalse);
    verify(() => remote.updateMine(payload)).called(1);
  });

  test('getMine maps Dio errors through mapDio', () async {
    when(() => remote.getMine()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/profile'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/auth/profile'),
          statusCode: 401,
        ),
      ),
    );

    final result = await repo.getMine();

    expect(result.isOk, isFalse);
    expect(result.failure, isA<UnauthorizedFailure>());
  });
}
