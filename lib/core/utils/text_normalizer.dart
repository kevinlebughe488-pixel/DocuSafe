/// Normalisation des textes pour les comparaisons et la recherche.
abstract final class TextNormalizer {
  static const _accents = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæß';
  static const _plain = 'aaaaaaceeeeiiiinooooouuuuyyoas';

  /// Clé de comparaison : minuscules, sans accents, espaces réduits.
  ///
  /// « Santé » et « sante » donnent la même clé (docs/03-modele-de-donnees.md).
  static String nameKey(String input) {
    final lower = input.trim().toLowerCase();
    final sb = StringBuffer();
    var lastWasSpace = false;
    for (final rune in lower.runes) {
      var ch = String.fromCharCode(rune);
      final idx = _accents.indexOf(ch);
      if (idx >= 0) {
        ch = _plain[idx];
        if (ch == 'o' && _accents[idx] == 'œ') {
          ch = 'oe';
        } else if (ch == 'a' && _accents[idx] == 'æ') {
          ch = 'ae';
        } else if (ch == 's' && _accents[idx] == 'ß') {
          ch = 'ss';
        }
      }
      final isSpace = ch.trim().isEmpty;
      if (isSpace) {
        if (!lastWasSpace && sb.isNotEmpty) {
          sb.write(' ');
        }
        lastWasSpace = true;
      } else {
        sb.write(ch);
        lastWasSpace = false;
      }
    }
    return sb.toString().trim();
  }
}
