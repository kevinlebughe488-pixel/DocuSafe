import 'package:drift/drift.dart';

import '../../errors/app_exception.dart';
import '../../utils/secure_random.dart';
import '../../utils/text_normalizer.dart';
import '../app_database.dart';
import '../default_categories.dart';
import '../tables.dart';

part 'categories_dao.g.dart';

/// Catégorie avec son nombre de documents.
final class CategoryWithCount {
  const CategoryWithCount(this.category, this.documentCount);

  final CategoryRow category;
  final int documentCount;
}

@DriftAccessor(tables: [Categories, Documents])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Toutes les catégories, dans l'ordre d'affichage.
  Stream<List<CategoryRow>> watchAll() => (select(
    categories,
  )..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)])).watch();

  Future<List<CategoryRow>> getAll() => (select(
    categories,
  )..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)])).get();

  Future<CategoryRow?> getById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Catégories avec le nombre de documents de chacune (tableau de bord).
  Stream<List<CategoryWithCount>> watchWithCounts() {
    final count = documents.id.count();
    final query = select(categories).join([
      leftOuterJoin(documents, documents.categoryId.equalsExp(categories.id)),
    ])
      ..addColumns([count])
      ..groupBy([categories.id])
      ..orderBy([OrderingTerm.asc(categories.sortOrder)]);
    return query.watch().map(
      (rows) => rows
          .map((r) => CategoryWithCount(r.readTable(categories), r.read(count) ?? 0))
          .toList(),
    );
  }

  /// Crée une catégorie. Lève [ValidationException] si le nom existe déjà.
  Future<CategoryRow> create({
    required String name,
    required String icon,
    required int color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      throw const ValidationException('validation.category_name');
    }
    final key = TextNormalizer.nameKey(trimmed);
    final existing = await (select(
      categories,
    )..where((c) => c.nameKey.equals(key))).getSingleOrNull();
    if (existing != null) {
      throw const ValidationException('validation.category_duplicate');
    }
    final maxOrder =
        await (selectOnly(categories)..addColumns([categories.sortOrder.max()]))
            .map((r) => r.read(categories.sortOrder.max()))
            .getSingle() ??
        0;
    final companion = CategoriesCompanion.insert(
      id: SecureRandom.uuid(),
      name: trimmed,
      nameKey: key,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
      sortOrder: Value(maxOrder + 1),
    );
    await into(categories).insert(companion);
    return (await getById(companion.id.value))!;
  }

  /// Renomme ou recolore une catégorie.
  Future<void> edit(
    String id, {
    String? name,
    String? icon,
    int? color,
  }) async {
    final companion = CategoriesCompanion(
      name: name == null ? const Value.absent() : Value(name.trim()),
      nameKey: name == null
          ? const Value.absent()
          : Value(TextNormalizer.nameKey(name)),
      icon: icon == null ? const Value.absent() : Value(icon),
      color: color == null ? const Value.absent() : Value(color),
    );
    await (update(categories)..where((c) => c.id.equals(id))).write(companion);
  }

  /// Nouvel ordre après un glisser-déposer : [orderedIds] est l'ordre actuel,
  /// l'élément [from] est déplacé en position [to] (indice déjà ajusté,
  /// convention de `onReorderItem`).
  Future<void> reorder(List<String> orderedIds, int from, int to) async {
    final ids = List<String>.from(orderedIds);
    final moved = ids.removeAt(from);
    ids.insert(to, moved);
    await transaction(() async {
      for (var i = 0; i < ids.length; i++) {
        await (update(categories)..where((c) => c.id.equals(ids[i]))).write(
          CategoriesCompanion(sortOrder: Value(i)),
        );
      }
    });
  }

  /// Supprime une catégorie après avoir déplacé ses documents vers
  /// [targetCategoryId] (par défaut « Autres »), dans une seule transaction.
  /// La catégorie système ne peut pas être supprimée.
  Future<void> deleteMovingDocuments(
    String id, {
    String targetCategoryId = DefaultCategory.othersId,
  }) async {
    final row = await getById(id);
    if (row == null) {
      return;
    }
    if (row.isSystem || id == targetCategoryId) {
      throw const ValidationException('validation.category_system');
    }
    await transaction(() async {
      await (update(documents)..where((d) => d.categoryId.equals(id))).write(
        DocumentsCompanion(categoryId: Value(targetCategoryId)),
      );
      await (delete(categories)..where((c) => c.id.equals(id))).go();
    });
  }
}
