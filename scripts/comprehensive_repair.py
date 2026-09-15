from pathlib import Path
import re


def replace_once(path: str, pattern: str, replacement: str, flags: int = 0) -> None:
    p = Path(path)
    text = p.read_text(encoding='utf-8')
    new, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise SystemExit(f'{path}: expected exactly one match, got {count}')
    p.write_text(new, encoding='utf-8')


replace_once('lib/services/sync_service.dart', r"Future<Map<String, dynamic>\?> _fetchNode\(String path\) async \{.*?\n  \}", '''Future<Map<String, dynamic>> _fetchNode(String path) async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$path.json'));
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw StateError('Firebase GET failed ($path): HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded == null) return <String, dynamic>{};
    if (decoded is! Map) throw StateError('Firebase returned invalid data for $path');
    return decoded.cast<String, dynamic>();
  }''', flags=re.S)
replace_once('lib/services/sync_service.dart', r"Future<void> _putNode\(String path, Map<String, dynamic> data\) async \{.*?\n  \}", '''Future<void> _putNode(String path, Map<String, dynamic> data) async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$path.json'));
    final response = await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('Firebase PUT failed ($path): HTTP ${response.statusCode}');
  }''', flags=re.S)
replace_once('lib/services/sync_service.dart', r"Future<void> _deleteNode\(String path\) async \{.*?\n  \}", '''Future<void> _deleteNode(String path) async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$path.json'));
    final response = await http.delete(uri).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('Firebase DELETE failed ($path): HTTP ${response.statusCode}');
  }''', flags=re.S)
replace_once('lib/services/sync_service.dart', r"final remoteUpdatedAt = \(map\['paymentDate'\] as num\?\)\?\.toInt\(\) \?\? 0;", "final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? (map['paymentDate'] as num?)?.toInt() ?? 0;")
replace_once('lib/services/sync_service.dart', r"'paymentDate': row\.paymentDate,\n          'paymentType': row\.paymentType,", "'paymentDate': row.paymentDate,\n          'updatedAt': row.updatedAt,\n          'paymentType': row.paymentType,")
replace_once('lib/services/sync_service.dart', r"final remoteUpdatedAt = \(map\['date'\] as num\?\)\?\.toInt\(\) \?\? 0;", "final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? (map['date'] as num?)?.toInt() ?? 0;")
replace_once('lib/services/sync_service.dart', r"'orderAllocationsJson': row\.orderAllocationsJson,\n          'date': row\.date,", "'orderAllocationsJson': row.orderAllocationsJson,\n          'date': row.date,\n          'updatedAt': row.updatedAt,")
replace_once('lib/providers/auth_provider.dart', r"bool can\(String screenKey\) => isAdmin \|\| \(permissions\[screenKey\] \?\? true\);", "bool can(String screenKey) => isAdmin || (permissions[screenKey] ?? false);")
replace_once('lib/models/app_user_model.dart', r"bool canAccess\(String screenKey\) => permissions\[screenKey\] \?\? true;", "bool canAccess(String screenKey) => permissions[screenKey] ?? false;")
replace_once('lib/services/user_account_service.dart', r"if \(response\.statusCode != 200\) return \[\];\n    final decoded = jsonDecode\(response\.body\);\n    if \(decoded is! Map\) return \[\];", "if (response.statusCode != 200) throw StateError('Firebase GET failed (app_users): HTTP ${response.statusCode}');\n    final decoded = jsonDecode(response.body);\n    if (decoded == null) return [];\n    if (decoded is! Map) throw StateError('Firebase returned invalid app_users data');")
replace_once('lib/services/user_account_service.dart', r"final decoded = jsonDecode\(response\.body\) as Map<String, dynamic>;\n    return decoded\['name'\] as String;", "if (response.statusCode < 200 || response.statusCode >= 300) {\n      final decodedError = jsonDecode(response.body);\n      final message = decodedError is Map ? (decodedError['error'] ?? decodedError['message'] ?? 'فشل حفظ الحساب').toString() : 'فشل حفظ الحساب';\n      throw StateError(message);\n    }\n    final decoded = jsonDecode(response.body) as Map<String, dynamic>;\n    return decoded['name'] as String;")
replace_once('lib/services/user_account_service.dart', r"await http\.patch\(uri, body: jsonEncode\(\{'permissions': permissions\}\)\)\.timeout\(_timeout\);", "final response = await http.patch(uri, body: jsonEncode({'permissions': permissions})).timeout(_timeout);\n    if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('فشل تحديث صلاحيات الحساب: HTTP ${response.statusCode}');")
replace_once('lib/services/user_account_service.dart', r"await http\.delete\(uri\)\.timeout\(_timeout\);", "final response = await http.delete(uri).timeout(_timeout);\n    if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('فشل حذف الحساب: HTTP ${response.statusCode}');")
replace_once('lib/providers/auth_provider.dart', r"if \(match != null\) \{\n        await _persistSession\(username: match\.username, isAdmin: false, permissions: match\.permissions\);\n      \}", "if (match != null) {\n        await _persistSession(username: match.username, isAdmin: false, permissions: match.permissions);\n      } else {\n        await logout();\n      }")

customers = Path('lib/screens/customers_screen.dart')
text = customers.read_text(encoding='utf-8')
if "../providers/auth_provider.dart" not in text:
    text = text.replace("import '../providers/data_providers.dart';", "import '../providers/data_providers.dart';\nimport '../providers/auth_provider.dart';")
marker = "    final customersAsync = ref.watch(customersProvider);"
if marker not in text: raise SystemExit('customers provider marker not found')
if "final session = ref.watch(sessionProvider).value;" not in text:
    text = text.replace(marker, marker + "\n    final session = ref.watch(sessionProvider).value;", 1)
old_button = "IconButton(tooltip: 'أرشفة', icon: const Icon(Icons.archive_outlined, color: AppColors.danger), onPressed: () => _archive(c)),"
if old_button in text:
    text = text.replace(old_button, "if (session?.isAdmin == true) " + old_button, 1)
if "final archivedOrder = o.isDeleted;" in text:
    text = text.replace("final archivedOrder = o.isDeleted;", "final archivedOrder = o.isArchived;", 1)
customers.write_text(text, encoding='utf-8')
print('Comprehensive source repair applied successfully.')
