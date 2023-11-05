import 'package:meta/meta.dart';

/// A utility for safely manipulating asynchronous data.
///
/// By using [AsyncValue], you are guaranteed that you cannot forget to
/// handle the loading/error state of an asynchronous operation.
///
/// It also exposes some utilities to nicely convert an [AsyncValue] to
/// a different object.
/// For example, a Flutter Widget may use [when] to convert an [AsyncValue]
/// into either a progress indicator, an error screen, or to show the data:
///
/// ```dart
/// /// A pod that asynchronously exposes the current user
/// final userPod = streamPod<User>((_) async* {
///   // fetch the user
/// });
///
/// class Example extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final AsyncValue<User> user = context.watch(userPod);
///
///     return user.when(
///       loading: () => CircularProgressIndicator(),
///       error: (error, stack) => Text('Oops, something unexpected happened'),
///       data: (user) => Text('Hello ${user.name}'),
///     );
///   }
/// }
/// ```
@sealed
@immutable
sealed class AsyncValue<T> {
  const AsyncValue._();

  /// Creates an [AsyncValue] with a data.
  // coverage:ignore-start
  const factory AsyncValue.data(T value) = AsyncData<T>;
  // coverage:ignore-end

  /// Creates an [AsyncValue] in loading state.
  ///
  /// Prefer always using this constructor with the `const` keyword.
  // coverage:ignore-start
  const factory AsyncValue.loading() = AsyncLoading<T>;
  // coverage:ignore-end

  /// Creates an [AsyncValue] in the error state.
  ///
  /// _I don't have a [StackTrace], what can I do?_
  /// You can still construct an [AsyncError] by passing [StackTrace.current]:
  ///
  /// ```dart
  /// AsyncValue.error(error, StackTrace.current);
  /// ```
  const factory AsyncValue.error(Object error, StackTrace stackTrace) =
      AsyncError<T>;

  /// Transforms a [Future] that may fail into something that is safe to read.
  ///
  /// We can use [guard] to simplify it:
  ///
  /// ```dart
  ///   Future<void> sideEffect() async {
  ///     state = const AsyncValue.loading();
  ///     // does the try/catch for us like previously
  ///     state = await AsyncValue.guard(() async {
  ///       final response = await dio.get('my_api/data');
  ///       return Data.fromJson(response);
  ///     });
  ///   }
  /// ```
  static Future<AsyncValue<T>> guard<T>(Future<T> Function() future) async {
    try {
      return AsyncValue.data(await future());
    } catch (err, stack) {
      return AsyncValue.error(err, stack);
    }
  }

  /// Whether some new value is currently asynchronously loading.
  ///
  /// Even if [isLoading] is true, it is still possible for [hasValue]/[hasError]
  /// to also be true.
  bool get isLoading;

  /// Whether [value] is set.
  ///
  /// Even if [hasValue] is true, it is still possible for [isLoading]/[hasError]
  /// to also be true.
  bool get hasValue;

  /// The value currently exposed.
  ///
  /// It will return the previous value during loading/error state.
  /// If there is no previous value, reading [value] during loading state will
  /// return null. While during error state, the error will be rethrown instead.
  ///
  /// If you do not want to return previous value during loading/error states,
  /// consider using [unwrapPrevious] with [valueOrNull]:
  ///
  /// ```dart
  /// ref.watch(pod).unwrapPrevious().valueOrNull;
  /// ```
  ///
  /// This will return null during loading/error states.
  T? get value;

  /// The [error].
  Object? get error;

  /// The stacktrace of [error].
  StackTrace? get stackTrace;

  String get _displayString;

  /// Perform some action based on the current state of the [AsyncValue].
  ///
  /// This allows reading the content of an [AsyncValue] in a type-safe way,
  /// without potentially ignoring to handle a case.
  R map<R>({
    required R Function(AsyncData<T> data) data,
    required R Function(AsyncError<T> error) error,
    required R Function(AsyncLoading<T> loading) loading,
  });

