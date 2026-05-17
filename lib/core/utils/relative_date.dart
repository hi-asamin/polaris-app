/// 日本語の簡易相対日付。`DateTime.now()` を基準にした近似表現を返す。
String relativeDate(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(date);

  if (diff.isNegative) return 'たった今';
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}週間前';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}ヶ月前';
  return '${(diff.inDays / 365).floor()}年前';
}
