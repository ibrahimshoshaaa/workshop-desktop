/// EGP values are calculated in integer piastres. SQLite retains its existing
/// REAL columns for compatibility; no historical record is rewritten here.
class Money {
  static const maxValue = 1000000000000.0;
  static int cents(num value) {
    if (!value.isFinite || value.abs() > maxValue)
      throw StateError('قيمة مالية غير صالحة');
    return (value * 100).round();
  }

  static double amount(int cents) => cents / 100;
  static double sum(Iterable<num> values) =>
      amount(values.fold<int>(0, (s, v) => s + cents(v)));
  static double subtract(num a, num b) => amount(cents(a) - cents(b));
  static double require(
    double value, {
    bool allowZero = false,
    bool signed = false,
  }) {
    final result = amount(cents(value));
    if ((!signed && value < 0) ||
        (!allowZero && result == 0) ||
        (value - result).abs() > 0.000001) {
      throw StateError(
        'أدخل مبلغًا صحيحًا بالجنيه والقرش (منزلتان عشريتان بحد أقصى)',
      );
    }
    return result;
  }

  static double? tryParse(String input) {
    var text = input.trim();
    for (var i = 0; i < 10; i++) {
      text = text
          .replaceAll(String.fromCharCode(0x660 + i), '$i')
          .replaceAll(String.fromCharCode(0x6f0 + i), '$i');
    }
    text = text.replaceAll('٫', '.').replaceAll('٬', '');
    if (RegExp(r'^[+-]?\d{1,3}(,\d{3})+(\.\d{1,2})?$').hasMatch(text)) {
      text = text.replaceAll(',', '');
    } else {
      text = text.replaceAll(',', '.');
    }
    if (!RegExp(r'^[+-]?\d+(\.\d{1,2})?$').hasMatch(text)) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite || value.abs() > maxValue) return null;
    return value;
  }

  static double parse(String input) =>
      tryParse(input) ?? (throw const FormatException('المبلغ غير صالح'));
  static List<double> split(double value, int count) {
    if (count <= 0) return [];
    final total = cents(require(value));
    return List.generate(
      count,
      (i) => amount(total ~/ count + (i < total % count ? 1 : 0)),
    );
  }
}
