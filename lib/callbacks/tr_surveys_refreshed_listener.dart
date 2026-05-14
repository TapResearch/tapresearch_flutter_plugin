/// Invoked whenever surveys for a placement have been refreshed and are ready
/// to be fetched again via TapResearch.getSurveysForPlacement.
abstract class TRSurveysRefreshedListener {
  /// Invoked whenever surveys have been refreshed for a particular placement.
  ///
  /// [placementTag] - The placement tag string, e.g. "home-screen" or "earn-center".
  void onSurveysRefreshedForPlacement(String placementTag);
}
