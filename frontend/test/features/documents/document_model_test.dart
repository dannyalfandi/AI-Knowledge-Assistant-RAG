import 'package:enterprise_knowledge_assistant/features/documents/data/models/document_model.dart';
import 'package:enterprise_knowledge_assistant/features/documents/domain/entities/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _listPayload({
  String status = 'INDEXED',
  Object? fileSize = '2048',
  Object? errorMessage,
  int chunks = 12,
}) {
  return {
    'id': 'doc-1',
    'originalName': 'Refund Policy.pdf',
    'mimeType': 'application/pdf',
    'fileSize': fileSize,
    'status': status,
    'errorMessage': errorMessage,
    'createdAt': '2026-09-01T10:00:00.000Z',
    'updatedAt': '2026-09-01T10:05:00.000Z',
    'uploadedBy': {'id': 'u1', 'name': 'Admin', 'email': 'admin@corp.com'},
    '_count': {'chunks': chunks},
  };
}

void main() {
  group('happy path', () {
    test('parses the full list/detail payload', () {
      final document = DocumentModel.fromJson(_listPayload());

      expect(document.id, 'doc-1');
      expect(document.originalName, 'Refund Policy.pdf');
      expect(document.status, DocumentStatus.indexed);
      expect(document.chunkCount, 12);
      expect(document.uploadedBy?.displayName, 'Admin');
      expect(document.errorMessage, isNull);
    });

    test('reads fileSize sent as a string (BigInt column)', () {
      expect(DocumentModel.fromJson(_listPayload()).fileSize, 2048);
    });

    test('keeps the failure reason for a FAILED document', () {
      final document = DocumentModel.fromJson(
        _listPayload(
          status: 'FAILED',
          errorMessage: 'No text could be extracted from the PDF',
          chunks: 0,
        ),
      );

      expect(document.status, DocumentStatus.failed);
      expect(document.errorMessage, 'No text could be extracted from the PDF');
    });
  });

  group('upload response (subset payload)', () {
    test('fills the missing uploadedBy/_count with empty values', () {
      final document = DocumentModel.fromJson({
        'id': 'doc-2',
        'originalName': 'SOP.pdf',
        'mimeType': 'application/pdf',
        'fileSize': '512',
        'status': 'PENDING',
        'createdAt': '2026-09-01T10:00:00.000Z',
      });

      expect(document.status, DocumentStatus.pending);
      expect(document.chunkCount, 0);
      expect(document.uploadedBy, isNull);
      // No updatedAt in this payload: it falls back to createdAt.
      expect(document.updatedAt, document.createdAt);
    });
  });

  group('edge cases', () {
    test('an unrecognised status degrades to unknown instead of throwing', () {
      final document = DocumentModel.fromJson(
        _listPayload(status: 'ARCHIVED'),
      );

      expect(document.status, DocumentStatus.unknown);
      expect(document.status.isProcessable, isFalse);
    });

    test('an unparsable fileSize falls back to zero', () {
      expect(
        DocumentModel.fromJson(_listPayload(fileSize: 'not-a-number')).fileSize,
        0,
      );
    });

    test('a blank errorMessage is normalised to null', () {
      expect(
        DocumentModel.fromJson(
          _listPayload(status: 'FAILED', errorMessage: '   '),
        ).errorMessage,
        isNull,
      );
    });

    test('only PENDING and FAILED are processable', () {
      expect(DocumentStatus.pending.isProcessable, isTrue);
      expect(DocumentStatus.failed.isProcessable, isTrue);
      expect(DocumentStatus.processing.isProcessable, isFalse);
      expect(DocumentStatus.indexed.isProcessable, isFalse);
    });
  });
}
