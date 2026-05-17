import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/account/presentation/account_screen.dart';
import 'package:polaris/features/folders/presentation/folder_detail_screen.dart';
import 'package:polaris/features/folders/presentation/folders_screen.dart';
import 'package:polaris/features/home/presentation/home_shell.dart';
import 'package:polaris/features/lists/presentation/list_detail_screen.dart';
import 'package:polaris/features/map/presentation/map_screen.dart';
import 'package:polaris/features/settings/presentation/settings_screen.dart';
import 'package:polaris/features/spots/presentation/search_screen.dart';
import 'package:polaris/features/spots/presentation/spot_detail_screen.dart';
import 'package:polaris/features/visits/presentation/visits_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _mapNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'map');
final _listsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'lists');
final _visitsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'visits');
final _accountNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'account');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/map',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _mapNavigatorKey,
            routes: [
              GoRoute(
                path: '/map',
                name: 'map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _listsNavigatorKey,
            routes: [
              GoRoute(
                path: '/folders',
                name: 'folders',
                builder: (context, state) => const FoldersScreen(),
                routes: [
                  GoRoute(
                    path: ':folderId',
                    name: 'folderDetail',
                    builder: (context, state) => FolderDetailScreen(
                      folderId: state.pathParameters['folderId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _visitsNavigatorKey,
            routes: [
              GoRoute(
                path: '/visits',
                name: 'visits',
                builder: (context, state) => const VisitsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _accountNavigatorKey,
            routes: [
              GoRoute(
                path: '/account',
                name: 'account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      // Root-level routes (push above the shell)
      GoRoute(
        path: '/lists/:listId',
        name: 'listDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ListDetailScreen(
          listId: state.pathParameters['listId']!,
        ),
      ),
      GoRoute(
        path: '/spots/:spotId',
        name: 'spotDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SpotDetailScreen(
          spotId: state.pathParameters['spotId']!,
        ),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
