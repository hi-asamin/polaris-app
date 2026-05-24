import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/sharing/widgets/share_card_preview.dart';
import 'package:polaris/features/sharing/widgets/spot_share_card.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

/// 単一スポット用シェアカード画面。
class SpotShareScreen extends ConsumerWidget {
  const SpotShareScreen({required this.spotId, super.key});
  final String spotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spot = ref.watch(spotByIdProvider(spotId));
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    if (spot == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Spot not found')),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('シェア'),
        backgroundColor: scheme.surfaceContainerLowest,
      ),
      body: ShareCardPreview(
        card: SpotShareCard(
          spot: spot,
          categoryLabel: spot.primaryCategory.label(l),
          categoryColor: spot.primaryCategory.color,
          categoryIcon: spot.primaryCategory.icon,
        ),
        shareText: '${spot.name} - polaris で見つけた場所',
        shareSubject: spot.name,
      ),
    );
  }
}
