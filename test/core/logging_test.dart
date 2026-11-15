import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Vérification des journaux (cahier des charges §10 et §14) : aucune donnée
/// de document ne peut atteindre un journal.
///
/// Le contrôle porte sur le code source : tout passe par `AppLog`, qui ne
/// reçoit qu'un code fixe (et, pour une erreur, n'écrit que son type).
void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('/generated/'))
      .toList();

  test('aucun print ni debugPrint hors du journal technique', () {
    final forbidden = RegExp(r'\b(print|debugPrint|debugPrintStack)\(|developer\.log\(|\blog\(');
    final offenders = <String>[];
    for (final file in sources) {
      if (file.path.endsWith('core/utils/app_log.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) {
          continue;
        }
        if (forbidden.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Utiliser AppLog (codes fixes, sans donnée).');
  });

  test('AppLog ne reçoit que des codes fixes', () {
    final call = RegExp(r'AppLog\.(event|error)\(\s*');
    final literal = RegExp(r"AppLog\.(event|error)\(\s*'([^']*)'");
    // Seule variation admise : le nom d'une valeur d'énumération.
    final enumName = RegExp(r'\$\{[A-Za-z_.]+\.name\}');
    final offenders = <String>[];
    var calls = 0;
    for (final file in sources) {
      if (file.path.endsWith('core/utils/app_log.dart')) {
        continue;
      }
      final text = file.readAsStringSync();
      calls += call.allMatches(text).length;
      final literals = literal.allMatches(text).toList();
      if (literals.length != call.allMatches(text).length) {
        offenders.add('${file.path} : code non littéral');
      }
      for (final m in literals) {
        final code = m.group(2)!.replaceAll(enumName, '');
        if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(code)) {
          offenders.add('${file.path} : « ${m.group(2)} »');
        }
      }
    }
    expect(calls, greaterThan(20));
    expect(offenders, isEmpty);
  });

  test('une erreur est journalisée par son type, jamais par son message', () {
    final source = File('lib/core/utils/app_log.dart').readAsStringSync();
    expect(source, contains(r'${error.runtimeType}'));
    expect(source, isNot(contains(r'$error')));
    expect(source, isNot(contains('error.toString()')));
    expect(source, isNot(contains('.message')));
  });
}
