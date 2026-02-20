import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseProvider extends ChangeNotifier {
  static const _entitlementId = 'remove_ads';

  // iOS API key (App Store Connect)
  static const _iosApiKey = 'test_SBdoFimIyjwdiAMuQbfSCKcAaDA';
  // TODO: Android API key를 RevenueCat 대시보드 → Android 앱에서 복사해 교체
  static const _androidApiKey = 'test_SBdoFimIyjwdiAMuQbfSCKcAaDA';

  bool _isAdRemoved = false;
  bool _isLoading = true;

  bool get isAdRemoved => _isAdRemoved;
  bool get isLoading => _isLoading;

  PurchaseProvider() {
    _init();
  }

  // ─── RevenueCat 초기화 ──────────────────────────────────────────────────────

  static Future<void> configure() async {
    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
  }

  // ─── 현재 구매 상태 확인 ────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _isAdRemoved = customerInfo.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      debugPrint('[PurchaseProvider] init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 구매 후 / 복원 후 상태 갱신
  Future<void> refresh() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _isAdRemoved = customerInfo.entitlements.active.containsKey(_entitlementId);
      notifyListeners();
    } catch (e) {
      debugPrint('[PurchaseProvider] refresh error: $e');
    }
  }
}
