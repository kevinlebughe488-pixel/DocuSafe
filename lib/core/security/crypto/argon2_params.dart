/// Paramètres du calcul lent du code (Argon2id, docs/04-securite.md §5).
///
/// Ils sont enregistrés avec chaque serrure, pour pouvoir être durcis plus
/// tard sans casser les coffres existants.
final class Argon2Params {
  const Argon2Params({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
  });

  /// Valeurs de départ : 19 Mo, 2 passes. Réglage final sur téléphone réel.
  static const Argon2Params standard = Argon2Params(
    memoryKiB: 19 * 1024,
    iterations: 2,
    parallelism: 1,
  );

  /// Valeurs très légères, réservées aux tests automatiques.
  static const Argon2Params testOnly = Argon2Params(
    memoryKiB: 64,
    iterations: 1,
    parallelism: 1,
  );

  /// Mémoire utilisée, en kibioctets (unité d'Argon2).
  final int memoryKiB;
  final int iterations;
  final int parallelism;

  Map<String, Object> toJson() => {
    'm': memoryKiB,
    't': iterations,
    'p': parallelism,
  };

  factory Argon2Params.fromJson(Map<String, Object?> json) => Argon2Params(
    memoryKiB: json['m']! as int,
    iterations: json['t']! as int,
    parallelism: json['p']! as int,
  );
}