  /// Clone an [AsyncValue], merging it with [previous].
  ///
  /// When doing so, the resulting [AsyncValue] can contain the information
  /// about multiple state at once.
  /// For example, this allows an [AsyncError] to contain a [value], or even
  /// [AsyncLoading] to contain both a [value] and an [error].
  ///
  /// This changes the default behavior of [when] and sets the [isReloading]/
  /// [isRefreshing] flags accordingly.
  AsyncValue<T> copyWithPrevious(
    AsyncValue<T> previous, {
    bool isRefresh = true,
  });

  /// The opposite of [copyWithPrevious], reverting to the raw [AsyncValue]
  /// with no information on the previous state.
  AsyncValue<T> unwrapPrevious() {
    return map(
      data: (d) {
        if (d.isLoading) return AsyncLoading<T>();
        return AsyncData(d.value);
      },
      error: (e) {
        if (e.isLoading) return AsyncLoading<T>();
        return AsyncError(e.error, e.stackTrace);
      },
      loading: (l) => AsyncLoading<T>(),
    );
  }

  /// Transform the callback [cb] in [AsyncValue].
  AsyncValue<V> transform<V>(V Function(T value) cb);

  @override
  String toString() {
    final content = [
      if (isLoading && this is! AsyncLoading) 'isLoading: $isLoading',
      if (hasValue) 'value: $value',
      if (hasError) ...[
        'error: $error',
        'stackTrace: $stackTrace',
      ],
    ].join(', ');

    return '$_displayString<$T>($content)';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is AsyncValue<T> &&
        other.isLoading == isLoading &&
        other.hasValue == hasValue &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.valueOrNull == valueOrNull;
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        isLoading,
        hasValue,
        valueOrNull,
        error,
        stackTrace,
      );
}

/// Creates an [AsyncValue] with a data.
class AsyncData<T> extends AsyncValue<T> {
  /// Creates an [AsyncValue] with a data.
  const AsyncData(T value)
      : this._(
          value,
          isLoading: false,
          error: null,
          stackTrace: null,
        );

  const AsyncData._(
    this.value, {
    required this.isLoading,
    required this.error,
    required this.stackTrace,
  }) : super._();

  @override
  String get _displayString => 'AsyncData';

  @override
  final T value;

  @override
  bool get hasValue => true;

  @override
  final bool isLoading;

  @override
  final Object? error;

  @override
  final StackTrace? stackTrace;

  @override
  R map<R>({
    required R Function(AsyncData<T> data) data,
    required R Function(AsyncError<T> error) error,
    required R Function(AsyncLoading<T> loading) loading,
  }) {
    return data(this);
  }

  @override
  AsyncData<T> copyWithPrevious(
    AsyncValue<T> previous, {
    bool isRefresh = true,
  }) {
    return this;
  }

  @override
  AsyncValue<V> transform<V>(V Function(T value) cb) => AsyncData(cb(value));
}

/// Creates an [AsyncValue] in loading state.
///
/// Prefer always using this constructor with the `const` keyword.
class AsyncLoading<T> extends AsyncValue<T> {
  /// Creates an [AsyncValue] in loading state.
  ///
  /// Prefer always using this constructor with the `const` keyword.
  const AsyncLoading()
      : hasValue = false,
        value = null,
        error = null,
        stackTrace = null,
        super._();

  const AsyncLoading._({
    required this.hasValue,
    required this.value,
    required this.error,
    required this.stackTrace,
  }) : super._();

  @override
  String get _displayString => 'AsyncLoading';

  @override
  bool get isLoading => true;

  @override
  final bool hasValue;

  @override
  final T? value;

  @override
  final Object? error;

  @override
  final StackTrace? stackTrace;

  @override
  R map<R>({
    required R Function(AsyncData<T> data) data,
    required R Function(AsyncError<T> error) error,
    required R Function(AsyncLoading<T> loading) loading,
  }) {
    return loading(this);
  }

