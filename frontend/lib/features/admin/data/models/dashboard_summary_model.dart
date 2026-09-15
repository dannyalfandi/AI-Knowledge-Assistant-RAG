import '../../../documents/domain/entities/document_status.dart';
import '../../domain/entities/dashboard_summary.dart';

/// Transport representation of [DashboardSummary].
///
/// Every count is read defensively: a dashboard that renders zeros is far more
/// useful than one that throws because a bucket was absent.
class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.totalUsers,
    required super.totalDocuments,
    required super.documentsByStatus,
    required super.totalConversations,
    required super.questionsAsked,
    required super.questionsAnswered,
    required super.feedbackTotal,
    required super.feedbackPositive,
    required super.feedbackNegative,
    required super.fetchedAt,
  });

  factory DashboardSummaryModel.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final documents = _section(json['documents']);
    final questions = _section(json['questions']);
    final feedback = _section(json['feedback']);

    return DashboardSummaryModel(
      totalUsers: _count(_section(json['users'])['total']),
      totalDocuments: _count(documents['total']),
      documentsByStatus: _parseByStatus(documents['byStatus']),
      totalConversations: _count(_section(json['conversations'])['total']),
      questionsAsked: _count(questions['asked']),
      questionsAnswered: _count(questions['answered']),
      feedbackTotal: _count(feedback['total']),
      feedbackPositive: _count(feedback['positive']),
      feedbackNegative: _count(feedback['negative']),
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _section(Object? raw) {
    return raw is Map<String, dynamic> ? raw : const {};
  }

  static int _count(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  /// The backend always sends all four statuses, but every one is defaulted
  /// here anyway so a new status added server-side cannot blank the breakdown.
  static Map<DocumentStatus, int> _parseByStatus(Object? raw) {
    final byStatus = raw is Map ? raw : const {};

    return {
      for (final status in _wireNames.entries)
        status.value: _count(byStatus[status.key]),
    };
  }

  static const _wireNames = <String, DocumentStatus>{
    'PENDING': DocumentStatus.pending,
    'PROCESSING': DocumentStatus.processing,
    'INDEXED': DocumentStatus.indexed,
    'FAILED': DocumentStatus.failed,
  };
}
