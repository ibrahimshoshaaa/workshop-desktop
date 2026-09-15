from pathlib import Path


def edit(path, transform):
    p = Path(path)
    s = p.read_text(encoding='utf-8')
    n = transform(s)
    if n == s:
        raise RuntimeError(f'No change made to {path}')
    p.write_text(n, encoding='utf-8')


def database(s):
    customer = """  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الطلبات"""
    customer_new = """  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get archiveYear => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الطلبات"""
    if customer not in s: raise RuntimeError('customer columns marker missing')
    s = s.replace(customer, customer_new, 1)
    order = """  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الدفعات"""
    order_new = """  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get archiveYear => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الدفعات"""
    if order not in s: raise RuntimeError('order columns marker missing')
    s = s.replace(order, order_new, 1)
    s = s.replace('  int get schemaVersion => 10;', '  int get schemaVersion => 11;', 1)
    marker = """        if (from < 10) {
          // ربط مديونية الورشة بالطلب اللي ولّدها (نسخة 10) - لحالة العميل
          // اللي دفع أكتر من السعر النهائي بعد تعديله
          await m.addColumn(workshopDebts, workshopDebts.orderId);
        }"""
    migration = marker + """
        if (from < 11) {
          await m.addColumn(customers, customers.isArchived);
          await m.addColumn(customers, customers.archivedAt);
          await m.addColumn(customers, customers.archiveYear);
          await m.addColumn(orders, orders.isArchived);
          await m.addColumn(orders, orders.archivedAt);
          await m.addColumn(orders, orders.archiveYear);
        }"""
    if marker not in s: raise RuntimeError('migration marker missing')
    s = s.replace(marker, migration, 1)
    old = """  Stream<List<Customer>> watchCustomers() {
    return (select(customers)..where((t) => t.isDeleted.equals(false))).watch();
  }"""
    new = """  Stream<List<Customer>> watchCustomers() {
    return (select(customers)..where((t) => t.isDeleted.equals(false) & t.isArchived.equals(false))).watch();
  }

  Stream<List<Customer>> watchArchivedCustomers() {
    return (select(customers)..where((t) => t.isDeleted.equals(false) & t.isArchived.equals(true))).watch();
  }

  Future<Customer?> getCustomer(String id) async {
    return (select(customers)..where((t) => t.id.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();
  }"""
    if old not in s: raise RuntimeError('customer watch marker missing')
    s = s.replace(old, new, 1)
    old = """  Stream<List<Order>> watchOrders() {
    return (select(orders)..where((t) => t.isDeleted.equals(false))).watch();
  }"""
    new = """  Stream<List<Order>> watchOrders() {
    return (select(orders)..where((t) => t.isDeleted.equals(false) & t.isArchived.equals(false))).watch();
  }

  Stream<List<Order>> watchArchivedOrders({String? customerId, int? year}) {
    final q = select(orders)..where((t) => t.isDeleted.equals(false) & t.isArchived.equals(true));
    if (customerId != null) q.where((t) => t.customerId.equals(customerId));
    if (year != null) q.where((t) => t.archiveYear.equals(year));
    return q.watch();
  }"""
    if old not in s: raise RuntimeError('order watch marker missing')
    return s.replace(old, new, 1)


