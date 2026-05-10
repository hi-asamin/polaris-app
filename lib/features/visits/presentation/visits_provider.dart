import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/mock/mock_data.dart';
import 'package:polaris/features/visits/models/visit.dart';

class VisitsNotifier extends Notifier<List<Visit>> {
  @override
  List<Visit> build() {
    final list = [...MockData.visits]
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    return list;
  }
}

final visitsNotifierProvider = NotifierProvider<VisitsNotifier, List<Visit>>(
  VisitsNotifier.new,
);

final allVisitsProvider = Provider<List<Visit>>((ref) {
  return ref.watch(visitsNotifierProvider);
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
