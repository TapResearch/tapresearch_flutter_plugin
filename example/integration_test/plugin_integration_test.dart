import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tapresearch_flutter_plugin/tapresearch_flutter_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TapresearchFlutterPlugin Integration Tests', () {
    final TapresearchFlutterPlugin plugin = TapresearchFlutterPlugin();
    Completer<bool> completer = Completer<bool>();
    testWidgets('initialize and isReady check', (WidgetTester tester) async {
      // Basic initialization test
      await plugin.initialize(
        apiToken: 'fb28e5e0572876db0790ecaf6c588598',
        userIdentifier: 'tr-sdk-test-user-46183135',
        sdkReadyCallback: _SdkReadyCallback(() {
          completer.complete(true);
        }),
        errorCallback: _ErrorCallback((error) {
          completer.complete(false);
        }),
      );
      var result = await completer.future;
      final bool ready = await plugin.isReady();
      expect(ready, true);
      expect(result, true);
    });

    testWidgets('setUserIdentifier and sendUserAttributes', (WidgetTester tester) async {
      await plugin.setUserIdentifier('new-integration-user');

      await plugin.sendUserAttributes(
        userAttributes: {'integration_test': true, 'platform': 'flutter'},
        errorCallback: _ErrorCallback((e) {}),
      );
    });

    testWidgets('placement checks', (WidgetTester tester) async {
      const String tag = 'earn-center';

      final bool canShow = await plugin.canShowContentForPlacement(
        tag,
        _ErrorCallback((e) {}),
      );
      expect(canShow, true);

      final bool hasSurveys = await plugin.hasSurveysForPlacement(
        tag,
        _ErrorCallback((e) {}),
      );
      expect(hasSurveys, true);
    });

    testWidgets('getPlacementDetails', (WidgetTester tester) async {
      final details = await plugin.getPlacementDetails(
        'earn-center',
        errorListener: _ErrorCallback((e) {}),
      );
      // Details might be null if placement doesn't exist, but it shouldn't crash
      if (details != null) {
        expect(details.currencyName, isNotNull);
      }
    });

    testWidgets('getSurveysForPlacement', (WidgetTester tester) async {
      final surveys = await plugin.getSurveysForPlacement(
        'earn-center',
        _ErrorCallback((e) {}),
      );
      if (surveys != null) {
        expect(surveys, isA<List<TRSurvey>>());
      }
    });

    testWidgets('setSurveysRefreshedListener', (WidgetTester tester) async {
      await plugin.setSurveysRefreshedListener(_SurveysRefreshedListener((tag) {}));
      await plugin.setSurveysRefreshedListener(null);
    });

    testWidgets('grantBoost', (WidgetTester tester) async {
      await plugin.grantBoost('test-boost', listener: _GrantBoostListener((resp) {}));
    });

    testWidgets('showContentForPlacement (non-blocking call)', (WidgetTester tester) async {
      await plugin.showContentForPlacement(
        tag: 'integration-tag',
        errorCallback: _ErrorCallback((e) {}),
      );
    });

    testWidgets('showSurveyForPlacement (non-blocking call)', (WidgetTester tester) async {
      await plugin.showSurveyForPlacement(
        placementTag: 'integration-tag',
        surveyId: 'test-survey-id',
        errorCallback: _ErrorCallback((e) {}),
      );
    });
  });
}

class _SdkReadyCallback implements TRSdkReadyCallback {
  final Function onReady;
  _SdkReadyCallback(this.onReady);
  @override
  void onTapResearchSdkReady() => onReady();
}

class _ErrorCallback implements TRErrorCallback {
  final Function(TRError) onError;
  _ErrorCallback(this.onError);
  @override
  void onTapResearchDidError(TRError error) => onError(error);
}

class _SurveysRefreshedListener implements TRSurveysRefreshedListener {
  final Function(String) onRefreshed;
  _SurveysRefreshedListener(this.onRefreshed);
  @override
  void onSurveysRefreshedForPlacement(String placementTag) => onRefreshed(placementTag);
}

class _GrantBoostListener implements TRGrantBoostResponseListener {
  final Function(TRGrantBoostResponse) onResponse;
  _GrantBoostListener(this.onResponse);
  @override
  void onGrantBoostResponse(TRGrantBoostResponse grantBoostResponse) => onResponse(grantBoostResponse);
}
