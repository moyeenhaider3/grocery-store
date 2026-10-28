const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatOrderDate(DateTime? d) {
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
}

String formatOrderDateTime(DateTime? d) {
  if (d == null) return '';
  return '${formatOrderDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
