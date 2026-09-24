import 'package:flutter/widgets.dart';
import 'package:startapp_sdk/startapp.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const String appId = '207412796';

  final StartAppSdk _sdk = StartAppSdk();

  StartAppBannerAd? _bannerAd;
  StartAppInterstitialAd? _interstitialAd;

  final ValueNotifier<bool> bannerReady = ValueNotifier(false);

  final ValueNotifier<String> status = ValueNotifier('ads: non initialisé');

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    status.value = 'ads: initialisé, chargement bannière…';
    debugPrint('[AdsService] Start.io initialisé (appId=$appId) PROD');

    _loadBanner();
  }

  void _loadBanner() {
    if (_bannerAd != null) return;

    _sdk.loadBannerAd(
      StartAppBannerType.BANNER,
      prefs: const StartAppAdPreferences(adTag: 'sportflix-home-banner'),
      onAdImpression: () {
        status.value = 'ads: bannière impression';
        debugPrint('[AdsService] Start.io banner impression');
      },
      onAdClicked: () {
        status.value = 'ads: bannière cliquée';
        debugPrint('[AdsService] Start.io banner clicked');
      },
    ).then((bannerAd) {
      _bannerAd = bannerAd;
      bannerReady.value = true;
      status.value = 'ads: bannière chargée';
      debugPrint('[AdsService] Start.io banner loaded');
    }).onError((error, stackTrace) {
      status.value = 'ads: bannière échouée ($error)';
      debugPrint('[AdsService] Start.io banner failed: $error');
      _bannerAd = null;
      bannerReady.value = false;
    });
  }

  Widget get bannerWidget {
    if (_bannerAd == null) return const SizedBox.shrink();
    return StartAppBanner(_bannerAd!);
  }

  Future<bool> showInterstitial() async {
    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('[AdsService] interstitial not ready, loading…');
      _loadInterstitial();
      return false;
    }
    try {
      final shown = await ad.show();
      if (shown) {
        debugPrint('[AdsService] interstitial shown (onAdHidden reload)');
        // Ne pas reload ici : onAdHidden s'en charge.
      }
      return shown;
    } catch (e) {
      debugPrint('[AdsService] interstitial show error: $e');
      ad.dispose();
      _interstitialAd = null;
      _loadInterstitial();
      return false;
    }
  }

  void _loadInterstitial() {
    _sdk.loadInterstitialAd(
      prefs: const StartAppAdPreferences(adTag: 'sportflix-exit-interstitial'),
      onAdDisplayed: () {
        status.value = 'ads: interstitial affichée';
        debugPrint('[AdsService] Start.io interstitial displayed');
      },
      onAdNotDisplayed: () {
        status.value = 'ads: interstitial non affichée';
        debugPrint('[AdsService] Start.io interstitial not displayed');
        _interstitialAd?.dispose();
        _interstitialAd = null;
        _retryInterstitial();
      },
      onAdClicked: () {
        status.value = 'ads: interstitial cliquée';
        debugPrint('[AdsService] Start.io interstitial clicked');
      },
      onAdHidden: () {
        status.value = 'ads: interstitial fermée, reload…';
        debugPrint('[AdsService] Start.io interstitial hidden, reloading');
        _interstitialAd?.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
    ).then((interstitialAd) {
      _interstitialAd = interstitialAd;
      status.value = 'ads: interstitial prête';
      debugPrint('[AdsService] Start.io interstitial loaded');
    }).onError((error, stackTrace) {
      status.value = 'ads: interstitial échouée ($error)';
      debugPrint('[AdsService] Start.io interstitial failed: $error');
      _interstitialAd = null;
      _retryInterstitial();
    });
  }

  int _retryCount = 0;
  static const int _maxRetries = 3;

  void _retryInterstitial() {
    if (_retryCount >= _maxRetries) {
      debugPrint('[AdsService] interstitial retries exhausted');
      return;
    }
    _retryCount++;
    final delay = Duration(seconds: 2 * _retryCount);
    debugPrint('[AdsService] retry interstitial attempt $_retryCount in $delay');
    Future.delayed(delay, _loadInterstitial);
  }
}
