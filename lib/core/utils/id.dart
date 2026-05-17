import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 端末側で発番する UUIDv7。時間順ソート可能で、後の同期にも安全。
String newId() => _uuid.v7();
