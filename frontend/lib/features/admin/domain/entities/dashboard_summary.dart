import '../../../documents/domain/entities/document_status.dart';

/// Aggregate counts behind the admin dashboard, as returned by
/// `GET /api/admin/dashboard`.
class DashboardSummary {
  const DashboardSummary({
    required this.totalUsers,
    required this.totalDocuments,
    required this.documentsByStatus,
    required this.totalConversations,
    required this.questionsAsked,
    required this.questionsAnswered,
    required this.feedbackTotal,
    required this.feedbackPositive,
    required this.feedbackNegative,
    required this.fetchedAt,
  });

  final int totalUsers;

  final int totalDocuments;

  /// Count per processing status. The backend seeds every status, so all four
  /// keys are always present — a status missing here would be a contract
  /// change, not an empty bucket.
  ///
  /// Keyed by the documents feature's own enum rather than a parallel copy, so
  /// the dashboard can never drift from the documents screen on naming or
  /// colour.
  final Map<DocumentStatus, int> documentsByStatus;

  final int totalConversations;

  /// USER messages ever sent.
  final int questionsAsked;

  /// ASSISTANT messages ever produced.
  final int questionsAnswered;

  final int feedbackTotal;
  final int feedbackPositive;
  final int feedbackNegative;

  /// When this snapshot was loaded. The dashboard is fetched on demand, not
  /// polled, so the screen states how old the numbers are.
  final DateTime fetchedAt;

  int countFor(DocumentStatus status) => documentsByStatus[status] ?? 0;

  bool get hasDocuments => totalDocuments > 0;

  bool get hasFeedback => feedbackTotal > 0;
}
