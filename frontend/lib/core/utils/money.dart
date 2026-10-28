// Money helpers. All amounts are integer paise; integer arithmetic only.

/// 129900 -> '₹1,299.00', 12999900 -> '₹1,29,999.00' (Indian digit grouping).
String formatPaise(int paise) {
  final negative = paise < 0;
  final abs = negative ? -paise : paise;
  final rupees = (abs ~/ 100).toString();
  final fraction = (abs % 100).toString().padLeft(2, '0');
  String grouped;
  if (rupees.length <= 3) {
    grouped = rupees;
  } else {
    final head = rupees.substring(0, rupees.length - 3);
    final tail = rupees.substring(rupees.length - 3);
    final parts = <String>[];
    for (var i = head.length; i > 0; i -= 2) {
      parts.insert(0, head.substring(i - 2 < 0 ? 0 : i - 2, i));
    }
    grouped = '${parts.join(',')},$tail';
  }
  return '${negative ? '-' : ''}₹$grouped.$fraction';
}

final _rupeePattern = RegExp(r'^\d{1,8}(\.\d{1,2})?$');

/// '1299.50' -> 129950. Returns null for invalid input or a zero amount.
int? rupeesToPaise(String input) {
  final value = input.trim();
  if (!_rupeePattern.hasMatch(value)) return null;
  final parts = value.split('.');
  final whole = int.parse(parts[0]);
  final fraction = parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0;
  final paise = whole * 100 + fraction;
  return paise == 0 ? null : paise;
}

/// 129900 -> '1299.00' (for pre-filling the edit form).
String paiseToRupeesInput(int paise) {
  return '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';
}
