// lib/core/utils/result.dart

/// A simple Result type for clean error handling without exceptions
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, {this.error});
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T> s => s.data,
        Failure<T> _ => null,
      };

  String? get errorOrNull => switch (this) {
        Success<T> _ => null,
        Failure<T> f => f.message,
      };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message) onFailure,
  }) =>
      switch (this) {
        Success<T> s => onSuccess(s.data),
        Failure<T> f => onFailure(f.message),
      };
}