def repository(s):
    anchor = "  Future<void> deleteCustomer(String id) => _db.softDeleteCustomer(id);"
    methods = """  Future<void> deleteCustomer(String id) => _db.softDeleteCustomer(id);

  Future<String?> archiveCustomer(String customerId) async {
    final customer = await _db.getCustomer(customerId);
    if (customer == null) return 'العميل غير موجود';
    if (customer.isArchived) return null;
    final orders = await (_db.select(_db.orders)..where((t) => t.customerId.equals(customerId) & t.isDeleted.equals(false))).get();
    final blocked = orders.where((o) => o.remaining > 0.01 || o.status != 'تم التسليم').toList();
    if (blocked.isNotEmpty) return 'لا يمكن الأرشفة: يوجد طلب غير مُسلّم أو عليه مبلغ متبقي';
    final now = _now;
    final year = DateTime.fromMillisecondsSinceEpoch(now).year;
    await _db.transaction(() async {
      await _db.updateCustomerFields(CustomersCompanion(id: Value(customerId), isArchived: const Value(true), archivedAt: Value(now), archiveYear: Value(year), updatedAt: Value(now), dirty: const Value(true)));
      for (final order in orders) {
        await _db.updateOrderFields(OrdersCompanion(id: Value(order.id), isArchived: const Value(true), archivedAt: Value(now), archiveYear: Value(year), updatedAt: Value(now), dirty: const Value(true)));
      }
    });
    return null;
  }

  Future<String?> reactivateCustomer(String customerId) async {
    final customer = await _db.getCustomer(customerId);
    if (customer == null) return 'العميل غير موجود';
    if (!customer.isArchived) return null;
    await _db.updateCustomerFields(CustomersCompanion(id: Value(customer.id), isArchived: const Value(false), archivedAt: const Value(null), archiveYear: const Value(null), updatedAt: Value(_now), dirty: const Value(true)));
    return null;
  }"""
    if anchor not in s: raise RuntimeError('repository customer anchor missing')
    return s.replace(anchor, methods, 1)


def providers(s):
    marker = """final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(databaseProvider).watchCustomers();
});"""
    addition = marker + """

final archivedCustomersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(databaseProvider).watchArchivedCustomers();
});

final archivedOrdersProvider = StreamProvider.family<List<Order>, String>((ref, customerId) {
  return ref.watch(databaseProvider).watchArchivedOrders(customerId: customerId);
});"""
    if marker not in s: raise RuntimeError('provider marker missing')
    return s.replace(marker, addition, 1)


def sync(s):
    a = """            createdAt: Value((map['createdAt'] as num?)?.toInt() ?? remoteUpdatedAt),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),"""
    b = """            createdAt: Value((map['createdAt'] as num?)?.toInt() ?? remoteUpdatedAt),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            isArchived: Value(map['isArchived'] == true),
            archivedAt: Value((map['archivedAt'] as num?)?.toInt()),
            archiveYear: Value((map['archiveYear'] as num?)?.toInt()),
            dirty: const Value(false),"""
    if s.count(a) < 2: raise RuntimeError('sync remote markers missing')
    s = s.replace(a, b, 2)
    a = """          'createdAt': row.createdAt,
          'updatedAt': row.updatedAt,"""
    b = """          'createdAt': row.createdAt,
          'updatedAt': row.updatedAt,
          'isArchived': row.isArchived,
          'archivedAt': row.archivedAt,
          'archiveYear': row.archiveYear,"""
    if s.count(a) < 2: raise RuntimeError('sync write markers missing')
    return s.replace(a, b, 2)


def shell(s):
    s = s.replace("import 'customers_screen.dart';", "import 'customers_screen.dart';\nimport 'customer_archive_screen.dart';", 1)
    a = "    (Icons.people_alt_rounded, 'العملاء', 'customers'),\n    (Icons.checkroom_rounded, 'الطلبات', 'orders'),"
    b = "    (Icons.people_alt_rounded, 'العملاء', 'customers'),\n    (Icons.archive_rounded, 'أرشيف العملاء', 'admin_only'),\n    (Icons.checkroom_rounded, 'الطلبات', 'orders'),"
    if a not in s: raise RuntimeError('shell destinations marker missing')
    s = s.replace(a, b, 1)
    a = "    const CustomersScreen(),\n    const OrdersScreen(),"
    b = "    const CustomersScreen(),\n    const CustomerArchiveScreen(),\n    const OrdersScreen(),"
    if a not in s: raise RuntimeError('shell screens marker missing')
    return s.replace(a, b, 1)


