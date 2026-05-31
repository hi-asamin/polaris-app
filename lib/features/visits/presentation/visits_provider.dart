import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/database_provider.dart';
import 'package:polaris/core/db/system_entities.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/visits/data/visits_repository.dart';
import 'package:polaris/features/visits/models/visit.dart';

final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  return VisitsRepository(ref.watch(databaseProvider));
});

class VisitsNotifier extends AsyncNotifier<List<Visit>> {
  @override
  Future<List<Visit>> build() async {
    final repo = ref.watch(visitsRepositoryProvider);
    return repo.list();
  }

  Future<void> create(Visit v) async {
    final repo = ref.read(visitsRepositoryProvider);
    await repo.insert(v);
    // 訪問記録ができたら「行きたい」フォルダから自動で外す。
    // (= もう行ったので「行きたい」状態は終わり)
    await ref
        .read(spotFolderPairsNotifierProvider.notifier)
        .remove(v.spotId, SystemIds.wantFolderId);
    state = AsyncData(await repo.list());
  }

  Future<void> updateVisit(Visit v) async {
    final repo = ref.read(visitsRepositoryProvider);
    await repo.update(v);
    state = AsyncData(await repo.list());
  }

  Future<void> deleteVisit(String id) async {
    final repo = ref.read(visitsRepositoryProvider);
    await repo.softDelete(id);
    state = AsyncData(await repo.list());
  }
}

final visitsNotifierProvider =
    AsyncNotifierProvider<VisitsNotifier, List<Visit>>(VisitsNotifier.new);

final allVisitsProvider = Provider<List<Visit>>((ref) {
  return ref.watch(visitsNotifierProvider).value ?? const [];
});

final visitsBySpotProvider = Provider.family<List<Visit>, String>((
  ref,
  spotId,
) {
  return ref.watch(allVisitsProvider).where((v) => v.spotId == spotId).toList()
    ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
});

final visitCountBySpotProvider = Provider.family<int, String>((ref, spotId) {
  return ref.watch(visitsBySpotProvider(spotId)).length;
});

final lastVisitedAtProvider = Provider.family<DateTime?, String>((ref, spotId) {
  final visits = ref.watch(visitsBySpotProvider(spotId));
  if (visits.isEmpty) return null;
  return visits.first.visitedAt;
});

class VisitGroup {
  const VisitGroup({required this.label, required this.visits});
  final String label;
  final List<Visit> visits;
}

final visitGroupsProvider = Provider<List<VisitGroup>>((ref) {
  final visits = ref.watch(allVisitsProvider);
  if (visits.isEmpty) return const [];

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);
  final last30 = now.subtract(const Duration(days: 30));

  final thisMonth = <Visit>[];
  final recent = <Visit>[];
  final earlier = <Visit>[];

  for (final v in visits) {
    if (v.visitedAt.isAfter(monthStart) ||
        v.visitedAt.isAtSameMomentAs(monthStart)) {
      thisMonth.add(v);
    } else if (v.visitedAt.isAfter(last30)) {
      recent.add(v);
    } else {
      earlier.add(v);
    }
  }

  return [
    if (thisMonth.isNotEmpty) VisitGroup(label: 'thisMonth', visits: thisMonth),
    if (recent.isNotEmpty) VisitGroup(label: 'recent', visits: recent),
    if (earlier.isNotEmpty) VisitGroup(label: 'earlier', visits: earlier),
  ];
});
