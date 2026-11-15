import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/documents/document_search.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';

final class SearchState {
  const SearchState({
    this.text = '',
    this.filters = const SearchFilters(),
    this.results = const [],
    this.loading = false,
    this.error,
  });

  final String text;
  final SearchFilters filters;
  final List<DocumentRow> results;
  final bool loading;
  final Object? error;

  /// Ni texte ni filtre : on affiche l'invitation à chercher.
  bool get isIdle => text.trim().isEmpty && filters.isEmpty;

  SearchState copyWith({
    String? text,
    SearchFilters? filters,
    List<DocumentRow>? results,
    bool? loading,
    Object? error,
    bool clearError = true,
  }) => SearchState(
    text: text ?? this.text,
    filters: filters ?? this.filters,
    results: results ?? this.results,
    loading: loading ?? this.loading,
    error: clearError ? error : (error ?? this.error),
  );
}

/// ViewModel de la recherche : résultats pendant la saisie (petite
/// temporisation pour ne pas interroger la base à chaque touche).
final class SearchViewModel extends Notifier<SearchState> {
  Timer? _debounce;
  int _generation = 0;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void setText(String text) {
    state = state.copyWith(text: text);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () => unawaited(_run()));
  }

  void setFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters);
    unawaited(_run());
  }

  void clearFilters() => setFilters(const SearchFilters());

  /// Relance la recherche (après une modification d'un document).
  Future<void> refresh() => _run();

  Future<void> _run() async {
    final generation = ++_generation;
    if (state.isIdle) {
      state = state.copyWith(results: const [], loading: false);
      return;
    }
    state = state.copyWith(loading: true);
    try {
      final results = await ref
          .read(documentSearchProvider)
          .search(state.text, state.filters);
      // Une saisie plus récente a pu relancer la recherche entre-temps.
      if (generation == _generation) {
        state = state.copyWith(results: results, loading: false);
      }
    } on AppException catch (e) {
      if (generation == _generation) {
        state = state.copyWith(loading: false, error: e);
      }
    }
  }
}

final searchViewModelProvider =
    NotifierProvider.autoDispose<SearchViewModel, SearchState>(SearchViewModel.new);

/// Tags existants, pour le filtre.
final searchTagsProvider = FutureProvider.autoDispose<List<TagRow>>(
  (ref) => ref.watch(documentSearchProvider).allTags(),
);
