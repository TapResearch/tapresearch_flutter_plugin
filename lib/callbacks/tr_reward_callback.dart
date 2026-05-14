import '../models/tr_reward.dart';

/// Indicates a reward event has occurred, e.g. after a user successfully
/// completes a survey and closes the Survey Wall.
abstract class TRRewardCallback {
  /// Invoked whenever a reward is received. Can be triggered by survey
  /// completions, profile questionnaires, or previously un-redeemed rewards.
  void onTapResearchDidReceiveRewards(List<TRReward> rewards);
}