  @override
  AsyncValue<T> copyWithPrevious(
    AsyncValue<T> previous, {
    bool isRefresh = true,
  }) {
    if (isRefresh) {
      return previous.map(
        data: (d) => AsyncData._(
          d.value,
          isLoading: true,
          error: d.error,
          stackTrace: d.stackTrace,
        ),
        error: (e) => AsyncError._(
          e.error,
          isLoading: true,
          value: e.valueOrNull,
          stackTrace: e.stackTrace,
          hasValue: e.hasValue,
        ),
        loading: (_) => this,
      );
    } else {
      return previous.map(
        data: (d) => AsyncLoading._(
          hasValue: true,
          value: d.valueOrNull,
          error: d.error,
          stackTrace: d.stackTrace,
        ),
        error: (e) => AsyncLoading._(
          hasValue: e.hasValue,
          value: e.valueOrNull,
          error: e.error,
          stackTrace: e.stackTrace,
        ),
        loading: (e) => e,
      );
    }
  }

  @override
  AsyncValue<V> transform<V>(V Function(T value) cb) {
    if (value case final val?) {
      return AsyncLoading<V>().copyWithPrevious(AsyncData(cb(val)));
    }

    return AsyncLoading<V>();
  }
}

/// Creates an [AsyncValue] in the error state.
///
/// _I don't have a [StackTrace], what can I do?_
/// You can still construct an [AsyncError] by passing [StackTrace.current]:
///
/// ```dart
/// AsyncValue.error(error, StackTrace.current);
/// ```
class AsyncError<T> extends AsyncValue<T> {
  /// Creates an [AsyncValue] in the error state.
  ///
  /// _I don't have a [StackTrace], what can I do?_
  /// You can still construct an [AsyncError] by passing [StackTrace.current]:
  ///
  /// ```dart
  /// AsyncValue.error(error, StackTrace.current);
  /// ```
  const AsyncError(Object error, StackTrace stackTrace)
      : this._(
          error,
          stackTrace: stackTrace,
          isLoading: false,
          hasValue: false,
          value: null,
        );

  const AsyncError._(
    this.error, {
    required this.stackTrace,
    required T? value,
    required this.hasValue,
    required this.isLoading,
  })  : _value = value,
        super._();

  @override
  String get _displayString => 'AsyncError';

  @override
  final bool isLoading;

  @override
  final bool hasValue;

  final T? _value;

  @override
  T? get value {
    if (!hasValue) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    return _value;
  }

  @override
  final Object error;

  @override
  final StackTrace stackTrace;

  @override
  R map<R>({
    required R Function(AsyncData<T> data) data,
    required R Function(AsyncError<T> error) error,
    required R Function(AsyncLoading<T> loading) loading,
  }) {
    return error(this);
  }

  @override
  AsyncError<T> copyWithPrevious(
    AsyncValue<T> previous, {
    bool isRefresh = true,
  }) {
    return AsyncError._(
      error,
      stackTrace: stackTrace,
      isLoading: isLoading,
      value: previous.valueOrNull,
      hasValue: previous.hasValue,
    );
  }

  @override
  AsyncValue<V> transform<V>(V Function(T value) cb) =>
      AsyncError(error, stackTrace);
}

/// An extension that adds methods like [when] to an [AsyncValue].
extension AsyncValueX<T> on AsyncValue<T> {
  /// If [hasValue] is true, returns the value.
  /// Otherwise if [hasError], rethrows the error.
  /// Finally if in loading state, throws a [StateError].
  ///
  /// This is typically used for when the UI assumes that [value] is always
  /// present.
  T get requireValue {
    if (hasValue) return value as T;
    if (hasError) {
      Error.throwWithStackTrace(error!, stackTrace!);
    }

    throw StateError(
      'Tried to call `requireValue` on an `AsyncValue` that has no value: '
      '$this',
    );
  }

