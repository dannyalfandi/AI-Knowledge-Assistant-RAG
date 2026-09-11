import 'package:enterprise_knowledge_assistant/core/api/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApiConfig exposes a non-empty base URL and the /api prefix', () {
    expect(ApiConfig.baseUrl, isNotEmpty);
    expect(ApiConfig.apiPrefix, '/api');
  });
}
