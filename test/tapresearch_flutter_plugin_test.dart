import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tapresearch_flutter_plugin/tapresearch_flutter_plugin.dart';
import 'package:tapresearch_flutter_plugin/tapresearch_flutter_plugin_method_channel.dart';
import 'package:tapresearch_flutter_plugin/tapresearch_flutter_plugin_platform_interface.dart';

// ---------------------------------------------------------------------------
// Concrete callback implementations for use in tests
// ---------------------------------------------------------------------------

class _SdkReadyCallback implements TRSdkReadyCallback {
  bool wasCalled = false;
  @override
  void onTapResearchSdkReady() => wasCalled = true;
}

class _ErrorCallback implements TRErrorCallback {
  TRError? received;
  @override
  void onTapResearchDidError(TRError trError) => received = trError;
}

class _ContentCallback implements TRContentCallback {
  String? shownTag;
  String? dismissedTag;
  @override
  void onTapResearchContentShown(String placementTag) => shownTag = placementTag;
  @override
  void onTapResearchContentDismissed(String placementTag) =>
      dismissedTag = placementTag;
}

class _SurveysRefreshedListener implements TRSurveysRefreshedListener {
  String? refreshedTag;
  @override
  void onSurveysRefreshedForPlacement(String placementTag) =>
      refreshedTag = placementTag;
}

class _GrantBoostListener implements TRGrantBoostResponseListener {
  TRGrantBoostResponse? received;
  @override
  void onGrantBoostResponse(TRGrantBoostResponse grantBoostResponse) =>
      received = grantBoostResponse;
}

// ---------------------------------------------------------------------------
// Mock platform
// ---------------------------------------------------------------------------