  /// Return the value or previous value if in loading/error state.
  ///
  /// If there is no previous value, null will be returned during loading/error state.
  ///
  /// This is different from [value], which will rethrow the error instead of
  /// returning null.
  ///
  /// If you do not want to return previous value during loading/error states,
  /// consider using [unwrapPrevious] :
  ///
  /// ```dart
  /// ref.watch(pod).unwrapPrevious()?.valueOrNull;
  /// ```
  T? get valueOrNull {
    if (hasValue) return value;
    return null;
  }

  /// Whether the associated pod was forced to recompute even though
  /// none of its dependencies has changed, after at least one [value]/[error] was emitted.
  ///
  /// This is usually the case when rebuilding a pod with either
  /// refresh.
  ///
  /// If a pod rebuilds because one of its dependencies changes,
  /// then [isRefreshing] will be false, and instead [isReloading] will be true.
  bool get isRefreshing =>
      isLoading && (hasValue || hasError) && this is! AsyncLoading;

  /// Whether the associated pod was recomputed because of a dependency change
  /// (using watch), after at least one [value]/[error] was emitted.
  ///
  /// If a pod rebuilds because one of its dependencies changed (using watch),
  /// then [isReloading] will be true.
  /// If a pod rebuilds only due to refresh, then
  /// [isReloading] will be false (and [isRefreshing] will be true).
  ///
  /// See also [isRefreshing] for manual pod rebuild.
  bool get isReloading => (hasValue || hasError) && this is AsyncLoading;

  /// Whether [error] is not null.
  ///
  /// Even if [hasError] is true, it is still possible for [hasValue]/[isLoading]
  /// to also be true.
  // It is safe to check it through `error != null` because `error` is
  // non-nullable on the AsyncError constructor.
  bool get hasError => error != null;

  /// Upcast [AsyncValue] into an [AsyncData], or return null if the
  /// [AsyncValue] is an [AsyncLoading]/[AsyncError].
  ///
  /// Note that an [AsyncData] may still be in loading/error state, such
  /// as during a pull-to-refresh.
  AsyncData<T>? get asData {
    return map(
      data: (d) => d,
      error: (e) => null,
      loading: (l) => null,
    );
  }

  /// Upcast [AsyncValue] into an [AsyncError], or return null if the
  /// [AsyncValue] is an [AsyncLoading]/[AsyncData].
  ///
  /// Note that an [AsyncError] may still be in loading state, such
  /// as during a pull-to-refresh.
  AsyncError<T>? get asError => map(
        data: (_) => null,
        error: (e) => e,
        loading: (_) => null,
      );

  /// Shorthand for [when] to handle only the `data` case.
  ///
  /// For loading/error cases, creates a new [AsyncValue] with the corresponding
  /// generic type while preserving the error/stacktrace.
  AsyncValue<R> whenData<R>(R Function(T value) cb) {
    return map(
      data: (d) {
        try {
          return AsyncData._(
            cb(d.value),
            isLoading: d.isLoading,
            error: d.error,
            stackTrace: d.stackTrace,
          );
        } catch (err, stack) {
          return AsyncError._(
            err,
            stackTrace: stack,
            isLoading: d.isLoading,
            value: null,
            hasValue: false,
          );
        }
      },
      error: (e) => AsyncError._(
        e.error,
        stackTrace: e.stackTrace,
        isLoading: e.isLoading,
        value: null,
        hasValue: false,
      ),
      loading: (l) => AsyncLoading<R>(),
    );
  }

  /// Switch-case over the state of the [AsyncValue] while purposefully not
  /// handling some cases.
  ///
  /// If [AsyncValue] was in a case that is not handled, will return [orElse].
  ///
  R maybeWhen<R>({
    required R Function() orElse,
    bool skipLoadingOnReload = false,
    bool skipLoadingOnRefresh = true,
    bool skipError = false,
    R Function(T data)? data,
    R Function(Object error, StackTrace stackTrace)? error,
    R Function()? loading,
  }) {
    return when(
      skipError: skipError,
      skipLoadingOnRefresh: skipLoadingOnRefresh,
      skipLoadingOnReload: skipLoadingOnReload,
      data: data ?? (_) => orElse(),
      error: error ?? (err, stack) => orElse(),
      loading: loading ?? () => orElse(),
    );
  }

