import 'dart:async';

/// Combine deux flux : émet à chaque nouvelle valeur de l'un ou de l'autre,
/// dès que les deux ont émis une première fois. Évite une dépendance à
/// `rxdart` pour un seul usage.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combine,
) {
  late StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  var hasA = false;
  var hasB = false;
  late A lastA;
  late B lastB;
  var doneCount = 0;

  void emit() {
    if (hasA && hasB) {
      controller.add(combine(lastA, lastB));
    }
  }

  void onDone() {
    doneCount++;
    if (doneCount == 2) {
      unawaited(controller.close());
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subA = a.listen(
        (v) {
          lastA = v;
          hasA = true;
          emit();
        },
        onError: controller.addError,
        onDone: onDone,
      );
      subB = b.listen(
        (v) {
          lastB = v;
          hasB = true;
          emit();
        },
        onError: controller.addError,
        onDone: onDone,
      );
    },
    onPause: () {
      subA?.pause();
      subB?.pause();
    },
    onResume: () {
      subA?.resume();
      subB?.resume();
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );
  return controller.stream;
}
