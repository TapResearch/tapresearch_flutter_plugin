/// Indicates when the TapResearch SDK is ready for use and ready to display
/// content such as the Survey Wall, Interstitials, and Quick Questions.
abstract class TRSdkReadyCallback {
  /// Invoked shortly after TapResearch.initialize has been called, indicating
  /// the SDK is ready for use.
  void onTapResearchSdkReady();
}