  /// Performs an action based on the state of the [AsyncValue].
  ///
  /// All cases are required, which allows returning a non-nullable value.
  ///
  /// By default, [when] skips "loading" states if triggered by a refresh
  /// (but does not skip loading states if triggered by watch).
  ///
  /// In the event that an [AsyncValue] is in multiple states at once (such as
  /// when reloading a pod or emitting an error after a valid data),
  /// [when] offers various flags to customize whether it should call
  /// [loading]/[error]/[data] :
  ///
  /// - [skipLoadingOnReload] (false by default) customizes whether [loading]
  ///   should be invoked if a pod rebuilds because of watch.
  ///   In that situation, [when] will try to invoke either [error]/[data]
  ///   with the previous state.
  ///
  /// - [skipLoadingOnRefresh] (true by default) controls whether [loading]
  ///   should be invoked if a pod rebuilds because of refresh.
  ///   In that situation, [when] will try to invoke either [error]/[data]
  ///   with the previous state.
  ///
  /// - [skipError] (false by default) decides whether to invoke [data] instead
  ///   of [error] if a previous [value] is available.
  R when<R>({
    required R Function(T data) data,
    required R Function(Object error, StackTrace stackTrace) error,
    required R Function() loading,
    bool skipLoadingOnReload = false,
    bool skipLoadingOnRefresh = true,
    bool skipError = false,
  }) {
    if (isLoading) {
      bool skip;
      if (isRefreshing) {
        skip = skipLoadingOnRefresh;
      } else if (isReloading) {
        skip = skipLoadingOnReload;
      } else {
        skip = false;
      }
      if (!skip) return loading();
    }

    if (hasError && (!hasValue || !skipError)) {
      return error(this.error!, stackTrace!);
    }

    return data(requireValue);
  }

  /// Perform actions conditionally based on the state of the [AsyncValue].
  ///
  /// Returns null if [AsyncValue] was in a state that was not handled.
  /// This is similar to [maybeWhen] where `orElse` returns null.
  R? whenOrNull<R>({
    bool skipLoadingOnReload = false,
    bool skipLoadingOnRefresh = true,
    bool skipError = false,
    R? Function(T data)? data,
    R? Function(Object error, StackTrace stackTrace)? error,
    R? Function()? loading,
  }) {
    return when(
      skipError: skipError,
      skipLoadingOnRefresh: skipLoadingOnRefresh,
      skipLoadingOnReload: skipLoadingOnReload,
      data: data ?? (_) => null,
      error: error ?? (err, stack) => null,
      loading: loading ?? () => null,
    );
  }

  /// Perform some actions based on the state of the [AsyncValue], or call
  /// orElse if the current state was not tested.
  R maybeMap<R>({
    required R Function() orElse,
    R Function(AsyncData<T> data)? data,
    R Function(AsyncError<T> error)? error,
    R Function(AsyncLoading<T> loading)? loading,
  }) {
    return map(
      data: (d) {
        if (data != null) return data(d);
        return orElse();
      },
      error: (d) {
        if (error != null) return error(d);
        return orElse();
      },
      loading: (d) {
        if (loading != null) return loading(d);
        return orElse();
      },
    );
  }

  /// Perform some actions based on the state of the [AsyncValue], or return
  /// null if the current state wasn't tested.
  R? mapOrNull<R>({
    R? Function(AsyncData<T> data)? data,
    R? Function(AsyncError<T> error)? error,
    R? Function(AsyncLoading<T> loading)? loading,
  }) {
    return map(
      data: (d) => data?.call(d),
      error: (d) => error?.call(d),
      loading: (d) => loading?.call(d),
    );
  }
}
