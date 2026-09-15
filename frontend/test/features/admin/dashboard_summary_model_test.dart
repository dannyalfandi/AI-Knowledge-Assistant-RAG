import 'package:enterprise_knowledge_assistant/features/admin/data/models/dashboard_summary_model.dart';
import 'package:enterprise_knowledge_assistant/features/documents/domain/entities/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _payload() {
  return {
    'users': {'total': 12},
    'documents': {
      'total': 9,
      'byStatus': {'PENDING': 2, 'PROCESSING': 1, 'INDEXED': 5, 'FAILED': 1},
    },
    'conversations': {'total': 31},
    'questions': {'asked': 87, 'answered': 85},
    'feedback': {'total': 20, 'positive': 14, 'negative': 6},
  };
}

void main() {
  group('happy path', () {
    test('parses every section of the dashboard payload', () {
      final summary = DashboardSummaryModel.fromJson(_payload());

      expect(summary.totalUsers, 12);
      expect(summary.totalDocuments, 9);
      expect(summary.totalConversations, 31);
      expect(summary.questionsAsked, 87);
      expect(summary.questionsAnswered, 85);
      expect(summary.feedbackTotal, 20);
      expect(summary.feedbackPositive, 14);
      expect(summary.feedbackNegative, 6);
    });

    test('maps every document status to its count', () {
      final summary = DashboardSummaryModel.fromJson(_payload());

      expect(summary.countFor(DocumentStatus.pending), 2);
      expect(summary.countFor(DocumentStatus.processing), 1);
      expect(summary.countFor(DocumentStatus.indexed), 5);
      expect(summary.countFor(DocumentStatus.failed), 1);
      expect(summary.hasDocuments, isTrue);
    });

    test('records when the snapshot was taken', () {
      final at = DateTime(2026, 9, 12, 14, 30);

      final summary = DashboardSummaryModel.fromJson(_payload(), fetchedAt: at);

      expect(summary.fetchedAt, at);
    });
  });

  group('empty instance', () {
    test('a brand-new install reads as all zeros, not as an error', () {
      final summary = DashboardSummaryModel.fromJson({
        'users': {'total': 0},
        'documents': {
          'total': 0,
          'byStatus': {
            'PENDING': 0,
            'PROCESSING': 0,
            'INDEXED': 0,
            'FAILED': 0,
          },
        },
        'conversations': {'total': 0},
        'questions': {'asked': 0, 'answered': 0},
        'feedback': {'total': 0, 'positive': 0, 'negative': 0},
      });

      expect(summary.totalUsers, 0);
      expect(summary.hasDocuments, isFalse);
      expect(summary.hasFeedback, isFalse);
    });
  });

  group('defensive parsing', () {
    test('a missing section degrades to zeros rather than throwing', () {
      final summary = DashboardSummaryModel.fromJson({
        'users': {'total': 3},
      });

      expect(summary.totalUsers, 3);
      expect(summary.totalDocuments, 0);
      expect(summary.totalConversations, 0);
      expect(summary.feedbackTotal, 0);
    });

    test('a status absent from byStatus counts as zero', () {
      final summary = DashboardSummaryModel.fromJson({
        'documents': {
          'total': 1,
          'byStatus': {'INDEXED': 1},
        },
      });

      expect(summary.countFor(DocumentStatus.indexed), 1);
      expect(summary.countFor(DocumentStatus.failed), 0);
      expect(summary.countFor(DocumentStatus.pending), 0);
    });

    test('every known status is present even when byStatus is absent', () {
      final summary = DashboardSummaryModel.fromJson({
        'documents': {'total': 0},
      });

      expect(
        summary.documentsByStatus.keys,
        containsAll(
          DocumentStatus.values.where((s) => s != DocumentStatus.unknown),
        ),
      );
    });
  });
}
