import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'pending_referral_storage.dart';

/// Referral code from invite URLs: `https://host/invite/CODE`, hash routes
/// `#/invite/CODE`, or `myapp://invite/CODE` (host `invite`, path `/CODE`).
String? parseInviteReferralCode(Uri uri) {
  final path = uri.path;
  if (path.contains('/invite/')) {
    var tail = path.split('/invite/').last;
    tail = tail.split('/').first.split('?').first.split('#').first.trim();
    if (tail.isNotEmpty) return tail;
  }
  final frag = uri.fragment;
  if (frag.contains('invite/')) {
    var tail = frag.split('invite/').last;
    tail = tail.split('/').first.split('?').first.split('#').first.trim();
    if (tail.isNotEmpty) return tail;
  }
  if (uri.host.toLowerCase() == 'invite') {
    var p = uri.path.replaceFirst(RegExp(r'^/'), '');
    final tail = p.split('/').first.split('?').first.trim();
    if (tail.isNotEmpty) return tail;
  }
  return null;
}

class LinkService extends ChangeNotifier {
  static final LinkService _instance = LinkService._internal();
  factory LinkService() => _instance;
  LinkService._internal() {
    _init();
  }

  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  String? _pendingReferralCode;

  String? get pendingReferralCode => _pendingReferralCode;

  void _init() {
    // Web: app_links initial URL is often null; browser location is in Uri.base
    // immediately. Parse synchronously so cold opens to /invite/CODE work.
    if (kIsWeb) {
      final fromBase = parseInviteReferralCode(Uri.base);
      if (fromBase != null && fromBase.isNotEmpty) {
        _pendingReferralCode = fromBase.toUpperCase();
        unawaited(PendingReferralStorage.save(_pendingReferralCode!));
        notifyListeners();
        if (kDebugMode) {
          debugPrint('Captured referral from Uri.base: $_pendingReferralCode');
        }
      }
    }

    // 1. Handle deep link when app is already open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    }, onError: (err) {
      if (kDebugMode) debugPrint('AppLinks Error: $err');
    });

    // 2. Handle deep link when app is opened from scratch (mobile / desktop)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    });
  }

  void _handleUri(Uri uri) {
    if (kDebugMode) debugPrint('Incoming Deep Link: $uri');

    final code = parseInviteReferralCode(uri);
    if (code != null && code.isNotEmpty) {
      _pendingReferralCode = code.toUpperCase();
      unawaited(PendingReferralStorage.save(_pendingReferralCode!));
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Captured Referral Code: $_pendingReferralCode');
      }
    }
  }

  void consumeCode() {
    _pendingReferralCode = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
