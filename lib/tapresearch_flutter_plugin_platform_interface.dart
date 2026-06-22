import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'callbacks/callbacks.dart';
import 'models/models.dart';
import 'tapresearch_flutter_plugin_method_channel.dart';

abstract class TapresearchFlutterPluginPlatform extends PlatformInterface {
  TapresearchFlutterPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static TapresearchFlutterPluginPlatform _instance =
      MethodChannelTapresearchFlutterPlugin();

  static TapresearchFlutterPluginPlatform get instance => _instance;

  static set instance(TapresearchFlutterPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

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
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> setUserIdentifier(String userIdentifier) {
    throw UnimplementedError('setUserIdentifier() has not been implemented.');
  }

  Future<bool> canShowContentForPlacement(
      String tag, TRErrorCallback errorCallback) {
    throw UnimplementedError(
        'canShowContentForPlacement() has not been implemented.');
  }

  Future<void> sendUserAttributes({
    required Map<String, dynamic> userAttributes,
    bool? clearPreviousAttributes,
    required TRErrorCallback errorCallback,
  }) {
    throw UnimplementedError('sendUserAttributes() has not been implemented.');
  }

  Future<void> showContentForPlacement({
    required String tag,
    TRContentCallback? contentCallback,
    Map<String, dynamic>? customParameters,
    required TRErrorCallback errorCallback,
  }) {
    throw UnimplementedError(
        'showContentForPlacement() has not been implemented.');
  }

  Future<bool> isReady() {
    throw UnimplementedError('isReady() has not been implemented.');
  }

  Future<void> setSurveysRefreshedListener(
      TRSurveysRefreshedListener? listener) {
    throw UnimplementedError(
        'setSurveysRefreshedListener() has not been implemented.');
  }

  Future<bool> hasSurveysForPlacement(
      String placementTag, TRErrorCallback errorCallback) {
    throw UnimplementedError(
        'hasSurveysForPlacement() has not been implemented.');
  }

  Future<List<TRSurvey>?> getSurveysForPlacement(
      String placementTag, TRErrorCallback errorCallback) {
    throw UnimplementedError(
        'getSurveysForPlacement() has not been implemented.');
  }

  Future<void> showSurveyForPlacement({
    required String placementTag,
    required String surveyId,
    Map<String, dynamic>? customParameters,
    TRContentCallback? contentCallback,
    required TRErrorCallback errorCallback,
  }) {
    throw UnimplementedError(
        'showSurveyForPlacement() has not been implemented.');
  }

  Future<void> grantBoost(String boostTag,
      {TRGrantBoostResponseListener? listener}) {
    throw UnimplementedError('grantBoost() has not been implemented.');
  }

  Future<TRPlacementDetails?> getPlacementDetails(String placementTag,
      {TRErrorCallback? errorListener}) {
    throw UnimplementedError('getPlacementDetails() has not been implemented.');
  }
}