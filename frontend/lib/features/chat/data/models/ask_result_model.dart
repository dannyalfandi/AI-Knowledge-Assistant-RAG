import '../../domain/entities/ask_result.dart';
import 'message_model.dart';

/// Transport representation of [AskResult].
///
/// The backend returns `sources` at the top level rather than inside
/// `assistantMessage`, so they are attached to the assistant message here —
/// that way the UI treats a fresh answer exactly like one loaded from history.
class AskResultModel extends AskResult {
  const AskResultModel({
    required super.userMessage,
    required super.assistantMessage,
  });

  factory AskResultModel.fromJson(Map<String, dynamic> json) {
    final assistant = Map<String, dynamic>.from(
      json['assistantMessage'] as Map<String, dynamic>,
    )..['sources'] = json['sources'];

    return AskResultModel(
      userMessage: MessageModel.fromJson(
        json['userMessage'] as Map<String, dynamic>,
      ),
      assistantMessage: MessageModel.fromJson(assistant),
    );
  }
}
