import 'text_normalizer.dart';

/// Positions des mots de [query] dans [text], sans tenir compte des
/// majuscules ni des accents (« diplome » trouve « Diplôme »). Les mots
/// sont cherchés en début de mot, comme le fait l'index de recherche.
List<(int, int)> highlightRanges(String text, String query) {
  final folded = TextNormalizer.foldSameLength(text);
  final words = TextNormalizer.foldSameLength(query)
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(RegExp(r'["*^()\-:{}]'), ''))
      .where((w) => w.isNotEmpty)
      .toSet();
  final ranges = <(int, int)>[];
  for (final word in words) {
    var start = 0;
    while (true) {
      final i = folded.indexOf(word, start);
      if (i < 0) {
        break;
      }
      final atWordStart = i == 0 || !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(folded[i - 1]);
      if (atWordStart) {
        ranges.add((i, i + word.length));
      }
      start = i + 1;
    }
  }
  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(int, int)>[];
  for (final r in ranges) {
    if (merged.isNotEmpty && r.$1 <= merged.last.$2) {
      final last = merged.removeLast();
      merged.add((last.$1, r.$2 > last.$2 ? r.$2 : last.$2));
    } else {
      merged.add(r);
    }
  }
  return merged;
}
