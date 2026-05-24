import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/app/theme.dart';
import 'package:polaris/features/account/presentation/user_profile_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class PolarisApp extends ConsumerWidget {
  const PolarisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ルーター起動前にプロフィールの読み込みを待つ。これがないと、初回起動時に
    // initialLocation の /map が一瞬構築されてしまい、MapScreen から
    // CoreLocation の許可ダイアログが出てしまう (オンボーディング前なのに)。
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      data: (_) => const _RouterApp(),
      loading: _SplashApp.new,
      error: (e, _) => _SplashApp(errorMessage: e.toString()),
    );
  }
}

class _RouterApp extends ConsumerWidget {
  const _RouterApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'polaris',
      theme: PolarisTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class _SplashApp extends StatelessWidget {
  const _SplashApp({this.errorMessage});
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'polaris',
      theme: PolarisTheme.light(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: errorMessage == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }
}
