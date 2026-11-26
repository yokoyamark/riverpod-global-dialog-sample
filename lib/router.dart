import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/detail_page.dart';
import 'pages/detail_page2.dart';
import 'pages/home_page.dart';

/// DialogPresenter がダイアログを出すのに使う。
///
/// DialogPresenter は Router の外（MaterialApp.router の builder）にいるので、
/// 自分の context からは Navigator を辿れない。
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'detail',
          builder: (context, state) => const DetailPage(),
        ),
        GoRoute(
          path: 'detail2',
          builder: (context, state) => const DetailPage2(),
        ),
      ],
    ),
  ],
);
