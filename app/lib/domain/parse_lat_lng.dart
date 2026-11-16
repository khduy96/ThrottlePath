import 'geo.dart';

/// Result of [parseLatLng]: either a coordinate or a Vietnamese error message.
class ParseLatLngResult {
  const ParseLatLngResult.ok(LatLng this.value) : error = null;
  const ParseLatLngResult.fail(String this.error) : value = null;

  final LatLng? value;
  final String? error;
}

const _num = r'(-?\d{1,3}(?:\.\d+)?)';

// Ordered by precision: the place pin (!3d…!4d…) beats the map centre (@…).
final _patterns = <RegExp>[
  RegExp('!3d$_num!4d$_num'),
  RegExp('[?&](?:q|query|ll|destination|daddr|center)=(?:loc:)?$_num,\\s*$_num'),
  RegExp('/place/$_num,\\s*$_num'),
  RegExp('/dir/[^?]*?/$_num,\\s*$_num'),
  RegExp('@$_num,$_num'),
  RegExp('^\\s*$_num\\s*[,; ]\\s*$_num\\s*\$'),
];

/// Parses a plain "lat, lng" pair or a common Google Maps link.
ParseLatLngResult parseLatLng(String input) {
  var text = input.trim();
  if (text.isEmpty) return const ParseLatLngResult.fail('Chưa nhập gì.');
  try {
    text = Uri.decodeFull(text);
  } on ArgumentError {
    // Keep the raw text when it is not valid percent-encoding.
  }
  if (RegExp(r'(maps\.app\.goo\.gl|goo\.gl/maps)').hasMatch(text)) {
    return const ParseLatLngResult.fail(
        'Link rút gọn không chứa tọa độ. Mở link trong trình duyệt rồi copy link đầy đủ, '
        'hoặc nhấn giữ điểm trên Google Maps để copy tọa độ.');
  }
  for (final re in _patterns) {
    final m = re.firstMatch(text);
    if (m == null) continue;
    final lat = double.tryParse(m.group(1)!);
    final lng = double.tryParse(m.group(2)!);
    if (lat == null || lng == null) continue;
    final p = LatLng(lat, lng);
    if (!p.isValid) return const ParseLatLngResult.fail('Tọa độ ngoài phạm vi.');
    return ParseLatLngResult.ok(p);
  }
  return const ParseLatLngResult.fail('Không đọc được tọa độ. Dán dạng "10.77, 106.69" hoặc link Google Maps.');
}
