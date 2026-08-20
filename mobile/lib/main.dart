import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/sync_service.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: GmaoApp()));
}

class GmaoApp extends ConsumerWidget {
  const GmaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.read(syncServiceProvider).flush();

    return MaterialApp.router(
      title: 'GMAO Léger',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
