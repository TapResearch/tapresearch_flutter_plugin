import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'callbacks/callbacks.dart';
import 'models/models.dart';
import 'tapresearch_flutter_plugin_platform_interface.dart';

class MethodChannelTapresearchFlutterPlugin
    extends TapresearchFlutterPluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('tapresearch_flutter_plugin');

  int _nextCallId = 0;

  // Global callbacks that persist across calls
  TRSdkReadyCallback? _sdkReadyCallback;
  TRErrorCallback? _initErrorCallback;
  TRRewardCallback? _rewardCallback;
  TRQQDataCallback? _qqDataCallback;
  TRSurveysRefreshedListener? _surveysRefreshedListener;

  // Per-call callbacks keyed by callId
  final Map<int, TRErrorCallback> _errorCallbacks = {};
  final Map<int, TRContentCallback> _contentCallbacks = {};
  final Map<int, TRGrantBoostResponseListener> _grantBoostCallbacks = {};

  MethodChannelTapresearchFlutterPlugin() {
    methodChannel.setMethodCallHandler(_handleNativeCall);
  }

  int _newCallId() => _nextCallId++;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onSdkReady':
        _sdkReadyCallback?.onTapResearchSdkReady();

      case 'onError':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final error = TRError.fromJson(args);
        final callId = args['callId'] as int?;
        if (callId != null && _errorCallbacks.containsKey(callId)) {
          _errorCallbacks.remove(callId)?.onTapResearchDidError(error);
        } else {
          _initErrorCallback?.onTapResearchDidError(error);
        }

      case 'onReward':
        final list = call.arguments as List<dynamic>;
        final rewards = list
            .map((e) => TRReward.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _rewardCallback?.onTapResearchDidReceiveRewards(rewards);

      case 'onQuickQuestionData':
        final data =
            QQPayload.fromJson(Map<String, dynamic>.from(call.arguments as Map));
        _qqDataCallback?.onQuickQuestionDataReceived(data);

      case 'onContentShown':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final callId = args['callId'] as int?;
        final placementTag = args['placementTag'] as String;
        if (callId != null) {
          _contentCallbacks[callId]?.onTapResearchContentShown(placementTag);
        }

      case 'onContentDismissed':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final callId = args['callId'] as int?;
        final placementTag = args['placementTag'] as String;
        if (callId != null) {
          _contentCallbacks.remove(callId)?.onTapResearchContentDismissed(placementTag);
          _errorCallbacks.remove(callId);
        }

      case 'onSurveysRefreshed':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final placementTag = args['placementTag'] as String;
        _surveysRefreshedListener?.onSurveysRefreshedForPlacement(placementTag);

      case 'onGrantBoostResponse':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final callId = args['callId'] as int?;
        final response = TRGrantBoostResponse.fromJson(args);
        if (callId != null) {
          _grantBoostCallbacks.remove(callId)?.onGrantBoostResponse(response);
        }
    }
  }

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
    _sdkReadyCallback = sdkReadyCallback;
    _initErrorCallback = errorCallback;
    if (rewardCallback != null) _rewardCallback = rewardCallback;
    if (qqDataCallback != null) _qqDataCallback = qqDataCallback;

    await methodChannel.invokeMethod<void>('initialize', {
      'flutterVersion' : flutterVersion,
      'apiToken': apiToken,
      'userIdentifier': userIdentifier,
      'hasRewardCallback': rewardCallback != null,
      'hasQqCallback': qqDataCallback != null,
      'userAttributes': userAttributes,
      'clearPreviousAttributes': clearPreviousAttributes,
    });
  }

  @override
  Future<void> setUserIdentifier(String userIdentifier) async {
    await methodChannel.invokeMethod<void>(
        'setUserIdentifier', {'userIdentifier': userIdentifier});
  }

  @override
  Future<bool> canShowContentForPlacement(
      String tag, TRErrorCallback errorCallback) async {
    final callId = _newCallId();
    _errorCallbacks[callId] = errorCallback;
    final result = await methodChannel.invokeMethod<bool>(
        'canShowContentForPlacement', {'callId': callId, 'tag': tag});
    _errorCallbacks.remove(callId);
    return result ?? false;
  }

  @override
  Future<void> sendUserAttributes({
    required Map<String, dynamic> userAttributes,
    bool? clearPreviousAttributes,
    required TRErrorCallback errorCallback,
  }) async {
    final callId = _newCallId();
    _errorCallbacks[callId] = errorCallback;
    await methodChannel.invokeMethod<void>('sendUserAttributes', {
      'callId': callId,
      'userAttributes': userAttributes,
      'clearPreviousAttributes': clearPreviousAttributes,
    });
  }

  @override
  Future<void> showContentForPlacement({
    required String tag,
    TRContentCallback? contentCallback,
    Map<String, dynamic>? customParameters,
    required TRErrorCallback errorCallback,
  }) async {
    final callId = _newCallId();
    _errorCallbacks[callId] = errorCallback;
    if (contentCallback != null) _contentCallbacks[callId] = contentCallback;

    await methodChannel.invokeMethod<void>('showContentForPlacement', {
      'callId': callId,
      'tag': tag,
      'hasContentCallback': contentCallback != null,
      'customParameters': customParameters,
    });
  }

  @override
  Future<bool> isReady() async {
    final result = await methodChannel.invokeMethod<bool>('isReady');
    return result ?? false;
  }

  @override
  Future<void> setSurveysRefreshedListener(
      TRSurveysRefreshedListener? listener) async {
    _surveysRefreshedListener = listener;
    await methodChannel.invokeMethod<void>(
        'setSurveysRefreshedListener', {'enable': listener != null});
  }

  @override
  Future<bool> hasSurveysForPlacement(
      String placementTag, TRErrorCallback errorCallback) async {
    final callId = _newCallId();
    _errorCallbacks[callId] = errorCallback;
    final result = await methodChannel.invokeMethod<bool>(
        'hasSurveysForPlacement', {'callId': callId, 'placementTag': placementTag});
    _errorCallbacks.remove(callId);
    return result ?? false;
  }

  @override
  Future<List<TRSurvey>?> getSurveysForPlacement(
      String placementTag, TRErrorCallback errorCallback) async {
    final callId = _newCallId();
    _errorCallbacks[callId] = errorCallback;
    final result = await methodChannel.invokeMethod<List<dynamic>>(
        'getSurveysForPlacement', {'callId': callId, 'placementTag': placementTag});
    _errorCallbacks.remove(callId);
    return result
        ?.map((e) => TRSurvey.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> showSurveyForPlacement({
    required String placementTag,
    required String surveyId,
    Map<String, dynamic>? customParameters,
    TRContentCallback? contentCallback,
    required TRErrorCallback errorCallback,
  }) async {
    final callId = _newCallId();
    _errorCallbacks[callId] = errorCallback;
    if (contentCallback != null) _contentCallbacks[callId] = contentCallback;

    await methodChannel.invokeMethod<void>('showSurveyForPlacement', {
      'callId': callId,
      'placementTag': placementTag,
      'surveyId': surveyId,
      'hasContentCallback': contentCallback != null,
      'customParameters': customParameters,
    });
  }

  @override
  Future<void> grantBoost(String boostTag,
      {TRGrantBoostResponseListener? listener}) async {
    final callId = _newCallId();
    if (listener != null) _grantBoostCallbacks[callId] = listener;

    await methodChannel.invokeMethod<void>('grantBoost', {
      'callId': callId,
      'boostTag': boostTag,
      'hasListener': listener != null,
    });
  }

  @override
  Future<TRPlacementDetails?> getPlacementDetails(String placementTag,
      {TRErrorCallback? errorListener}) async {
    final callId = _newCallId();
    if (errorListener != null) _errorCallbacks[callId] = errorListener;

    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getPlacementDetails', {'callId': callId, 'placementTag': placementTag});
    _errorCallbacks.remove(callId);
    return result != null
        ? TRPlacementDetails.fromJson(Map<String, dynamic>.from(result))
        : null;
  }
}