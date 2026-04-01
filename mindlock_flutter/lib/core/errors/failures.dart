import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.code});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Session expired. Please log in again.', super.code = 401});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;
  const ValidationFailure({required super.message, this.errors, super.code = 422});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Resource not found', super.code = 404});
}

class EntitlementFailure extends Failure {
  const EntitlementFailure({super.message = 'Pro feature required', super.code = 403});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unexpected error occurred', super.code});
}
