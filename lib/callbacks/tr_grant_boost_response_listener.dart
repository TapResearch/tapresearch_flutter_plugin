import '../models/tr_grant_boost_response.dart';

/// Callback triggered after TapResearch.grantBoost has been called.
abstract class TRGrantBoostResponseListener {
  /// Occurs as a response to TapResearch.grantBoost.
  ///
  /// [grantBoostResponse] - The grant boost response.
  void onGrantBoostResponse(TRGrantBoostResponse grantBoostResponse);
}
