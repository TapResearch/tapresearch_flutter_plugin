import 'callbacks/callbacks.dart';
import 'models/models.dart';
import 'tapresearch_flutter_plugin_platform_interface.dart';

export 'callbacks/callbacks.dart';
export 'models/models.dart';

class TapresearchFlutterPlugin {
  Future<void> initialize({
    required String apiToken,
    required String userIdentifier,
    TRRewardCallback? rewardCallback,
    required TRErrorCallback errorCallback,
    required TRSdkReadyCallback sdkReadyCallback,
    TRQQDataCallback? qqDataCallback,
    Map<String, dynamic>? userAttributes,
    bool? clearPreviousAttributes,
  }) {
    return TapresearchFlutterPluginPlatform.instance.initialize(
      apiToken: apiToken,
      userIdentifier: userIdentifier,
      rewardCallback: rewardCallback,
      errorCallback: errorCallback,
      sdkReadyCallback: sdkReadyCallback,
      qqDataCallback: qqDataCallback,
      userAttributes: userAttributes,
      clearPreviousAttributes: clearPreviousAttributes,
    );
  }

  Future<void> setUserIdentifier(String userIdentifier) {
    return TapresearchFlutterPluginPlatform.instance
        .setUserIdentifier(userIdentifier);
  }

  Future<bool> canShowContentForPlacement(
      String tag, TRErrorCallback errorCallback) {
    return TapresearchFlutterPluginPlatform.instance
        .canShowContentForPlacement(tag, errorCallback);
  }

  Future<void> sendUserAttributes({
    required Map<String, dynamic> userAttributes,
    bool? clearPreviousAttributes,
    required TRErrorCallback errorCallback,
  }) {
    return TapresearchFlutterPluginPlatform.instance.sendUserAttributes(
      userAttributes: userAttributes,
      clearPreviousAttributes: clearPreviousAttributes,
      errorCallback: errorCallback,
    );
  }

  Future<void> showContentForPlacement({
    required String tag,
    TRContentCallback? contentCallback,
    Map<String, dynamic>? customParameters,
    required TRErrorCallback errorCallback,
  }) {
    return TapresearchFlutterPluginPlatform.instance.showContentForPlacement(
      tag: tag,
      contentCallback: contentCallback,
      customParameters: customParameters,
      errorCallback: errorCallback,
    );
  }

  Future<bool> isReady() {
    return TapresearchFlutterPluginPlatform.instance.isReady();
  }

  Future<void> setSurveysRefreshedListener(
      TRSurveysRefreshedListener? listener) {
    return TapresearchFlutterPluginPlatform.instance
        .setSurveysRefreshedListener(listener);
  }

  Future<bool> hasSurveysForPlacement(
      String placementTag, TRErrorCallback errorCallback) {
    return TapresearchFlutterPluginPlatform.instance
        .hasSurveysForPlacement(placementTag, errorCallback);
  }

  Future<List<TRSurvey>?> getSurveysForPlacement(
      String placementTag, TRErrorCallback errorCallback) {
    return TapresearchFlutterPluginPlatform.instance
        .getSurveysForPlacement(placementTag, errorCallback);
  }

  Future<void> showSurveyForPlacement({
    required String placementTag,
    required String surveyId,
    Map<String, dynamic>? customParameters,
    TRContentCallback? contentCallback,
    required TRErrorCallback errorCallback,
  }) {
    return TapresearchFlutterPluginPlatform.instance.showSurveyForPlacement(
      placementTag: placementTag,
      surveyId: surveyId,
      customParameters: customParameters,
      contentCallback: contentCallback,
      errorCallback: errorCallback,
    );
  }

  Future<void> grantBoost(String boostTag,
      {TRGrantBoostResponseListener? listener}) {
    return TapresearchFlutterPluginPlatform.instance
        .grantBoost(boostTag, listener: listener);
  }

  Future<TRPlacementDetails?> getPlacementDetails(String placementTag,
      {TRErrorCallback? errorListener}) {
    return TapresearchFlutterPluginPlatform.instance
        .getPlacementDetails(placementTag, errorListener: errorListener);
  }
}