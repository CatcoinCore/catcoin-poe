import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'games/runner/systems/asset_pack_service.dart';
import 'services/game_sfx_service.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/mining_provider.dart';
import 'providers/mission_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wallet_provider.dart';
import 'services/link_service.dart';

/// Shared provider list for [main] and widget tests.
List<SingleChildWidget> catcoinAppProviders() => [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => MiningProvider()),
      ChangeNotifierProvider(create: (_) => WalletProvider()),
      ChangeNotifierProvider(create: (_) => AdminProvider()),
      ChangeNotifierProvider(create: (_) => MissionProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => GameProvider()),
      ChangeNotifierProvider(create: (_) => RunnerAssetService()),
      ChangeNotifierProvider(create: (_) {
        final mini = MiniGameAssetService();
        GameSfxService.instance.attachMiniGamePack(mini);
        return mini;
      }),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => LinkService()),
    ];
