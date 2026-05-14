/// TapResearch content callback for Survey Wall and Quick Question visibility events.
abstract class TRContentCallback {
  /// Invoked whenever the Survey Wall activity is shown or a Quick Question appears on screen.
  ///
  /// [placementTag] - The placement tag string, e.g. "home-screen" or "earn-center".
  void onTapResearchContentShown(String placementTag);

  /// Invoked whenever the Survey Wall activity is dismissed or a Quick Question dialog is dismissed.
  ///
  /// [placementTag] - The placement tag string, e.g. "home-screen" or "earn-center".
  void onTapResearchContentDismissed(String placementTag);
}
