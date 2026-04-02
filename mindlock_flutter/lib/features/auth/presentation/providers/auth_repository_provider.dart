import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../../data/remote/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_repository_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageServiceProvider);
  final datasource = AuthRemoteDatasource(dio);
  return AuthRepository(datasource: datasource, storage: storage);
}