def customers(s):
    s = s.replace("import '../providers/data_providers.dart';", "import '../providers/data_providers.dart';\nimport '../providers/auth_provider.dart';", 1)
    a = "    final customersAsync = ref.watch(customersProvider);\n\n    return Container("
    b = "    final customersAsync = ref.watch(customersProvider);\n    final archivedAsync = ref.watch(archivedCustomersProvider);\n    final isAdmin = ref.watch(sessionProvider).value?.isAdmin ?? false;\n\n    return Container("
    if a not in s: raise RuntimeError('customers async marker missing')
    s = s.replace(a, b, 1)
    a = """              data: (customers) {
                if (customers.isEmpty) {
                  return const _EmptyState(icon: Icons.people_outline_rounded, text: 'لا يوجد عملاء بعد');
                }
                final q = normalizeForSearch(_query);
                final filtered = q.isEmpty
                    ? customers
                    : customers.where((c) {"""
    b = """              data: (customers) {
                final archived = archivedAsync.value ?? [];
                final allForSearch = [...customers, ...archived];
                if (allForSearch.isEmpty) {
                  return const _EmptyState(icon: Icons.people_outline_rounded, text: 'لا يوجد عملاء بعد');
                }
                final q = normalizeForSearch(_query);
                final filtered = (q.isEmpty ? customers : allForSearch).where((c) {"""
    if a not in s: raise RuntimeError('customers filtering marker missing')
    s = s.replace(a, b, 1)
    a = """                        onTap: () => showDialog(context: context, builder: (context) => CustomerOrdersDialog(customer: c)),
                        onEdit: () => _showCustomerDialog(context, ref, customer: c),
                        onDelete: () async {"""
    b = """                        onTap: () => showDialog(context: context, builder: (context) => CustomerOrdersDialog(customer: c)),
                        onEdit: () => _showCustomerDialog(context, ref, customer: c),
                        onReactivate: c.isArchived ? () async {
                          if (!isAdmin) return;
                          final error = await ref.read(repositoryProvider).reactivateCustomer(c.id);
                          if (error != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                        } : null,
                        onArchive: (!c.isArchived && isAdmin) ? () async {
                          final error = await ref.read(repositoryProvider).archiveCustomer(c.id);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'تم أرشفة العميل وطلباته بنجاح')));
                        } : null,
                        onDelete: () async {"""
    if a not in s: raise RuntimeError('customer callbacks marker missing')
    s = s.replace(a, b, 1)
    a = "  final VoidCallback onDelete;\n  const _CustomerRow({required this.customer, required this.onTap, required this.onEdit, required this.onDelete});"
    b = "  final VoidCallback onDelete;\n  final VoidCallback? onReactivate;\n  final VoidCallback? onArchive;\n  const _CustomerRow({required this.customer, required this.onTap, required this.onEdit, required this.onDelete, this.onReactivate, this.onArchive});"
    if a not in s: raise RuntimeError('customer row constructor marker missing')
    s = s.replace(a, b, 1)
    a = "            IconButton(\n              tooltip: 'تعديل',"
    b = """            if (c.isArchived && onReactivate != null)
              IconButton(tooltip: 'إعادة تنشيط', icon: const Icon(Icons.unarchive_outlined, size: 20, color: AppColors.success), onPressed: onReactivate),
            if (!c.isArchived && onArchive != null)
              IconButton(tooltip: 'أرشفة', icon: const Icon(Icons.archive_outlined, size: 20, color: AppColors.wood), onPressed: onArchive),
            IconButton(
              tooltip: 'تعديل',"""
    if a not in s: raise RuntimeError('customer row buttons marker missing')
    return s.replace(a, b, 1)