class MockPlatform
    with MockPlatformInterfaceMixin
    implements TapresearchFlutterPluginPlatform {
  String? lastMethod;
  Map<String, dynamic> lastArgs = {};

  // Controllable return values
  bool isReadyResult = true;
  bool canShowResult = true;
  bool hasSurveysResult = true;
  List<TRSurvey>? surveysResult;
  TRPlacementDetails? placementDetailsResult;

  // Fires sdkReady and optionally an error synchronously so callback tests work
  TRError? errorToFire;

  @override
  Future<void> initialize({
    required String flutterVersion,
    required String apiToken,
    required String userIdentifier,
    TRRewardCallback? rewardCallback,
    required TRErrorCallback errorCallback,
    required TRSdkReadyCallback sdkReadyCallback,
    TRQQDataCallback? qqDataCallback,
    Map<String, dynamic>? userAttributes,
    bool? clearPreviousAttributes,
  }) async {
    lastMethod = 'initialize';
    lastArgs = {
      'apiToken': apiToken,
      'userIdentifier': userIdentifier,
    };
    if (errorToFire != null) {
      errorCallback.onTapResearchDidError(errorToFire!);
    } else {
      sdkReadyCallback.onTapResearchSdkReady();
    }
  }

  @override
  Future<void> setUserIdentifier(String userIdentifier) async {
    lastMethod = 'setUserIdentifier';
    lastArgs = {'userIdentifier': userIdentifier};
  }

  @override
  Future<bool> canShowContentForPlacement(
      String tag, TRErrorCallback errorCallback) async {
    lastMethod = 'canShowContentForPlacement';
    lastArgs = {'tag': tag};
    return canShowResult;
  }

  @override
  Future<void> sendUserAttributes({
    required Map<String, dynamic> userAttributes,
    bool? clearPreviousAttributes,
    required TRErrorCallback errorCallback,
  }) async {
    lastMethod = 'sendUserAttributes';
    lastArgs = {
      'userAttributes': userAttributes,
      'clearPreviousAttributes': clearPreviousAttributes,
    };
  }

  @override
  Future<void> showContentForPlacement({
    required String tag,
    TRContentCallback? contentCallback,
    Map<String, dynamic>? customParameters,
    required TRErrorCallback errorCallback,
  }) async {
    lastMethod = 'showContentForPlacement';
    lastArgs = {'tag': tag, 'customParameters': customParameters};
    contentCallback?.onTapResearchContentShown(tag);
    contentCallback?.onTapResearchContentDismissed(tag);
  }

  @override
  Future<bool> isReady() async => isReadyResult;

  @override
  Future<void> setSurveysRefreshedListener(
      TRSurveysRefreshedListener? listener) async {
    lastMethod = 'setSurveysRefreshedListener';
    lastArgs = {'enabled': listener != null};
    listener?.onSurveysRefreshedForPlacement('test-placement');
  }

  @override
  Future<bool> hasSurveysForPlacement(
      String placementTag, TRErrorCallback errorCallback) async {
    lastMethod = 'hasSurveysForPlacement';
    lastArgs = {'placementTag': placementTag};
    return hasSurveysResult;
  }

  @override
  Future<List<TRSurvey>?> getSurveysForPlacement(
      String placementTag, TRErrorCallback errorCallback) async {
    lastMethod = 'getSurveysForPlacement';
    lastArgs = {'placementTag': placementTag};
    return surveysResult;
  }

  @override
  Future<void> showSurveyForPlacement({
    required String placementTag,
    required String surveyId,
    Map<String, dynamic>? customParameters,
    TRContentCallback? contentCallback,
    required TRErrorCallback errorCallback,
  }) async {
    lastMethod = 'showSurveyForPlacement';
    lastArgs = {'placementTag': placementTag, 'surveyId': surveyId};
    contentCallback?.onTapResearchContentShown(placementTag);
  }

  @override
  Future<void> grantBoost(String boostTag,
      {TRGrantBoostResponseListener? listener}) async {
    lastMethod = 'grantBoost';
    lastArgs = {'boostTag': boostTag};
    listener?.onGrantBoostResponse(TRGrantBoostResponse(
      boostTag: boostTag,
      success: true,
    ));
  }

  @override
  Future<TRPlacementDetails?> getPlacementDetails(String placementTag,
      {TRErrorCallback? errorListener}) async {
    lastMethod = 'getPlacementDetails';
    lastArgs = {'placementTag': placementTag};
    return placementDetailsResult;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = TapresearchFlutterPluginPlatform.instance;

  late MockPlatform mock;
  late TapresearchFlutterPlugin plugin;

  setUp(() {
    mock = MockPlatform();
    TapresearchFlutterPluginPlatform.instance = mock;
    plugin = TapresearchFlutterPlugin();
  });

  test('default instance is MethodChannelTapresearchFlutterPlugin', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTapresearchFlutterPlugin>());
  });

  group('initialize', () {
    test('passes apiToken and userIdentifier to platform', () async {
      final sdkReady = _SdkReadyCallback();
      final error = _ErrorCallback();

      await plugin.initialize(
        apiToken: 'test-token',
        userIdentifier: 'user-1',
        sdkReadyCallback: sdkReady,
        errorCallback: error,
      );

      expect(mock.lastMethod, 'initialize');
      expect(mock.lastArgs['apiToken'], 'test-token');
      expect(mock.lastArgs['userIdentifier'], 'user-1');
    });

    test('fires sdkReadyCallback on success', () async {
      final sdkReady = _SdkReadyCallback();
      final error = _ErrorCallback();

      await plugin.initialize(
        apiToken: 'token',
        userIdentifier: 'user',
        sdkReadyCallback: sdkReady,
        errorCallback: error,
      );

      expect(sdkReady.wasCalled, isTrue);
      expect(error.received, isNull);
    });

    test('fires errorCallback on failure', () async {
      mock.errorToFire = TRError(code: 42, description: 'bad token');
      final sdkReady = _SdkReadyCallback();
      final error = _ErrorCallback();

      await plugin.initialize(
        apiToken: 'bad-token',
        userIdentifier: 'user',
        sdkReadyCallback: sdkReady,
        errorCallback: error,
      );

      expect(sdkReady.wasCalled, isFalse);
      expect(error.received?.code, 42);
      expect(error.received?.description, 'bad token');
    });
  });

  group('setUserIdentifier', () {
    test('passes identifier to platform', () async {
      await plugin.setUserIdentifier('user-99');

      expect(mock.lastMethod, 'setUserIdentifier');
      expect(mock.lastArgs['userIdentifier'], 'user-99');
    });
  });

  group('canShowContentForPlacement', () {
    test('returns true when platform returns true', () async {
      mock.canShowResult = true;
      final error = _ErrorCallback();

      final result =
          await plugin.canShowContentForPlacement('earn-center', error);

      expect(result, isTrue);
      expect(mock.lastArgs['tag'], 'earn-center');
    });

    test('returns false when platform returns false', () async {
      mock.canShowResult = false;
      final result = await plugin.canShowContentForPlacement(
          'earn-center', _ErrorCallback());
      expect(result, isFalse);
    });
  });

  group('sendUserAttributes', () {
    test('passes attributes and clearPreviousAttributes to platform', () async {
      await plugin.sendUserAttributes(
        userAttributes: {'age': 25, 'country': 'US'},
        clearPreviousAttributes: true,
        errorCallback: _ErrorCallback(),
      );

      expect(mock.lastMethod, 'sendUserAttributes');
      expect(mock.lastArgs['userAttributes'], {'age': 25, 'country': 'US'});
      expect(mock.lastArgs['clearPreviousAttributes'], isTrue);
    });
  });

  group('showContentForPlacement', () {
    test('passes tag and fires content callbacks', () async {
      final content = _ContentCallback();
      final error = _ErrorCallback();

      await plugin.showContentForPlacement(
        tag: 'earn-center',
        contentCallback: content,
        errorCallback: error,
      );

      expect(mock.lastMethod, 'showContentForPlacement');
      expect(mock.lastArgs['tag'], 'earn-center');
      expect(content.shownTag, 'earn-center');
      expect(content.dismissedTag, 'earn-center');
    });

    test('works without content callback', () async {
      await plugin.showContentForPlacement(
        tag: 'earn-center',
        errorCallback: _ErrorCallback(),
      );
      expect(mock.lastMethod, 'showContentForPlacement');
    });
  });

  group('isReady', () {
    test('returns true when platform returns true', () async {
      mock.isReadyResult = true;
      expect(await plugin.isReady(), isTrue);
    });

    test('returns false when platform returns false', () async {
      mock.isReadyResult = false;
      expect(await plugin.isReady(), isFalse);
    });
  });

  group('setSurveysRefreshedListener', () {
    test('fires listener with placement tag', () async {
      final listener = _SurveysRefreshedListener();

      await plugin.setSurveysRefreshedListener(listener);

      expect(mock.lastMethod, 'setSurveysRefreshedListener');
      expect(mock.lastArgs['enabled'], isTrue);
      expect(listener.refreshedTag, 'test-placement');
    });

    test('passes null to disable', () async {
      await plugin.setSurveysRefreshedListener(null);

      expect(mock.lastArgs['enabled'], isFalse);
    });
  });

  group('hasSurveysForPlacement', () {
    test('returns true when surveys exist', () async {
      mock.hasSurveysResult = true;
      final result = await plugin.hasSurveysForPlacement(
          'earn-center', _ErrorCallback());

      expect(result, isTrue);
      expect(mock.lastArgs['placementTag'], 'earn-center');
    });
  });

  group('getSurveysForPlacement', () {
    test('returns null when no surveys', () async {
      mock.surveysResult = null;
      final result = await plugin.getSurveysForPlacement(
          'earn-center', _ErrorCallback());
      expect(result, isNull);
    });

    test('returns list of surveys', () async {
      mock.surveysResult = [
        TRSurvey(surveyId: 'survey-1', rewardAmount: 5.0, currencyName: 'Coins'),
      ];
      final result = await plugin.getSurveysForPlacement(
          'earn-center', _ErrorCallback());

      expect(result, hasLength(1));
      expect(result?.first.surveyId, 'survey-1');
      expect(result?.first.rewardAmount, 5.0);
    });
  });

  group('showSurveyForPlacement', () {
    test('passes placementTag and surveyId, fires content callback', () async {
      final content = _ContentCallback();

      await plugin.showSurveyForPlacement(
        placementTag: 'earn-center',
        surveyId: 'survey-1',
        contentCallback: content,
        errorCallback: _ErrorCallback(),
      );

      expect(mock.lastMethod, 'showSurveyForPlacement');
      expect(mock.lastArgs['placementTag'], 'earn-center');
      expect(mock.lastArgs['surveyId'], 'survey-1');
      expect(content.shownTag, 'earn-center');
    });
  });

  group('grantBoost', () {
    test('passes boostTag and fires response listener', () async {
      final listener = _GrantBoostListener();

      await plugin.grantBoost('boost-tag-1', listener: listener);

      expect(mock.lastMethod, 'grantBoost');
      expect(mock.lastArgs['boostTag'], 'boost-tag-1');
      expect(listener.received?.boostTag, 'boost-tag-1');
      expect(listener.received?.success, isTrue);
    });

    test('works without listener', () async {
      await plugin.grantBoost('boost-tag-1');
      expect(mock.lastMethod, 'grantBoost');
    });
  });

  group('getPlacementDetails', () {
    test('returns null when no details', () async {
      mock.placementDetailsResult = null;
      final result = await plugin.getPlacementDetails('earn-center');
      expect(result, isNull);
    });

    test('returns placement details', () async {
      mock.placementDetailsResult = TRPlacementDetails(
        name: 'Earn Center',
        currencyName: 'Coins',
        isSale: false,
      );

      final result = await plugin.getPlacementDetails('earn-center');

      expect(result?.name, 'Earn Center');
      expect(result?.currencyName, 'Coins');
      expect(result?.isSale, isFalse);
    });
  });
}
