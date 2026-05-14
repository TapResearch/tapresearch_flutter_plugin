import '../models/quick_question.dart';

/// Indicates when a Quick Question has been answered and the dialog dismissed.
abstract class TRQQDataCallback {
  /// Invoked whenever a Quick Question has been completed and the dialog dismissed.
  ///
  /// [data] - Contains all data pertaining to the answered Quick Question.
  void onQuickQuestionDataReceived(QQPayload data);
}