archive_screen = r'''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/theme.dart';
import '../data/database.dart';
import '../providers/data_providers.dart';

class CustomerArchiveScreen extends ConsumerStatefulWidget {
  const CustomerArchiveScreen({super.key});
  @override ConsumerState<CustomerArchiveScreen> createState() => _CustomerArchiveScreenState();
}

class _CustomerArchiveScreenState extends ConsumerState<CustomerArchiveScreen> {
  final _search = TextEditingController();
  String _query = '';
  int? _year;
  @override void dispose() { _search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final async = ref.watch(archivedCustomersProvider);
    return Container(color: const Color(0xFFFAF6F0), child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(28,28,28,0), child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.wood.withValues(alpha:.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.archive_rounded,color:AppColors.wood)),
        const SizedBox(width:14), Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('أرشيف العملاء',style:GoogleFonts.cairo(fontSize:22,fontWeight:FontWeight.w800)),Text('تاريخ العملاء والطلبات المؤرشفة بدون حذف البيانات',style:GoogleFonts.cairo(fontSize:13,color:Colors.grey))]))
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(28,20,28,0), child: TextField(controller:_search,onChanged:(v)=>setState(()=>_query=v),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'ابحث بالاسم أو الهاتف أو الرقم التسلسلي...',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)))),
      Expanded(child: async.when(loading:()=>const Center(child:CircularProgressIndicator()),error:(e,_)=>Center(child:Text('خطأ: $e')),data:(customers){
        final years=customers.map((c)=>c.archiveYear).whereType<int>().toSet().toList()..sort((a,b)=>b.compareTo(a)); final q=_query.trim().toLowerCase();
        final filtered=customers.where((c)=> (q.isEmpty || '${c.name} ${c.phone} ${c.serialNumber}'.toLowerCase().contains(q)) && (_year==null || c.archiveYear==_year)).toList();
        return Column(children:[if(years.isNotEmpty) SizedBox(height:56,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:28,vertical:10),children:[ChoiceChip(label:const Text('كل السنوات'),selected:_year==null,onSelected:(_)=>setState(()=>_year=null)),const SizedBox(width:8),...years.map((y)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text('أرشيف $y'),selected:_year==y,onSelected:(_)=>setState(()=>_year=y))))])),Expanded(child:filtered.isEmpty?const Center(child:Text('لا توجد نتائج في الأرشيف')):ListView.builder(padding:const EdgeInsets.fromLTRB(28,8,28,24),itemCount:filtered.length,itemBuilder:(context,i)=>_ArchiveCard(customer:filtered[i]))) ]);
      }))
    ]));
  }
}

class _ArchiveCard extends ConsumerWidget {
  final Customer customer; const _ArchiveCard({required this.customer});
  @override Widget build(BuildContext context,WidgetRef ref){
    final async=ref.watch(archivedOrdersProvider(customer.id)); final orders=async.value??[]; final total=orders.fold<double>(0,(s,o)=>s+o.totalAmount);
    return Card(margin:const EdgeInsets.only(bottom:12),elevation:0,child:ExpansionTile(leading:CircleAvatar(backgroundColor:AppColors.wood.withValues(alpha:.1),child:Text(customer.name.isNotEmpty?customer.name[0]:'?',style:const TextStyle(color:AppColors.wood))),title:Row(children:[Expanded(child:Text(customer.name,style:GoogleFonts.cairo(fontWeight:FontWeight.w800))),Text('#${customer.serialNumber}',style:const TextStyle(color:AppColors.wood,fontWeight:FontWeight.bold))]),subtitle:Text('${customer.phone} • ${orders.length} طلب • إجمالي ${total.toStringAsFixed(0)}',style:GoogleFonts.cairo(fontSize:11.5)),children:[...orders.map((o)=>ListTile(title:Text(o.itemType,style:GoogleFonts.cairo(fontWeight:FontWeight.w700)),subtitle:Text('التسليم ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))} • ${o.status} • ${o.totalAmount.toStringAsFixed(0)}'),trailing:Text(o.remaining>.01?'متبقي ${o.remaining.toStringAsFixed(0)}':'مكتمل',style:TextStyle(color:o.remaining>.01?AppColors.danger:AppColors.success,fontWeight:FontWeight.bold))))]));
  }
}
'''

edit('lib/data/database.dart', database)
edit('lib/data/local_repository.dart', repository)
edit('lib/providers/data_providers.dart', providers)
edit('lib/services/sync_service.dart', sync)
edit('lib/screens/app_shell.dart', shell)
edit('lib/screens/customers_screen.dart', customers)
Path('lib/screens/customer_archive_screen.dart').write_text(archive_screen, encoding='utf-8')
