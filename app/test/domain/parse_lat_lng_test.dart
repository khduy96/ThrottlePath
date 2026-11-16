import 'package:flutter_test/flutter_test.dart';
import 'package:throttle_path/domain/parse_lat_lng.dart';

void main() {
  void expectOk(String input, double lat, double lng) {
    final r = parseLatLng(input);
    expect(r.error, isNull, reason: input);
    expect(r.value!.lat, closeTo(lat, 1e-9), reason: input);
    expect(r.value!.lng, closeTo(lng, 1e-9), reason: input);
  }

  test('plain pairs', () {
    expectOk('10.7769, 106.7009', 10.7769, 106.7009);
    expectOk('10.7769,106.7009', 10.7769, 106.7009);
    expectOk('  10.7769 106.7009 ', 10.7769, 106.7009);
    expectOk('-33.5;151.25', -33.5, 151.25);
  });

  test('Google Maps links', () {
    expectOk('https://www.google.com/maps/@10.7769,106.7009,17z', 10.7769, 106.7009);
    expectOk('https://maps.google.com/?q=10.7769,106.7009', 10.7769, 106.7009);
    expectOk('https://www.google.com/maps/search/?api=1&query=10.7769%2C106.7009', 10.7769, 106.7009);
    expectOk('https://www.google.com/maps/place/10.7769,106.7009', 10.7769, 106.7009);
    expectOk('https://www.google.com/maps/dir/?api=1&destination=10.7769,106.7009', 10.7769, 106.7009);
  });

  test('place pin beats map centre', () {
    expectOk(
      'https://www.google.com/maps/place/Ben+Thanh/@10.7700,106.6900,17z/data=!3m1!4b1!4m6!3m5!1s0x0:0x0!8m2!3d10.7725!4d106.6980',
      10.7725,
      106.6980,
    );
  });

  test('errors', () {
    expect(parseLatLng('').error, isNotNull);
    expect(parseLatLng('hello').error, isNotNull);
    expect(parseLatLng('95, 106').error, isNotNull);
    expect(parseLatLng('https://maps.app.goo.gl/abc123').error, contains('rút gọn'));
  });
}
