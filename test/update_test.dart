import 'package:flutter_test/flutter_test.dart';
import 'package:vehiculos_app/services/update_service.dart';

void main() {
  test('compareVersions compara por número, no como texto', () {
    expect(compareVersions('1.10.0', '1.9.2'), greaterThan(0));
    expect(compareVersions('1.4.0', '1.4.0'), 0);
    expect(compareVersions('1.4', '1.4.0'), 0);
    expect(compareVersions('1.3.9', '1.4.0'), lessThan(0));
    expect(compareVersions('2.0.0-beta', '1.9.9'), greaterThan(0));
  });
}
