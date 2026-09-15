// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _serialNumberMeta =
      const VerificationMeta('serialNumber');
  @override
  late final GeneratedColumn<int> serialNumber = GeneratedColumn<int>(
      'serial_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone,
        address,
        serialNumber,
        createdAt,
        updatedAt,
        isDeleted,
        isArchived,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('serial_number')) {
      context.handle(
          _serialNumberMeta,
          serialNumber.isAcceptableOrUnknown(
              data['serial_number']!, _serialNumberMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      serialNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}serial_number'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final String id;
  final String name;
  final String phone;
  final String address;

  /// رقم تسلسلي فريد وثابت للعميل - بيتحدد مرة واحدة وقت الإضافة
  /// ومبيتغيرش بعد كده، ومش بيتكرر أبدًا حتى لو اتحذف عميل تاني قبله
  final int serialNumber;
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final bool isArchived;
  final bool dirty;
  const Customer(
      {required this.id,
      required this.name,
      required this.phone,
      required this.address,
      required this.serialNumber,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted,
      required this.isArchived,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['address'] = Variable<String>(address);
    map['serial_number'] = Variable<int>(serialNumber);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_archived'] = Variable<bool>(isArchived);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
      serialNumber: Value(serialNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      isArchived: Value(isArchived),
      dirty: Value(dirty),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      address: serializer.fromJson<String>(json['address']),
      serialNumber: serializer.fromJson<int>(json['serialNumber']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'address': serializer.toJson<String>(address),
      'serialNumber': serializer.toJson<int>(serialNumber),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isArchived': serializer.toJson<bool>(isArchived),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Customer copyWith(
          {String? id,
          String? name,
          String? phone,
          String? address,
          int? serialNumber,
          int? createdAt,
          int? updatedAt,
          bool? isDeleted,
          bool? isArchived,
          bool? dirty}) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        serialNumber: serialNumber ?? this.serialNumber,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        isArchived: isArchived ?? this.isArchived,
        dirty: dirty ?? this.dirty,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isArchived: $isArchived, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, address, serialNumber,
      createdAt, updatedAt, isDeleted, isArchived, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.serialNumber == this.serialNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isArchived == this.isArchived &&
          other.dirty == this.dirty);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> address;
  final Value<int> serialNumber;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isArchived;
  final Value<bool> dirty;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String name,
    required String phone,
    this.address = const Value.absent(),
    this.serialNumber = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        phone = Value(phone),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<int>? serialNumber,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isArchived,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isArchived != null) 'is_archived': isArchived,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? phone,
      Value<String>? address,
      Value<int>? serialNumber,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? isArchived,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      serialNumber: serialNumber ?? this.serialNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isArchived: isArchived ?? this.isArchived,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<int>(serialNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isArchived: $isArchived, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detailsMeta =
      const VerificationMeta('details');
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
      'details', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _imagesJsonMeta =
      const VerificationMeta('imagesJson');
  @override
  late final GeneratedColumn<String> imagesJson = GeneratedColumn<String>(
      'images_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalPaidMeta =
      const VerificationMeta('totalPaid');
  @override
  late final GeneratedColumn<double> totalPaid = GeneratedColumn<double>(
      'total_paid', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountAmountMeta =
      const VerificationMeta('discountAmount');
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
      'discount_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountReasonMeta =
      const VerificationMeta('discountReason');
  @override
  late final GeneratedColumn<String> discountReason = GeneratedColumn<String>(
      'discount_reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _deliveryDateMeta =
      const VerificationMeta('deliveryDate');
  @override
  late final GeneratedColumn<int> deliveryDate = GeneratedColumn<int>(
      'delivery_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        customerId,
        customerName,
        itemType,
        details,
        imagesJson,
        status,
        totalAmount,
        totalPaid,
        discountAmount,
        discountReason,
        deliveryDate,
        createdAt,
        updatedAt,
        isDeleted,
        isArchived,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(Insertable<Order> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('details')) {
      context.handle(_detailsMeta,
          details.isAcceptableOrUnknown(data['details']!, _detailsMeta));
    }
    if (data.containsKey('images_json')) {
      context.handle(
          _imagesJsonMeta,
          imagesJson.isAcceptableOrUnknown(
              data['images_json']!, _imagesJsonMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    }
    if (data.containsKey('total_paid')) {
      context.handle(_totalPaidMeta,
          totalPaid.isAcceptableOrUnknown(data['total_paid']!, _totalPaidMeta));
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
          _discountAmountMeta,
          discountAmount.isAcceptableOrUnknown(
              data['discount_amount']!, _discountAmountMeta));
    }
    if (data.containsKey('discount_reason')) {
      context.handle(
          _discountReasonMeta,
          discountReason.isAcceptableOrUnknown(
              data['discount_reason']!, _discountReasonMeta));
    }
    if (data.containsKey('delivery_date')) {
      context.handle(
          _deliveryDateMeta,
          deliveryDate.isAcceptableOrUnknown(
              data['delivery_date']!, _deliveryDateMeta));
    } else if (isInserting) {
      context.missing(_deliveryDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      details: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}details'])!,
      imagesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}images_json'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      totalPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_paid'])!,
      discountAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}discount_amount'])!,
      discountReason: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}discount_reason'])!,
      deliveryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}delivery_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final String customerId;
  final String customerName;
  final String itemType;
  final String details;

  /// روابط الصور متخزّنة كنص JSON (["url1", "url2"]) عشان درفت مالوش
  /// نوع عمود List مباشر
  final String imagesJson;
  final String status;
  final double totalAmount;
  final double totalPaid;

  /// خصم بمبلغ ثابت (مش نسبة) بيتشال من الإجمالي - مثلاً اتفقنا على
  /// 15000 والعميل دفع 14000 وعملنا خصم 1000، فالـ 1000 دي مش من
  /// حقنا أصلاً: مش بتتحسب مديونية عليه ولا إيراد للورشة
  final double discountAmount;
  final String discountReason;
  final int deliveryDate;
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final bool isArchived;
  final bool dirty;
  const Order(
      {required this.id,
      required this.customerId,
      required this.customerName,
      required this.itemType,
      required this.details,
      required this.imagesJson,
      required this.status,
      required this.totalAmount,
      required this.totalPaid,
      required this.discountAmount,
      required this.discountReason,
      required this.deliveryDate,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted,
      required this.isArchived,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['customer_name'] = Variable<String>(customerName);
    map['item_type'] = Variable<String>(itemType);
    map['details'] = Variable<String>(details);
    map['images_json'] = Variable<String>(imagesJson);
    map['status'] = Variable<String>(status);
    map['total_amount'] = Variable<double>(totalAmount);
    map['total_paid'] = Variable<double>(totalPaid);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['discount_reason'] = Variable<String>(discountReason);
    map['delivery_date'] = Variable<int>(deliveryDate);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_archived'] = Variable<bool>(isArchived);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      customerId: Value(customerId),
      customerName: Value(customerName),
      itemType: Value(itemType),
      details: Value(details),
      imagesJson: Value(imagesJson),
      status: Value(status),
      totalAmount: Value(totalAmount),
      totalPaid: Value(totalPaid),
      discountAmount: Value(discountAmount),
      discountReason: Value(discountReason),
      deliveryDate: Value(deliveryDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      isArchived: Value(isArchived),
      dirty: Value(dirty),
    );
  }

  factory Order.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      itemType: serializer.fromJson<String>(json['itemType']),
      details: serializer.fromJson<String>(json['details']),
      imagesJson: serializer.fromJson<String>(json['imagesJson']),
      status: serializer.fromJson<String>(json['status']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      totalPaid: serializer.fromJson<double>(json['totalPaid']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      discountReason: serializer.fromJson<String>(json['discountReason']),
      deliveryDate: serializer.fromJson<int>(json['deliveryDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'itemType': serializer.toJson<String>(itemType),
      'details': serializer.toJson<String>(details),
      'imagesJson': serializer.toJson<String>(imagesJson),
      'status': serializer.toJson<String>(status),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'totalPaid': serializer.toJson<double>(totalPaid),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'discountReason': serializer.toJson<String>(discountReason),
      'deliveryDate': serializer.toJson<int>(deliveryDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isArchived': serializer.toJson<bool>(isArchived),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Order copyWith(
          {String? id,
          String? customerId,
          String? customerName,
          String? itemType,
          String? details,
          String? imagesJson,
          String? status,
          double? totalAmount,
          double? totalPaid,
          double? discountAmount,
          String? discountReason,
          int? deliveryDate,
          int? createdAt,
          int? updatedAt,
          bool? isDeleted,
          bool? isArchived,
          bool? dirty}) =>
      Order(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        itemType: itemType ?? this.itemType,
        details: details ?? this.details,
        imagesJson: imagesJson ?? this.imagesJson,
        status: status ?? this.status,
        totalAmount: totalAmount ?? this.totalAmount,
        totalPaid: totalPaid ?? this.totalPaid,
        discountAmount: discountAmount ?? this.discountAmount,
        discountReason: discountReason ?? this.discountReason,
        deliveryDate: deliveryDate ?? this.deliveryDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        isArchived: isArchived ?? this.isArchived,
        dirty: dirty ?? this.dirty,
      );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      details: data.details.present ? data.details.value : this.details,
      imagesJson:
          data.imagesJson.present ? data.imagesJson.value : this.imagesJson,
      status: data.status.present ? data.status.value : this.status,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      totalPaid: data.totalPaid.present ? data.totalPaid.value : this.totalPaid,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      discountReason: data.discountReason.present
          ? data.discountReason.value
          : this.discountReason,
      deliveryDate: data.deliveryDate.present
          ? data.deliveryDate.value
          : this.deliveryDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('itemType: $itemType, ')
          ..write('details: $details, ')
          ..write('imagesJson: $imagesJson, ')
          ..write('status: $status, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('discountReason: $discountReason, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isArchived: $isArchived, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      customerId,
      customerName,
      itemType,
      details,
      imagesJson,
      status,
      totalAmount,
      totalPaid,
      discountAmount,
      discountReason,
      deliveryDate,
      createdAt,
      updatedAt,
      isDeleted,
      isArchived,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.itemType == this.itemType &&
          other.details == this.details &&
          other.imagesJson == this.imagesJson &&
          other.status == this.status &&
          other.totalAmount == this.totalAmount &&
          other.totalPaid == this.totalPaid &&
          other.discountAmount == this.discountAmount &&
          other.discountReason == this.discountReason &&
          other.deliveryDate == this.deliveryDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isArchived == this.isArchived &&
          other.dirty == this.dirty);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> customerName;
  final Value<String> itemType;
  final Value<String> details;
  final Value<String> imagesJson;
  final Value<String> status;
  final Value<double> totalAmount;
  final Value<double> totalPaid;
  final Value<double> discountAmount;
  final Value<String> discountReason;
  final Value<int> deliveryDate;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isArchived;
  final Value<bool> dirty;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.itemType = const Value.absent(),
    this.details = const Value.absent(),
    this.imagesJson = const Value.absent(),
    this.status = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.totalPaid = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.discountReason = const Value.absent(),
    this.deliveryDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String customerId,
    required String customerName,
    required String itemType,
    this.details = const Value.absent(),
    this.imagesJson = const Value.absent(),
    required String status,
    this.totalAmount = const Value.absent(),
    this.totalPaid = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.discountReason = const Value.absent(),
    required int deliveryDate,
    required int createdAt,
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        customerId = Value(customerId),
        customerName = Value(customerName),
        itemType = Value(itemType),
        status = Value(status),
        deliveryDate = Value(deliveryDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? itemType,
    Expression<String>? details,
    Expression<String>? imagesJson,
    Expression<String>? status,
    Expression<double>? totalAmount,
    Expression<double>? totalPaid,
    Expression<double>? discountAmount,
    Expression<String>? discountReason,
    Expression<int>? deliveryDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isArchived,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (itemType != null) 'item_type': itemType,
      if (details != null) 'details': details,
      if (imagesJson != null) 'images_json': imagesJson,
      if (status != null) 'status': status,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (totalPaid != null) 'total_paid': totalPaid,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (discountReason != null) 'discount_reason': discountReason,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isArchived != null) 'is_archived': isArchived,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith(
      {Value<String>? id,
      Value<String>? customerId,
      Value<String>? customerName,
      Value<String>? itemType,
      Value<String>? details,
      Value<String>? imagesJson,
      Value<String>? status,
      Value<double>? totalAmount,
      Value<double>? totalPaid,
      Value<double>? discountAmount,
      Value<String>? discountReason,
      Value<int>? deliveryDate,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? isArchived,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return OrdersCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      itemType: itemType ?? this.itemType,
      details: details ?? this.details,
      imagesJson: imagesJson ?? this.imagesJson,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      totalPaid: totalPaid ?? this.totalPaid,
      discountAmount: discountAmount ?? this.discountAmount,
      discountReason: discountReason ?? this.discountReason,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isArchived: isArchived ?? this.isArchived,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (imagesJson.present) {
      map['images_json'] = Variable<String>(imagesJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (totalPaid.present) {
      map['total_paid'] = Variable<double>(totalPaid.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (discountReason.present) {
      map['discount_reason'] = Variable<String>(discountReason.value);
    }
    if (deliveryDate.present) {
      map['delivery_date'] = Variable<int>(deliveryDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('itemType: $itemType, ')
          ..write('details: $details, ')
          ..write('imagesJson: $imagesJson, ')
          ..write('status: $status, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('discountReason: $discountReason, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isArchived: $isArchived, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentTransactionsTable extends PaymentTransactions
    with TableInfo<$PaymentTransactionsTable, PaymentTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountPaidMeta =
      const VerificationMeta('amountPaid');
  @override
  late final GeneratedColumn<double> amountPaid = GeneratedColumn<double>(
      'amount_paid', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paymentDateMeta =
      const VerificationMeta('paymentDate');
  @override
  late final GeneratedColumn<int> paymentDate = GeneratedColumn<int>(
      'payment_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _paymentTypeMeta =
      const VerificationMeta('paymentType');
  @override
  late final GeneratedColumn<String> paymentType = GeneratedColumn<String>(
      'payment_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('completed'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        customerId,
        amountPaid,
        paymentDate,
        paymentType,
        paymentMethod,
        status,
        updatedAt,
        isDeleted,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_transactions';
  @override
  VerificationContext validateIntegrity(Insertable<PaymentTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('amount_paid')) {
      context.handle(
          _amountPaidMeta,
          amountPaid.isAcceptableOrUnknown(
              data['amount_paid']!, _amountPaidMeta));
    } else if (isInserting) {
      context.missing(_amountPaidMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
          _paymentDateMeta,
          paymentDate.isAcceptableOrUnknown(
              data['payment_date']!, _paymentDateMeta));
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('payment_type')) {
      context.handle(
          _paymentTypeMeta,
          paymentType.isAcceptableOrUnknown(
              data['payment_type']!, _paymentTypeMeta));
    } else if (isInserting) {
      context.missing(_paymentTypeMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentTransaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      amountPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount_paid'])!,
      paymentDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payment_date'])!,
      paymentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_type'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $PaymentTransactionsTable createAlias(String alias) {
    return $PaymentTransactionsTable(attachedDatabase, alias);
  }
}

class PaymentTransaction extends DataClass
    implements Insertable<PaymentTransaction> {
  final String id;
  final String orderId;
  final String customerId;
  final double amountPaid;
  final int paymentDate;
  final String paymentType;

  /// طريقة استلام المبلغ: cash (نقدي) / instapay (إنستاباي) - أو أي قيمة
  /// حرة تانية لو المستخدم اختار "أخرى" وكتب طريقة مخصوصة
  final String paymentMethod;

  /// حالة الدفعة: pending (معلقة) / completed (مكتملة)
  final String status;
  final int updatedAt;
  final bool isDeleted;
  final bool dirty;
  const PaymentTransaction(
      {required this.id,
      required this.orderId,
      required this.customerId,
      required this.amountPaid,
      required this.paymentDate,
      required this.paymentType,
      required this.paymentMethod,
      required this.status,
      required this.updatedAt,
      required this.isDeleted,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['customer_id'] = Variable<String>(customerId);
    map['amount_paid'] = Variable<double>(amountPaid);
    map['payment_date'] = Variable<int>(paymentDate);
    map['payment_type'] = Variable<String>(paymentType);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['status'] = Variable<String>(status);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  PaymentTransactionsCompanion toCompanion(bool nullToAbsent) {
    return PaymentTransactionsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      customerId: Value(customerId),
      amountPaid: Value(amountPaid),
      paymentDate: Value(paymentDate),
      paymentType: Value(paymentType),
      paymentMethod: Value(paymentMethod),
      status: Value(status),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      dirty: Value(dirty),
    );
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentTransaction(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      amountPaid: serializer.fromJson<double>(json['amountPaid']),
      paymentDate: serializer.fromJson<int>(json['paymentDate']),
      paymentType: serializer.fromJson<String>(json['paymentType']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      status: serializer.fromJson<String>(json['status']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'customerId': serializer.toJson<String>(customerId),
      'amountPaid': serializer.toJson<double>(amountPaid),
      'paymentDate': serializer.toJson<int>(paymentDate),
      'paymentType': serializer.toJson<String>(paymentType),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'status': serializer.toJson<String>(status),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  PaymentTransaction copyWith(
          {String? id,
          String? orderId,
          String? customerId,
          double? amountPaid,
          int? paymentDate,
          String? paymentType,
          String? paymentMethod,
          String? status,
          int? updatedAt,
          bool? isDeleted,
          bool? dirty}) =>
      PaymentTransaction(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        customerId: customerId ?? this.customerId,
        amountPaid: amountPaid ?? this.amountPaid,
        paymentDate: paymentDate ?? this.paymentDate,
        paymentType: paymentType ?? this.paymentType,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        dirty: dirty ?? this.dirty,
      );
  PaymentTransaction copyWithCompanion(PaymentTransactionsCompanion data) {
    return PaymentTransaction(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      amountPaid:
          data.amountPaid.present ? data.amountPaid.value : this.amountPaid,
      paymentDate:
          data.paymentDate.present ? data.paymentDate.value : this.paymentDate,
      paymentType:
          data.paymentType.present ? data.paymentType.value : this.paymentType,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentTransaction(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('customerId: $customerId, ')
          ..write('amountPaid: $amountPaid, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentType: $paymentType, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      orderId,
      customerId,
      amountPaid,
      paymentDate,
      paymentType,
      paymentMethod,
      status,
      updatedAt,
      isDeleted,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentTransaction &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.customerId == this.customerId &&
          other.amountPaid == this.amountPaid &&
          other.paymentDate == this.paymentDate &&
          other.paymentType == this.paymentType &&
          other.paymentMethod == this.paymentMethod &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.dirty == this.dirty);
}

class PaymentTransactionsCompanion extends UpdateCompanion<PaymentTransaction> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> customerId;
  final Value<double> amountPaid;
  final Value<int> paymentDate;
  final Value<String> paymentType;
  final Value<String> paymentMethod;
  final Value<String> status;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> dirty;
  final Value<int> rowid;
  const PaymentTransactionsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.amountPaid = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.paymentType = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentTransactionsCompanion.insert({
    required String id,
    required String orderId,
    required String customerId,
    required double amountPaid,
    required int paymentDate,
    required String paymentType,
    this.paymentMethod = const Value.absent(),
    this.status = const Value.absent(),
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        customerId = Value(customerId),
        amountPaid = Value(amountPaid),
        paymentDate = Value(paymentDate),
        paymentType = Value(paymentType),
        updatedAt = Value(updatedAt);
  static Insertable<PaymentTransaction> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? customerId,
    Expression<double>? amountPaid,
    Expression<int>? paymentDate,
    Expression<String>? paymentType,
    Expression<String>? paymentMethod,
    Expression<String>? status,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (customerId != null) 'customer_id': customerId,
      if (amountPaid != null) 'amount_paid': amountPaid,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (paymentType != null) 'payment_type': paymentType,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentTransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<String>? customerId,
      Value<double>? amountPaid,
      Value<int>? paymentDate,
      Value<String>? paymentType,
      Value<String>? paymentMethod,
      Value<String>? status,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return PaymentTransactionsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (amountPaid.present) {
      map['amount_paid'] = Variable<double>(amountPaid.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<int>(paymentDate.value);
    }
    if (paymentType.present) {
      map['payment_type'] = Variable<String>(paymentType.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('customerId: $customerId, ')
          ..write('amountPaid: $amountPaid, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentType: $paymentType, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _workerNameMeta =
      const VerificationMeta('workerName');
  @override
  late final GeneratedColumn<String> workerName = GeneratedColumn<String>(
      'worker_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _workshopDebtIdMeta =
      const VerificationMeta('workshopDebtId');
  @override
  late final GeneratedColumn<String> workshopDebtId = GeneratedColumn<String>(
      'workshop_debt_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orderAllocationsJsonMeta =
      const VerificationMeta('orderAllocationsJson');
  @override
  late final GeneratedColumn<String> orderAllocationsJson =
      GeneratedColumn<String>('order_allocations_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        amount,
        category,
        description,
        workerName,
        orderId,
        customerId,
        customerName,
        paymentMethod,
        workshopDebtId,
        orderAllocationsJson,
        date,
        updatedAt,
        isDeleted,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('worker_name')) {
      context.handle(
          _workerNameMeta,
          workerName.isAcceptableOrUnknown(
              data['worker_name']!, _workerNameMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('workshop_debt_id')) {
      context.handle(
          _workshopDebtIdMeta,
          workshopDebtId.isAcceptableOrUnknown(
              data['workshop_debt_id']!, _workshopDebtIdMeta));
    }
    if (data.containsKey('order_allocations_json')) {
      context.handle(
          _orderAllocationsJsonMeta,
          orderAllocationsJson.isAcceptableOrUnknown(
              data['order_allocations_json']!, _orderAllocationsJsonMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      workerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}worker_name']),
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id']),
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      workshopDebtId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}workshop_debt_id']),
      orderAllocationsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}order_allocations_json'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final double amount;
  final String category;
  final String description;
  final String? workerName;

  /// لو المصروف ده مرتبط بطلب/عميل معيّن (زي مصروف بيتسجل من جوه تفاصيل
  /// الطلب) - بيفضلوا null للمصروفات العامة (إيجار، أجور... إلخ)
  final String? orderId;
  final String? customerId;
  final String? customerName;

  /// مصدر خروج المبلغ من الخزينة: cash (نقدي) / instapay (إنستاباي) -
  /// بيحدد أي "خزنة" اتخصم منها المصروف ده عشان تفنيط "المبلغ المتاح"
  final String paymentMethod;

  /// لو المصروف ده سداد لمديونية ورشة (مورد/صنايعي) - بيربطه بسجل
  /// المديونية في جدول WorkshopDebts، وبيفضل null لباقي المصروفات العادية
  final String? workshopDebtId;

  /// تقسيم المصروف على أكتر من طلب - متخزّن كنص JSON:
  /// [{"orderId":"..","customerId":"..","customerName":"..","amount":123}, ...]
  /// نفس فكرة imagesJson في جدول الطلبات؛ لو المصروف عام (مش مقسّم على
  /// طلبات) بتفضل '[]'. الحقول القديمة orderId/customerId/customerName
  /// فوق بتفضل متسجلة كمان لو طلب واحد بس اتاختار (توافقًا مع الكود القديم)
  final String orderAllocationsJson;
  final int date;
  final int updatedAt;
  final bool isDeleted;
  final bool dirty;
  const Expense(
      {required this.id,
      required this.amount,
      required this.category,
      required this.description,
      this.workerName,
      this.orderId,
      this.customerId,
      this.customerName,
      required this.paymentMethod,
      this.workshopDebtId,
      required this.orderAllocationsJson,
      required this.date,
      required this.updatedAt,
      required this.isDeleted,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || workerName != null) {
      map['worker_name'] = Variable<String>(workerName);
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<String>(orderId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || workshopDebtId != null) {
      map['workshop_debt_id'] = Variable<String>(workshopDebtId);
    }
    map['order_allocations_json'] = Variable<String>(orderAllocationsJson);
    map['date'] = Variable<int>(date);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      amount: Value(amount),
      category: Value(category),
      description: Value(description),
      workerName: workerName == null && nullToAbsent
          ? const Value.absent()
          : Value(workerName),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      paymentMethod: Value(paymentMethod),
      workshopDebtId: workshopDebtId == null && nullToAbsent
          ? const Value.absent()
          : Value(workshopDebtId),
      orderAllocationsJson: Value(orderAllocationsJson),
      date: Value(date),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      dirty: Value(dirty),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      workerName: serializer.fromJson<String?>(json['workerName']),
      orderId: serializer.fromJson<String?>(json['orderId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      workshopDebtId: serializer.fromJson<String?>(json['workshopDebtId']),
      orderAllocationsJson:
          serializer.fromJson<String>(json['orderAllocationsJson']),
      date: serializer.fromJson<int>(json['date']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
      'workerName': serializer.toJson<String?>(workerName),
      'orderId': serializer.toJson<String?>(orderId),
      'customerId': serializer.toJson<String?>(customerId),
      'customerName': serializer.toJson<String?>(customerName),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'workshopDebtId': serializer.toJson<String?>(workshopDebtId),
      'orderAllocationsJson': serializer.toJson<String>(orderAllocationsJson),
      'date': serializer.toJson<int>(date),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Expense copyWith(
          {String? id,
          double? amount,
          String? category,
          String? description,
          Value<String?> workerName = const Value.absent(),
          Value<String?> orderId = const Value.absent(),
          Value<String?> customerId = const Value.absent(),
          Value<String?> customerName = const Value.absent(),
          String? paymentMethod,
          Value<String?> workshopDebtId = const Value.absent(),
          String? orderAllocationsJson,
          int? date,
          int? updatedAt,
          bool? isDeleted,
          bool? dirty}) =>
      Expense(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        description: description ?? this.description,
        workerName: workerName.present ? workerName.value : this.workerName,
        orderId: orderId.present ? orderId.value : this.orderId,
        customerId: customerId.present ? customerId.value : this.customerId,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        workshopDebtId:
            workshopDebtId.present ? workshopDebtId.value : this.workshopDebtId,
        orderAllocationsJson: orderAllocationsJson ?? this.orderAllocationsJson,
        date: date ?? this.date,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        dirty: dirty ?? this.dirty,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      description:
          data.description.present ? data.description.value : this.description,
      workerName:
          data.workerName.present ? data.workerName.value : this.workerName,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      workshopDebtId: data.workshopDebtId.present
          ? data.workshopDebtId.value
          : this.workshopDebtId,
      orderAllocationsJson: data.orderAllocationsJson.present
          ? data.orderAllocationsJson.value
          : this.orderAllocationsJson,
      date: data.date.present ? data.date.value : this.date,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('workerName: $workerName, ')
          ..write('orderId: $orderId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('workshopDebtId: $workshopDebtId, ')
          ..write('orderAllocationsJson: $orderAllocationsJson, ')
          ..write('date: $date, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      amount,
      category,
      description,
      workerName,
      orderId,
      customerId,
      customerName,
      paymentMethod,
      workshopDebtId,
      orderAllocationsJson,
      date,
      updatedAt,
      isDeleted,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.description == this.description &&
          other.workerName == this.workerName &&
          other.orderId == this.orderId &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.paymentMethod == this.paymentMethod &&
          other.workshopDebtId == this.workshopDebtId &&
          other.orderAllocationsJson == this.orderAllocationsJson &&
          other.date == this.date &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.dirty == this.dirty);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<double> amount;
  final Value<String> category;
  final Value<String> description;
  final Value<String?> workerName;
  final Value<String?> orderId;
  final Value<String?> customerId;
  final Value<String?> customerName;
  final Value<String> paymentMethod;
  final Value<String?> workshopDebtId;
  final Value<String> orderAllocationsJson;
  final Value<int> date;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.workerName = const Value.absent(),
    this.orderId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.workshopDebtId = const Value.absent(),
    this.orderAllocationsJson = const Value.absent(),
    this.date = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required double amount,
    required String category,
    this.description = const Value.absent(),
    this.workerName = const Value.absent(),
    this.orderId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.workshopDebtId = const Value.absent(),
    this.orderAllocationsJson = const Value.absent(),
    required int date,
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        amount = Value(amount),
        category = Value(category),
        date = Value(date),
        updatedAt = Value(updatedAt);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? workerName,
    Expression<String>? orderId,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? paymentMethod,
    Expression<String>? workshopDebtId,
    Expression<String>? orderAllocationsJson,
    Expression<int>? date,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (workerName != null) 'worker_name': workerName,
      if (orderId != null) 'order_id': orderId,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (workshopDebtId != null) 'workshop_debt_id': workshopDebtId,
      if (orderAllocationsJson != null)
        'order_allocations_json': orderAllocationsJson,
      if (date != null) 'date': date,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith(
      {Value<String>? id,
      Value<double>? amount,
      Value<String>? category,
      Value<String>? description,
      Value<String?>? workerName,
      Value<String?>? orderId,
      Value<String?>? customerId,
      Value<String?>? customerName,
      Value<String>? paymentMethod,
      Value<String?>? workshopDebtId,
      Value<String>? orderAllocationsJson,
      Value<int>? date,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      workerName: workerName ?? this.workerName,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      workshopDebtId: workshopDebtId ?? this.workshopDebtId,
      orderAllocationsJson: orderAllocationsJson ?? this.orderAllocationsJson,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (workerName.present) {
      map['worker_name'] = Variable<String>(workerName.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (workshopDebtId.present) {
      map['workshop_debt_id'] = Variable<String>(workshopDebtId.value);
    }
    if (orderAllocationsJson.present) {
      map['order_allocations_json'] =
          Variable<String>(orderAllocationsJson.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('workerName: $workerName, ')
          ..write('orderId: $orderId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('workshopDebtId: $workshopDebtId, ')
          ..write('orderAllocationsJson: $orderAllocationsJson, ')
          ..write('date: $date, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialItemsTable extends MaterialItems
    with TableInfo<$MaterialItemsTable, MaterialItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minThresholdMeta =
      const VerificationMeta('minThreshold');
  @override
  late final GeneratedColumn<double> minThreshold = GeneratedColumn<double>(
      'min_threshold', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, unit, quantity, minThreshold, updatedAt, isDeleted, dirty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'material_items';
  @override
  VerificationContext validateIntegrity(Insertable<MaterialItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('min_threshold')) {
      context.handle(
          _minThresholdMeta,
          minThreshold.isAcceptableOrUnknown(
              data['min_threshold']!, _minThresholdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaterialItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      minThreshold: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_threshold'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $MaterialItemsTable createAlias(String alias) {
    return $MaterialItemsTable(attachedDatabase, alias);
  }
}

class MaterialItem extends DataClass implements Insertable<MaterialItem> {
  final String id;
  final String name;
  final String unit;
  final double quantity;
  final double minThreshold;
  final int updatedAt;
  final bool isDeleted;
  final bool dirty;
  const MaterialItem(
      {required this.id,
      required this.name,
      required this.unit,
      required this.quantity,
      required this.minThreshold,
      required this.updatedAt,
      required this.isDeleted,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['quantity'] = Variable<double>(quantity);
    map['min_threshold'] = Variable<double>(minThreshold);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  MaterialItemsCompanion toCompanion(bool nullToAbsent) {
    return MaterialItemsCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unit),
      quantity: Value(quantity),
      minThreshold: Value(minThreshold),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      dirty: Value(dirty),
    );
  }

  factory MaterialItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialItem(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      quantity: serializer.fromJson<double>(json['quantity']),
      minThreshold: serializer.fromJson<double>(json['minThreshold']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'quantity': serializer.toJson<double>(quantity),
      'minThreshold': serializer.toJson<double>(minThreshold),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  MaterialItem copyWith(
          {String? id,
          String? name,
          String? unit,
          double? quantity,
          double? minThreshold,
          int? updatedAt,
          bool? isDeleted,
          bool? dirty}) =>
      MaterialItem(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        quantity: quantity ?? this.quantity,
        minThreshold: minThreshold ?? this.minThreshold,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        dirty: dirty ?? this.dirty,
      );
  MaterialItem copyWithCompanion(MaterialItemsCompanion data) {
    return MaterialItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      minThreshold: data.minThreshold.present
          ? data.minThreshold.value
          : this.minThreshold,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('minThreshold: $minThreshold, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, unit, quantity, minThreshold, updatedAt, isDeleted, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.quantity == this.quantity &&
          other.minThreshold == this.minThreshold &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.dirty == this.dirty);
}

class MaterialItemsCompanion extends UpdateCompanion<MaterialItem> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<double> quantity;
  final Value<double> minThreshold;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> dirty;
  final Value<int> rowid;
  const MaterialItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    this.minThreshold = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialItemsCompanion.insert({
    required String id,
    required String name,
    required String unit,
    this.quantity = const Value.absent(),
    this.minThreshold = const Value.absent(),
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        unit = Value(unit),
        updatedAt = Value(updatedAt);
  static Insertable<MaterialItem> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<double>? quantity,
    Expression<double>? minThreshold,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (quantity != null) 'quantity': quantity,
      if (minThreshold != null) 'min_threshold': minThreshold,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? unit,
      Value<double>? quantity,
      Value<double>? minThreshold,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return MaterialItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (minThreshold.present) {
      map['min_threshold'] = Variable<double>(minThreshold.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('minThreshold: $minThreshold, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkersTable extends Workers with TableInfo<$WorkersTable, Worker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobTitleMeta =
      const VerificationMeta('jobTitle');
  @override
  late final GeneratedColumn<String> jobTitle = GeneratedColumn<String>(
      'job_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _salaryTypeMeta =
      const VerificationMeta('salaryType');
  @override
  late final GeneratedColumn<String> salaryType = GeneratedColumn<String>(
      'salary_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _salaryAmountMeta =
      const VerificationMeta('salaryAmount');
  @override
  late final GeneratedColumn<double> salaryAmount = GeneratedColumn<double>(
      'salary_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _payWeekdayMeta =
      const VerificationMeta('payWeekday');
  @override
  late final GeneratedColumn<int> payWeekday = GeneratedColumn<int>(
      'pay_weekday', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        jobTitle,
        salaryType,
        salaryAmount,
        payWeekday,
        phone,
        notes,
        createdAt,
        updatedAt,
        isDeleted,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workers';
  @override
  VerificationContext validateIntegrity(Insertable<Worker> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('job_title')) {
      context.handle(_jobTitleMeta,
          jobTitle.isAcceptableOrUnknown(data['job_title']!, _jobTitleMeta));
    } else if (isInserting) {
      context.missing(_jobTitleMeta);
    }
    if (data.containsKey('salary_type')) {
      context.handle(
          _salaryTypeMeta,
          salaryType.isAcceptableOrUnknown(
              data['salary_type']!, _salaryTypeMeta));
    } else if (isInserting) {
      context.missing(_salaryTypeMeta);
    }
    if (data.containsKey('salary_amount')) {
      context.handle(
          _salaryAmountMeta,
          salaryAmount.isAcceptableOrUnknown(
              data['salary_amount']!, _salaryAmountMeta));
    }
    if (data.containsKey('pay_weekday')) {
      context.handle(
          _payWeekdayMeta,
          payWeekday.isAcceptableOrUnknown(
              data['pay_weekday']!, _payWeekdayMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Worker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Worker(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      jobTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_title'])!,
      salaryType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}salary_type'])!,
      salaryAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}salary_amount'])!,
      payWeekday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pay_weekday'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $WorkersTable createAlias(String alias) {
    return $WorkersTable(attachedDatabase, alias);
  }
}

class Worker extends DataClass implements Insertable<Worker> {
  final String id;
  final String name;
  final String jobTitle;

  /// نوع المرتب: monthly / weekly / daily
  final String salaryType;
  final double salaryAmount;

  /// يوم القبض الأسبوعي (1=الاثنين ... 7=الأحد، زي DateTime.weekday) -
  /// مستخدم بس لو salaryType == weekly، افتراضيًا الخميس (4)
  final int payWeekday;
  final String phone;
  final String notes;
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final bool dirty;
  const Worker(
      {required this.id,
      required this.name,
      required this.jobTitle,
      required this.salaryType,
      required this.salaryAmount,
      required this.payWeekday,
      required this.phone,
      required this.notes,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['job_title'] = Variable<String>(jobTitle);
    map['salary_type'] = Variable<String>(salaryType);
    map['salary_amount'] = Variable<double>(salaryAmount);
    map['pay_weekday'] = Variable<int>(payWeekday);
    map['phone'] = Variable<String>(phone);
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  WorkersCompanion toCompanion(bool nullToAbsent) {
    return WorkersCompanion(
      id: Value(id),
      name: Value(name),
      jobTitle: Value(jobTitle),
      salaryType: Value(salaryType),
      salaryAmount: Value(salaryAmount),
      payWeekday: Value(payWeekday),
      phone: Value(phone),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      dirty: Value(dirty),
    );
  }

  factory Worker.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Worker(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      jobTitle: serializer.fromJson<String>(json['jobTitle']),
      salaryType: serializer.fromJson<String>(json['salaryType']),
      salaryAmount: serializer.fromJson<double>(json['salaryAmount']),
      payWeekday: serializer.fromJson<int>(json['payWeekday']),
      phone: serializer.fromJson<String>(json['phone']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'jobTitle': serializer.toJson<String>(jobTitle),
      'salaryType': serializer.toJson<String>(salaryType),
      'salaryAmount': serializer.toJson<double>(salaryAmount),
      'payWeekday': serializer.toJson<int>(payWeekday),
      'phone': serializer.toJson<String>(phone),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Worker copyWith(
          {String? id,
          String? name,
          String? jobTitle,
          String? salaryType,
          double? salaryAmount,
          int? payWeekday,
          String? phone,
          String? notes,
          int? createdAt,
          int? updatedAt,
          bool? isDeleted,
          bool? dirty}) =>
      Worker(
        id: id ?? this.id,
        name: name ?? this.name,
        jobTitle: jobTitle ?? this.jobTitle,
        salaryType: salaryType ?? this.salaryType,
        salaryAmount: salaryAmount ?? this.salaryAmount,
        payWeekday: payWeekday ?? this.payWeekday,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        dirty: dirty ?? this.dirty,
      );
  Worker copyWithCompanion(WorkersCompanion data) {
    return Worker(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      jobTitle: data.jobTitle.present ? data.jobTitle.value : this.jobTitle,
      salaryType:
          data.salaryType.present ? data.salaryType.value : this.salaryType,
      salaryAmount: data.salaryAmount.present
          ? data.salaryAmount.value
          : this.salaryAmount,
      payWeekday:
          data.payWeekday.present ? data.payWeekday.value : this.payWeekday,
      phone: data.phone.present ? data.phone.value : this.phone,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Worker(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('salaryType: $salaryType, ')
          ..write('salaryAmount: $salaryAmount, ')
          ..write('payWeekday: $payWeekday, ')
          ..write('phone: $phone, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, jobTitle, salaryType, salaryAmount,
      payWeekday, phone, notes, createdAt, updatedAt, isDeleted, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Worker &&
          other.id == this.id &&
          other.name == this.name &&
          other.jobTitle == this.jobTitle &&
          other.salaryType == this.salaryType &&
          other.salaryAmount == this.salaryAmount &&
          other.payWeekday == this.payWeekday &&
          other.phone == this.phone &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.dirty == this.dirty);
}

class WorkersCompanion extends UpdateCompanion<Worker> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> jobTitle;
  final Value<String> salaryType;
  final Value<double> salaryAmount;
  final Value<int> payWeekday;
  final Value<String> phone;
  final Value<String> notes;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> dirty;
  final Value<int> rowid;
  const WorkersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.salaryType = const Value.absent(),
    this.salaryAmount = const Value.absent(),
    this.payWeekday = const Value.absent(),
    this.phone = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkersCompanion.insert({
    required String id,
    required String name,
    required String jobTitle,
    required String salaryType,
    this.salaryAmount = const Value.absent(),
    this.payWeekday = const Value.absent(),
    this.phone = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        jobTitle = Value(jobTitle),
        salaryType = Value(salaryType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Worker> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? jobTitle,
    Expression<String>? salaryType,
    Expression<double>? salaryAmount,
    Expression<int>? payWeekday,
    Expression<String>? phone,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (jobTitle != null) 'job_title': jobTitle,
      if (salaryType != null) 'salary_type': salaryType,
      if (salaryAmount != null) 'salary_amount': salaryAmount,
      if (payWeekday != null) 'pay_weekday': payWeekday,
      if (phone != null) 'phone': phone,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? jobTitle,
      Value<String>? salaryType,
      Value<double>? salaryAmount,
      Value<int>? payWeekday,
      Value<String>? phone,
      Value<String>? notes,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return WorkersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      jobTitle: jobTitle ?? this.jobTitle,
      salaryType: salaryType ?? this.salaryType,
      salaryAmount: salaryAmount ?? this.salaryAmount,
      payWeekday: payWeekday ?? this.payWeekday,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (jobTitle.present) {
      map['job_title'] = Variable<String>(jobTitle.value);
    }
    if (salaryType.present) {
      map['salary_type'] = Variable<String>(salaryType.value);
    }
    if (salaryAmount.present) {
      map['salary_amount'] = Variable<double>(salaryAmount.value);
    }
    if (payWeekday.present) {
      map['pay_weekday'] = Variable<int>(payWeekday.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('salaryType: $salaryType, ')
          ..write('salaryAmount: $salaryAmount, ')
          ..write('payWeekday: $payWeekday, ')
          ..write('phone: $phone, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkerPaymentsTable extends WorkerPayments
    with TableInfo<$WorkerPaymentsTable, WorkerPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkerPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workerIdMeta =
      const VerificationMeta('workerId');
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
      'worker_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workerNameMeta =
      const VerificationMeta('workerName');
  @override
  late final GeneratedColumn<String> workerName = GeneratedColumn<String>(
      'worker_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paymentDateMeta =
      const VerificationMeta('paymentDate');
  @override
  late final GeneratedColumn<int> paymentDate = GeneratedColumn<int>(
      'payment_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _periodStartMeta =
      const VerificationMeta('periodStart');
  @override
  late final GeneratedColumn<int> periodStart = GeneratedColumn<int>(
      'period_start', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expenseIdMeta =
      const VerificationMeta('expenseId');
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
      'expense_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workerId,
        workerName,
        amount,
        paymentDate,
        periodStart,
        expenseId,
        updatedAt,
        isDeleted,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'worker_payments';
  @override
  VerificationContext validateIntegrity(Insertable<WorkerPayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('worker_id')) {
      context.handle(_workerIdMeta,
          workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta));
    } else if (isInserting) {
      context.missing(_workerIdMeta);
    }
    if (data.containsKey('worker_name')) {
      context.handle(
          _workerNameMeta,
          workerName.isAcceptableOrUnknown(
              data['worker_name']!, _workerNameMeta));
    } else if (isInserting) {
      context.missing(_workerNameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
          _paymentDateMeta,
          paymentDate.isAcceptableOrUnknown(
              data['payment_date']!, _paymentDateMeta));
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
          _periodStartMeta,
          periodStart.isAcceptableOrUnknown(
              data['period_start']!, _periodStartMeta));
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(_expenseIdMeta,
          expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkerPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkerPayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}worker_id'])!,
      workerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}worker_name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      paymentDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payment_date'])!,
      periodStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_start'])!,
      expenseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expense_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $WorkerPaymentsTable createAlias(String alias) {
    return $WorkerPaymentsTable(attachedDatabase, alias);
  }
}

class WorkerPayment extends DataClass implements Insertable<WorkerPayment> {
  final String id;
  final String workerId;
  final String workerName;
  final double amount;
  final int paymentDate;

  /// بداية دورة الاستحقاق (منتصف الليل) - بنستخدمها نتأكد إن العامل
  /// اتقبض مرة واحدة بس في نفس الدورة (الأسبوع/اليوم/الشهر)
  final int periodStart;
  final String? expenseId;
  final int updatedAt;
  final bool isDeleted;
  final bool dirty;
  const WorkerPayment(
      {required this.id,
      required this.workerId,
      required this.workerName,
      required this.amount,
      required this.paymentDate,
      required this.periodStart,
      this.expenseId,
      required this.updatedAt,
      required this.isDeleted,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['worker_id'] = Variable<String>(workerId);
    map['worker_name'] = Variable<String>(workerName);
    map['amount'] = Variable<double>(amount);
    map['payment_date'] = Variable<int>(paymentDate);
    map['period_start'] = Variable<int>(periodStart);
    if (!nullToAbsent || expenseId != null) {
      map['expense_id'] = Variable<String>(expenseId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  WorkerPaymentsCompanion toCompanion(bool nullToAbsent) {
    return WorkerPaymentsCompanion(
      id: Value(id),
      workerId: Value(workerId),
      workerName: Value(workerName),
      amount: Value(amount),
      paymentDate: Value(paymentDate),
      periodStart: Value(periodStart),
      expenseId: expenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(expenseId),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      dirty: Value(dirty),
    );
  }

  factory WorkerPayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkerPayment(
      id: serializer.fromJson<String>(json['id']),
      workerId: serializer.fromJson<String>(json['workerId']),
      workerName: serializer.fromJson<String>(json['workerName']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentDate: serializer.fromJson<int>(json['paymentDate']),
      periodStart: serializer.fromJson<int>(json['periodStart']),
      expenseId: serializer.fromJson<String?>(json['expenseId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workerId': serializer.toJson<String>(workerId),
      'workerName': serializer.toJson<String>(workerName),
      'amount': serializer.toJson<double>(amount),
      'paymentDate': serializer.toJson<int>(paymentDate),
      'periodStart': serializer.toJson<int>(periodStart),
      'expenseId': serializer.toJson<String?>(expenseId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  WorkerPayment copyWith(
          {String? id,
          String? workerId,
          String? workerName,
          double? amount,
          int? paymentDate,
          int? periodStart,
          Value<String?> expenseId = const Value.absent(),
          int? updatedAt,
          bool? isDeleted,
          bool? dirty}) =>
      WorkerPayment(
        id: id ?? this.id,
        workerId: workerId ?? this.workerId,
        workerName: workerName ?? this.workerName,
        amount: amount ?? this.amount,
        paymentDate: paymentDate ?? this.paymentDate,
        periodStart: periodStart ?? this.periodStart,
        expenseId: expenseId.present ? expenseId.value : this.expenseId,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        dirty: dirty ?? this.dirty,
      );
  WorkerPayment copyWithCompanion(WorkerPaymentsCompanion data) {
    return WorkerPayment(
      id: data.id.present ? data.id.value : this.id,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      workerName:
          data.workerName.present ? data.workerName.value : this.workerName,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentDate:
          data.paymentDate.present ? data.paymentDate.value : this.paymentDate,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkerPayment(')
          ..write('id: $id, ')
          ..write('workerId: $workerId, ')
          ..write('workerName: $workerName, ')
          ..write('amount: $amount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('periodStart: $periodStart, ')
          ..write('expenseId: $expenseId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workerId, workerName, amount, paymentDate,
      periodStart, expenseId, updatedAt, isDeleted, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkerPayment &&
          other.id == this.id &&
          other.workerId == this.workerId &&
          other.workerName == this.workerName &&
          other.amount == this.amount &&
          other.paymentDate == this.paymentDate &&
          other.periodStart == this.periodStart &&
          other.expenseId == this.expenseId &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.dirty == this.dirty);
}

class WorkerPaymentsCompanion extends UpdateCompanion<WorkerPayment> {
  final Value<String> id;
  final Value<String> workerId;
  final Value<String> workerName;
  final Value<double> amount;
  final Value<int> paymentDate;
  final Value<int> periodStart;
  final Value<String?> expenseId;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> dirty;
  final Value<int> rowid;
  const WorkerPaymentsCompanion({
    this.id = const Value.absent(),
    this.workerId = const Value.absent(),
    this.workerName = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkerPaymentsCompanion.insert({
    required String id,
    required String workerId,
    required String workerName,
    required double amount,
    required int paymentDate,
    required int periodStart,
    this.expenseId = const Value.absent(),
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workerId = Value(workerId),
        workerName = Value(workerName),
        amount = Value(amount),
        paymentDate = Value(paymentDate),
        periodStart = Value(periodStart),
        updatedAt = Value(updatedAt);
  static Insertable<WorkerPayment> custom({
    Expression<String>? id,
    Expression<String>? workerId,
    Expression<String>? workerName,
    Expression<double>? amount,
    Expression<int>? paymentDate,
    Expression<int>? periodStart,
    Expression<String>? expenseId,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workerId != null) 'worker_id': workerId,
      if (workerName != null) 'worker_name': workerName,
      if (amount != null) 'amount': amount,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (periodStart != null) 'period_start': periodStart,
      if (expenseId != null) 'expense_id': expenseId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkerPaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workerId,
      Value<String>? workerName,
      Value<double>? amount,
      Value<int>? paymentDate,
      Value<int>? periodStart,
      Value<String?>? expenseId,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return WorkerPaymentsCompanion(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      periodStart: periodStart ?? this.periodStart,
      expenseId: expenseId ?? this.expenseId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (workerName.present) {
      map['worker_name'] = Variable<String>(workerName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<int>(paymentDate.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<int>(periodStart.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkerPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('workerId: $workerId, ')
          ..write('workerName: $workerName, ')
          ..write('amount: $amount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('periodStart: $periodStart, ')
          ..write('expenseId: $expenseId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkshopDebtsTable extends WorkshopDebts
    with TableInfo<$WorkshopDebtsTable, WorkshopDebt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkshopDebtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _creditorNameMeta =
      const VerificationMeta('creditorName');
  @override
  late final GeneratedColumn<String> creditorName = GeneratedColumn<String>(
      'creditor_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _paidAmountMeta =
      const VerificationMeta('paidAmount');
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
      'paid_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        creditorName,
        totalAmount,
        paidAmount,
        notes,
        orderId,
        createdAt,
        updatedAt,
        isDeleted,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workshop_debts';
  @override
  VerificationContext validateIntegrity(Insertable<WorkshopDebt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('creditor_name')) {
      context.handle(
          _creditorNameMeta,
          creditorName.isAcceptableOrUnknown(
              data['creditor_name']!, _creditorNameMeta));
    } else if (isInserting) {
      context.missing(_creditorNameMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
          _paidAmountMeta,
          paidAmount.isAcceptableOrUnknown(
              data['paid_amount']!, _paidAmountMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkshopDebt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkshopDebt(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      creditorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}creditor_name'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      paidAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}paid_amount'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $WorkshopDebtsTable createAlias(String alias) {
    return $WorkshopDebtsTable(attachedDatabase, alias);
  }
}

class WorkshopDebt extends DataClass implements Insertable<WorkshopDebt> {
  final String id;

  /// اسم المورد/الصنايعي المستحق له المديونية (أو اسم العميل لو المديونية
  /// دي ناتجة عن دفعه أكتر من الاتفاق النهائي على طلب - راجع orderId)
  final String creditorName;
  final double totalAmount;

  /// إجمالي اللي اتسدد لحد دلوقتي من المديونية دي
  final double paidAmount;
  final String notes;

  /// لو المديونية دي اتولّدت تلقائيًا من طلب معيّن (العميل دفع أكتر من
  /// السعر النهائي بعد تعديله) - بيربطها بالطلب عشان تتحدّث/تتشال
  /// تلقائيًا لو السعر اتعدّل تاني. فاضي للمديونيات العادية (موردين/صنايعية)
  final String orderId;
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final bool dirty;
  const WorkshopDebt(
      {required this.id,
      required this.creditorName,
      required this.totalAmount,
      required this.paidAmount,
      required this.notes,
      required this.orderId,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['creditor_name'] = Variable<String>(creditorName);
    map['total_amount'] = Variable<double>(totalAmount);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['notes'] = Variable<String>(notes);
    map['order_id'] = Variable<String>(orderId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  WorkshopDebtsCompanion toCompanion(bool nullToAbsent) {
    return WorkshopDebtsCompanion(
      id: Value(id),
      creditorName: Value(creditorName),
      totalAmount: Value(totalAmount),
      paidAmount: Value(paidAmount),
      notes: Value(notes),
      orderId: Value(orderId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      dirty: Value(dirty),
    );
  }

  factory WorkshopDebt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkshopDebt(
      id: serializer.fromJson<String>(json['id']),
      creditorName: serializer.fromJson<String>(json['creditorName']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      notes: serializer.fromJson<String>(json['notes']),
      orderId: serializer.fromJson<String>(json['orderId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'creditorName': serializer.toJson<String>(creditorName),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'notes': serializer.toJson<String>(notes),
      'orderId': serializer.toJson<String>(orderId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  WorkshopDebt copyWith(
          {String? id,
          String? creditorName,
          double? totalAmount,
          double? paidAmount,
          String? notes,
          String? orderId,
          int? createdAt,
          int? updatedAt,
          bool? isDeleted,
          bool? dirty}) =>
      WorkshopDebt(
        id: id ?? this.id,
        creditorName: creditorName ?? this.creditorName,
        totalAmount: totalAmount ?? this.totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        notes: notes ?? this.notes,
        orderId: orderId ?? this.orderId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        dirty: dirty ?? this.dirty,
      );
  WorkshopDebt copyWithCompanion(WorkshopDebtsCompanion data) {
    return WorkshopDebt(
      id: data.id.present ? data.id.value : this.id,
      creditorName: data.creditorName.present
          ? data.creditorName.value
          : this.creditorName,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      paidAmount:
          data.paidAmount.present ? data.paidAmount.value : this.paidAmount,
      notes: data.notes.present ? data.notes.value : this.notes,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkshopDebt(')
          ..write('id: $id, ')
          ..write('creditorName: $creditorName, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('notes: $notes, ')
          ..write('orderId: $orderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, creditorName, totalAmount, paidAmount,
      notes, orderId, createdAt, updatedAt, isDeleted, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkshopDebt &&
          other.id == this.id &&
          other.creditorName == this.creditorName &&
          other.totalAmount == this.totalAmount &&
          other.paidAmount == this.paidAmount &&
          other.notes == this.notes &&
          other.orderId == this.orderId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.dirty == this.dirty);
}

class WorkshopDebtsCompanion extends UpdateCompanion<WorkshopDebt> {
  final Value<String> id;
  final Value<String> creditorName;
  final Value<double> totalAmount;
  final Value<double> paidAmount;
  final Value<String> notes;
  final Value<String> orderId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> dirty;
  final Value<int> rowid;
  const WorkshopDebtsCompanion({
    this.id = const Value.absent(),
    this.creditorName = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.notes = const Value.absent(),
    this.orderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkshopDebtsCompanion.insert({
    required String id,
    required String creditorName,
    this.totalAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.notes = const Value.absent(),
    this.orderId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        creditorName = Value(creditorName),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<WorkshopDebt> custom({
    Expression<String>? id,
    Expression<String>? creditorName,
    Expression<double>? totalAmount,
    Expression<double>? paidAmount,
    Expression<String>? notes,
    Expression<String>? orderId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (creditorName != null) 'creditor_name': creditorName,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (notes != null) 'notes': notes,
      if (orderId != null) 'order_id': orderId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkshopDebtsCompanion copyWith(
      {Value<String>? id,
      Value<String>? creditorName,
      Value<double>? totalAmount,
      Value<double>? paidAmount,
      Value<String>? notes,
      Value<String>? orderId,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return WorkshopDebtsCompanion(
      id: id ?? this.id,
      creditorName: creditorName ?? this.creditorName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (creditorName.present) {
      map['creditor_name'] = Variable<String>(creditorName.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkshopDebtsCompanion(')
          ..write('id: $id, ')
          ..write('creditorName: $creditorName, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('notes: $notes, ')
          ..write('orderId: $orderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashTransfersTable extends CashTransfers
    with TableInfo<$CashTransfersTable, CashTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, amount, note, date, updatedAt, isDeleted, dirty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_transfers';
  @override
  VerificationContext validateIntegrity(Insertable<CashTransfer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashTransfer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $CashTransfersTable createAlias(String alias) {
    return $CashTransfersTable(attachedDatabase, alias);
  }
}

class CashTransfer extends DataClass implements Insertable<CashTransfer> {
  final String id;
  final double amount;
  final String note;
  final int date;
  final int updatedAt;
  final bool isDeleted;
  final bool dirty;
  const CashTransfer(
      {required this.id,
      required this.amount,
      required this.note,
      required this.date,
      required this.updatedAt,
      required this.isDeleted,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount'] = Variable<double>(amount);
    map['note'] = Variable<String>(note);
    map['date'] = Variable<int>(date);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  CashTransfersCompanion toCompanion(bool nullToAbsent) {
    return CashTransfersCompanion(
      id: Value(id),
      amount: Value(amount),
      note: Value(note),
      date: Value(date),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      dirty: Value(dirty),
    );
  }

  factory CashTransfer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashTransfer(
      id: serializer.fromJson<String>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      date: serializer.fromJson<int>(json['date']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String>(note),
      'date': serializer.toJson<int>(date),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  CashTransfer copyWith(
          {String? id,
          double? amount,
          String? note,
          int? date,
          int? updatedAt,
          bool? isDeleted,
          bool? dirty}) =>
      CashTransfer(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        date: date ?? this.date,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        dirty: dirty ?? this.dirty,
      );
  CashTransfer copyWithCompanion(CashTransfersCompanion data) {
    return CashTransfer(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashTransfer(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, amount, note, date, updatedAt, isDeleted, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashTransfer &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.date == this.date &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.dirty == this.dirty);
}

class CashTransfersCompanion extends UpdateCompanion<CashTransfer> {
  final Value<String> id;
  final Value<double> amount;
  final Value<String> note;
  final Value<int> date;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> dirty;
  final Value<int> rowid;
  const CashTransfersCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashTransfersCompanion.insert({
    required String id,
    required double amount,
    this.note = const Value.absent(),
    required int date,
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        amount = Value(amount),
        date = Value(date),
        updatedAt = Value(updatedAt);
  static Insertable<CashTransfer> custom({
    Expression<String>? id,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<int>? date,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashTransfersCompanion copyWith(
      {Value<String>? id,
      Value<double>? amount,
      Value<String>? note,
      Value<int>? date,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return CashTransfersCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashTransfersCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final String value;
  const SyncMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SyncMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaData copyWith({String? key, String? value}) => SyncMetaData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SyncMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $PaymentTransactionsTable paymentTransactions =
      $PaymentTransactionsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $MaterialItemsTable materialItems = $MaterialItemsTable(this);
  late final $WorkersTable workers = $WorkersTable(this);
  late final $WorkerPaymentsTable workerPayments = $WorkerPaymentsTable(this);
  late final $WorkshopDebtsTable workshopDebts = $WorkshopDebtsTable(this);
  late final $CashTransfersTable cashTransfers = $CashTransfersTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        customers,
        orders,
        paymentTransactions,
        expenses,
        materialItems,
        workers,
        workerPayments,
        workshopDebts,
        cashTransfers,
        syncMeta
      ];
}

typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String name,
  required String phone,
  Value<String> address,
  Value<int> serialNumber,
  required int createdAt,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> isArchived,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<String> address,
  Value<int> serialNumber,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> isArchived,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serialNumber => $composableBuilder(
      column: $table.serialNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serialNumber => $composableBuilder(
      column: $table.serialNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get serialNumber => $composableBuilder(
      column: $table.serialNumber, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
    Customer,
    PrefetchHooks Function()> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<int> serialNumber = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            name: name,
            phone: phone,
            address: address,
            serialNumber: serialNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            isArchived: isArchived,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String phone,
            Value<String> address = const Value.absent(),
            Value<int> serialNumber = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            address: address,
            serialNumber: serialNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            isArchived: isArchived,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CustomersTable, Customer>(table),
                    BaseReferences<_$AppDatabase, $CustomersTable, Customer>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
    Customer,
    PrefetchHooks Function()>;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  required String id,
  required String customerId,
  required String customerName,
  required String itemType,
  Value<String> details,
  Value<String> imagesJson,
  required String status,
  Value<double> totalAmount,
  Value<double> totalPaid,
  Value<double> discountAmount,
  Value<String> discountReason,
  required int deliveryDate,
  required int createdAt,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> isArchived,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<String> id,
  Value<String> customerId,
  Value<String> customerName,
  Value<String> itemType,
  Value<String> details,
  Value<String> imagesJson,
  Value<String> status,
  Value<double> totalAmount,
  Value<double> totalPaid,
  Value<double> discountAmount,
  Value<String> discountReason,
  Value<int> deliveryDate,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> isArchived,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get details => $composableBuilder(
      column: $table.details, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagesJson => $composableBuilder(
      column: $table.imagesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalPaid => $composableBuilder(
      column: $table.totalPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get discountReason => $composableBuilder(
      column: $table.discountReason,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deliveryDate => $composableBuilder(
      column: $table.deliveryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get details => $composableBuilder(
      column: $table.details, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagesJson => $composableBuilder(
      column: $table.imagesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalPaid => $composableBuilder(
      column: $table.totalPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get discountReason => $composableBuilder(
      column: $table.discountReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deliveryDate => $composableBuilder(
      column: $table.deliveryDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<String> get imagesJson => $composableBuilder(
      column: $table.imagesJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<double> get totalPaid =>
      $composableBuilder(column: $table.totalPaid, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount, builder: (column) => column);

  GeneratedColumn<String> get discountReason => $composableBuilder(
      column: $table.discountReason, builder: (column) => column);

  GeneratedColumn<int> get deliveryDate => $composableBuilder(
      column: $table.deliveryDate, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$OrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
    Order,
    PrefetchHooks Function()> {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<String> customerName = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String> details = const Value.absent(),
            Value<String> imagesJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<double> totalPaid = const Value.absent(),
            Value<double> discountAmount = const Value.absent(),
            Value<String> discountReason = const Value.absent(),
            Value<int> deliveryDate = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion(
            id: id,
            customerId: customerId,
            customerName: customerName,
            itemType: itemType,
            details: details,
            imagesJson: imagesJson,
            status: status,
            totalAmount: totalAmount,
            totalPaid: totalPaid,
            discountAmount: discountAmount,
            discountReason: discountReason,
            deliveryDate: deliveryDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            isArchived: isArchived,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String customerId,
            required String customerName,
            required String itemType,
            Value<String> details = const Value.absent(),
            Value<String> imagesJson = const Value.absent(),
            required String status,
            Value<double> totalAmount = const Value.absent(),
            Value<double> totalPaid = const Value.absent(),
            Value<double> discountAmount = const Value.absent(),
            Value<String> discountReason = const Value.absent(),
            required int deliveryDate,
            required int createdAt,
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion.insert(
            id: id,
            customerId: customerId,
            customerName: customerName,
            itemType: itemType,
            details: details,
            imagesJson: imagesJson,
            status: status,
            totalAmount: totalAmount,
            totalPaid: totalPaid,
            discountAmount: discountAmount,
            discountReason: discountReason,
            deliveryDate: deliveryDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            isArchived: isArchived,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$OrdersTable, Order>(table),
                    BaseReferences<_$AppDatabase, $OrdersTable, Order>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
    Order,
    PrefetchHooks Function()>;
typedef $$PaymentTransactionsTableCreateCompanionBuilder
    = PaymentTransactionsCompanion Function({
  required String id,
  required String orderId,
  required String customerId,
  required double amountPaid,
  required int paymentDate,
  required String paymentType,
  Value<String> paymentMethod,
  Value<String> status,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$PaymentTransactionsTableUpdateCompanionBuilder
    = PaymentTransactionsCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> customerId,
  Value<double> amountPaid,
  Value<int> paymentDate,
  Value<String> paymentType,
  Value<String> paymentMethod,
  Value<String> status,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$PaymentTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentTransactionsTable> {
  $$PaymentTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amountPaid => $composableBuilder(
      column: $table.amountPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentType => $composableBuilder(
      column: $table.paymentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$PaymentTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentTransactionsTable> {
  $$PaymentTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amountPaid => $composableBuilder(
      column: $table.amountPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentType => $composableBuilder(
      column: $table.paymentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$PaymentTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentTransactionsTable> {
  $$PaymentTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<double> get amountPaid => $composableBuilder(
      column: $table.amountPaid, builder: (column) => column);

  GeneratedColumn<int> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => column);

  GeneratedColumn<String> get paymentType => $composableBuilder(
      column: $table.paymentType, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$PaymentTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PaymentTransactionsTable,
    PaymentTransaction,
    $$PaymentTransactionsTableFilterComposer,
    $$PaymentTransactionsTableOrderingComposer,
    $$PaymentTransactionsTableAnnotationComposer,
    $$PaymentTransactionsTableCreateCompanionBuilder,
    $$PaymentTransactionsTableUpdateCompanionBuilder,
    (
      PaymentTransaction,
      BaseReferences<_$AppDatabase, $PaymentTransactionsTable,
          PaymentTransaction>
    ),
    PaymentTransaction,
    PrefetchHooks Function()> {
  $$PaymentTransactionsTableTableManager(
      _$AppDatabase db, $PaymentTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentTransactionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<double> amountPaid = const Value.absent(),
            Value<int> paymentDate = const Value.absent(),
            Value<String> paymentType = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentTransactionsCompanion(
            id: id,
            orderId: orderId,
            customerId: customerId,
            amountPaid: amountPaid,
            paymentDate: paymentDate,
            paymentType: paymentType,
            paymentMethod: paymentMethod,
            status: status,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            required String customerId,
            required double amountPaid,
            required int paymentDate,
            required String paymentType,
            Value<String> paymentMethod = const Value.absent(),
            Value<String> status = const Value.absent(),
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentTransactionsCompanion.insert(
            id: id,
            orderId: orderId,
            customerId: customerId,
            amountPaid: amountPaid,
            paymentDate: paymentDate,
            paymentType: paymentType,
            paymentMethod: paymentMethod,
            status: status,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PaymentTransactionsTable, PaymentTransaction>(
                        table),
                    BaseReferences<_$AppDatabase, $PaymentTransactionsTable,
                        PaymentTransaction>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PaymentTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PaymentTransactionsTable,
    PaymentTransaction,
    $$PaymentTransactionsTableFilterComposer,
    $$PaymentTransactionsTableOrderingComposer,
    $$PaymentTransactionsTableAnnotationComposer,
    $$PaymentTransactionsTableCreateCompanionBuilder,
    $$PaymentTransactionsTableUpdateCompanionBuilder,
    (
      PaymentTransaction,
      BaseReferences<_$AppDatabase, $PaymentTransactionsTable,
          PaymentTransaction>
    ),
    PaymentTransaction,
    PrefetchHooks Function()>;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required double amount,
  required String category,
  Value<String> description,
  Value<String?> workerName,
  Value<String?> orderId,
  Value<String?> customerId,
  Value<String?> customerName,
  Value<String> paymentMethod,
  Value<String?> workshopDebtId,
  Value<String> orderAllocationsJson,
  required int date,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<double> amount,
  Value<String> category,
  Value<String> description,
  Value<String?> workerName,
  Value<String?> orderId,
  Value<String?> customerId,
  Value<String?> customerName,
  Value<String> paymentMethod,
  Value<String?> workshopDebtId,
  Value<String> orderAllocationsJson,
  Value<int> date,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workerName => $composableBuilder(
      column: $table.workerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workshopDebtId => $composableBuilder(
      column: $table.workshopDebtId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderAllocationsJson => $composableBuilder(
      column: $table.orderAllocationsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workerName => $composableBuilder(
      column: $table.workerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workshopDebtId => $composableBuilder(
      column: $table.workshopDebtId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderAllocationsJson => $composableBuilder(
      column: $table.orderAllocationsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get workerName => $composableBuilder(
      column: $table.workerName, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get workshopDebtId => $composableBuilder(
      column: $table.workshopDebtId, builder: (column) => column);

  GeneratedColumn<String> get orderAllocationsJson => $composableBuilder(
      column: $table.orderAllocationsJson, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
    Expense,
    PrefetchHooks Function()> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String?> workerName = const Value.absent(),
            Value<String?> orderId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String?> workshopDebtId = const Value.absent(),
            Value<String> orderAllocationsJson = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            amount: amount,
            category: category,
            description: description,
            workerName: workerName,
            orderId: orderId,
            customerId: customerId,
            customerName: customerName,
            paymentMethod: paymentMethod,
            workshopDebtId: workshopDebtId,
            orderAllocationsJson: orderAllocationsJson,
            date: date,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required double amount,
            required String category,
            Value<String> description = const Value.absent(),
            Value<String?> workerName = const Value.absent(),
            Value<String?> orderId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String?> workshopDebtId = const Value.absent(),
            Value<String> orderAllocationsJson = const Value.absent(),
            required int date,
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            amount: amount,
            category: category,
            description: description,
            workerName: workerName,
            orderId: orderId,
            customerId: customerId,
            customerName: customerName,
            paymentMethod: paymentMethod,
            workshopDebtId: workshopDebtId,
            orderAllocationsJson: orderAllocationsJson,
            date: date,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ExpensesTable, Expense>(table),
                    BaseReferences<_$AppDatabase, $ExpensesTable, Expense>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
    Expense,
    PrefetchHooks Function()>;
typedef $$MaterialItemsTableCreateCompanionBuilder = MaterialItemsCompanion
    Function({
  required String id,
  required String name,
  required String unit,
  Value<double> quantity,
  Value<double> minThreshold,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$MaterialItemsTableUpdateCompanionBuilder = MaterialItemsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> unit,
  Value<double> quantity,
  Value<double> minThreshold,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$MaterialItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialItemsTable> {
  $$MaterialItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minThreshold => $composableBuilder(
      column: $table.minThreshold, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$MaterialItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialItemsTable> {
  $$MaterialItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minThreshold => $composableBuilder(
      column: $table.minThreshold,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$MaterialItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialItemsTable> {
  $$MaterialItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get minThreshold => $composableBuilder(
      column: $table.minThreshold, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$MaterialItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MaterialItemsTable,
    MaterialItem,
    $$MaterialItemsTableFilterComposer,
    $$MaterialItemsTableOrderingComposer,
    $$MaterialItemsTableAnnotationComposer,
    $$MaterialItemsTableCreateCompanionBuilder,
    $$MaterialItemsTableUpdateCompanionBuilder,
    (
      MaterialItem,
      BaseReferences<_$AppDatabase, $MaterialItemsTable, MaterialItem>
    ),
    MaterialItem,
    PrefetchHooks Function()> {
  $$MaterialItemsTableTableManager(_$AppDatabase db, $MaterialItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaterialItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaterialItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> minThreshold = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MaterialItemsCompanion(
            id: id,
            name: name,
            unit: unit,
            quantity: quantity,
            minThreshold: minThreshold,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String unit,
            Value<double> quantity = const Value.absent(),
            Value<double> minThreshold = const Value.absent(),
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MaterialItemsCompanion.insert(
            id: id,
            name: name,
            unit: unit,
            quantity: quantity,
            minThreshold: minThreshold,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MaterialItemsTable, MaterialItem>(table),
                    BaseReferences<_$AppDatabase, $MaterialItemsTable,
                        MaterialItem>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MaterialItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MaterialItemsTable,
    MaterialItem,
    $$MaterialItemsTableFilterComposer,
    $$MaterialItemsTableOrderingComposer,
    $$MaterialItemsTableAnnotationComposer,
    $$MaterialItemsTableCreateCompanionBuilder,
    $$MaterialItemsTableUpdateCompanionBuilder,
    (
      MaterialItem,
      BaseReferences<_$AppDatabase, $MaterialItemsTable, MaterialItem>
    ),
    MaterialItem,
    PrefetchHooks Function()>;
typedef $$WorkersTableCreateCompanionBuilder = WorkersCompanion Function({
  required String id,
  required String name,
  required String jobTitle,
  required String salaryType,
  Value<double> salaryAmount,
  Value<int> payWeekday,
  Value<String> phone,
  Value<String> notes,
  required int createdAt,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$WorkersTableUpdateCompanionBuilder = WorkersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> jobTitle,
  Value<String> salaryType,
  Value<double> salaryAmount,
  Value<int> payWeekday,
  Value<String> phone,
  Value<String> notes,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$WorkersTableFilterComposer
    extends Composer<_$AppDatabase, $WorkersTable> {
  $$WorkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobTitle => $composableBuilder(
      column: $table.jobTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get salaryType => $composableBuilder(
      column: $table.salaryType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get salaryAmount => $composableBuilder(
      column: $table.salaryAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get payWeekday => $composableBuilder(
      column: $table.payWeekday, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$WorkersTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkersTable> {
  $$WorkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobTitle => $composableBuilder(
      column: $table.jobTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get salaryType => $composableBuilder(
      column: $table.salaryType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get salaryAmount => $composableBuilder(
      column: $table.salaryAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get payWeekday => $composableBuilder(
      column: $table.payWeekday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$WorkersTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkersTable> {
  $$WorkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get jobTitle =>
      $composableBuilder(column: $table.jobTitle, builder: (column) => column);

  GeneratedColumn<String> get salaryType => $composableBuilder(
      column: $table.salaryType, builder: (column) => column);

  GeneratedColumn<double> get salaryAmount => $composableBuilder(
      column: $table.salaryAmount, builder: (column) => column);

  GeneratedColumn<int> get payWeekday => $composableBuilder(
      column: $table.payWeekday, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$WorkersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkersTable,
    Worker,
    $$WorkersTableFilterComposer,
    $$WorkersTableOrderingComposer,
    $$WorkersTableAnnotationComposer,
    $$WorkersTableCreateCompanionBuilder,
    $$WorkersTableUpdateCompanionBuilder,
    (Worker, BaseReferences<_$AppDatabase, $WorkersTable, Worker>),
    Worker,
    PrefetchHooks Function()> {
  $$WorkersTableTableManager(_$AppDatabase db, $WorkersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> jobTitle = const Value.absent(),
            Value<String> salaryType = const Value.absent(),
            Value<double> salaryAmount = const Value.absent(),
            Value<int> payWeekday = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkersCompanion(
            id: id,
            name: name,
            jobTitle: jobTitle,
            salaryType: salaryType,
            salaryAmount: salaryAmount,
            payWeekday: payWeekday,
            phone: phone,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String jobTitle,
            required String salaryType,
            Value<double> salaryAmount = const Value.absent(),
            Value<int> payWeekday = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> notes = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkersCompanion.insert(
            id: id,
            name: name,
            jobTitle: jobTitle,
            salaryType: salaryType,
            salaryAmount: salaryAmount,
            payWeekday: payWeekday,
            phone: phone,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$WorkersTable, Worker>(table),
                    BaseReferences<_$AppDatabase, $WorkersTable, Worker>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkersTable,
    Worker,
    $$WorkersTableFilterComposer,
    $$WorkersTableOrderingComposer,
    $$WorkersTableAnnotationComposer,
    $$WorkersTableCreateCompanionBuilder,
    $$WorkersTableUpdateCompanionBuilder,
    (Worker, BaseReferences<_$AppDatabase, $WorkersTable, Worker>),
    Worker,
    PrefetchHooks Function()>;
typedef $$WorkerPaymentsTableCreateCompanionBuilder = WorkerPaymentsCompanion
    Function({
  required String id,
  required String workerId,
  required String workerName,
  required double amount,
  required int paymentDate,
  required int periodStart,
  Value<String?> expenseId,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$WorkerPaymentsTableUpdateCompanionBuilder = WorkerPaymentsCompanion
    Function({
  Value<String> id,
  Value<String> workerId,
  Value<String> workerName,
  Value<double> amount,
  Value<int> paymentDate,
  Value<int> periodStart,
  Value<String?> expenseId,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$WorkerPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkerPaymentsTable> {
  $$WorkerPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workerId => $composableBuilder(
      column: $table.workerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workerName => $composableBuilder(
      column: $table.workerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$WorkerPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkerPaymentsTable> {
  $$WorkerPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workerId => $composableBuilder(
      column: $table.workerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workerName => $composableBuilder(
      column: $table.workerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$WorkerPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkerPaymentsTable> {
  $$WorkerPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get workerName => $composableBuilder(
      column: $table.workerName, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => column);

  GeneratedColumn<int> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => column);

  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$WorkerPaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkerPaymentsTable,
    WorkerPayment,
    $$WorkerPaymentsTableFilterComposer,
    $$WorkerPaymentsTableOrderingComposer,
    $$WorkerPaymentsTableAnnotationComposer,
    $$WorkerPaymentsTableCreateCompanionBuilder,
    $$WorkerPaymentsTableUpdateCompanionBuilder,
    (
      WorkerPayment,
      BaseReferences<_$AppDatabase, $WorkerPaymentsTable, WorkerPayment>
    ),
    WorkerPayment,
    PrefetchHooks Function()> {
  $$WorkerPaymentsTableTableManager(
      _$AppDatabase db, $WorkerPaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkerPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkerPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkerPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workerId = const Value.absent(),
            Value<String> workerName = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<int> paymentDate = const Value.absent(),
            Value<int> periodStart = const Value.absent(),
            Value<String?> expenseId = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkerPaymentsCompanion(
            id: id,
            workerId: workerId,
            workerName: workerName,
            amount: amount,
            paymentDate: paymentDate,
            periodStart: periodStart,
            expenseId: expenseId,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workerId,
            required String workerName,
            required double amount,
            required int paymentDate,
            required int periodStart,
            Value<String?> expenseId = const Value.absent(),
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkerPaymentsCompanion.insert(
            id: id,
            workerId: workerId,
            workerName: workerName,
            amount: amount,
            paymentDate: paymentDate,
            periodStart: periodStart,
            expenseId: expenseId,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$WorkerPaymentsTable, WorkerPayment>(table),
                    BaseReferences<_$AppDatabase, $WorkerPaymentsTable,
                        WorkerPayment>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkerPaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkerPaymentsTable,
    WorkerPayment,
    $$WorkerPaymentsTableFilterComposer,
    $$WorkerPaymentsTableOrderingComposer,
    $$WorkerPaymentsTableAnnotationComposer,
    $$WorkerPaymentsTableCreateCompanionBuilder,
    $$WorkerPaymentsTableUpdateCompanionBuilder,
    (
      WorkerPayment,
      BaseReferences<_$AppDatabase, $WorkerPaymentsTable, WorkerPayment>
    ),
    WorkerPayment,
    PrefetchHooks Function()>;
typedef $$WorkshopDebtsTableCreateCompanionBuilder = WorkshopDebtsCompanion
    Function({
  required String id,
  required String creditorName,
  Value<double> totalAmount,
  Value<double> paidAmount,
  Value<String> notes,
  Value<String> orderId,
  required int createdAt,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$WorkshopDebtsTableUpdateCompanionBuilder = WorkshopDebtsCompanion
    Function({
  Value<String> id,
  Value<String> creditorName,
  Value<double> totalAmount,
  Value<double> paidAmount,
  Value<String> notes,
  Value<String> orderId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$WorkshopDebtsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkshopDebtsTable> {
  $$WorkshopDebtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get creditorName => $composableBuilder(
      column: $table.creditorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$WorkshopDebtsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkshopDebtsTable> {
  $$WorkshopDebtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get creditorName => $composableBuilder(
      column: $table.creditorName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$WorkshopDebtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkshopDebtsTable> {
  $$WorkshopDebtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get creditorName => $composableBuilder(
      column: $table.creditorName, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$WorkshopDebtsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkshopDebtsTable,
    WorkshopDebt,
    $$WorkshopDebtsTableFilterComposer,
    $$WorkshopDebtsTableOrderingComposer,
    $$WorkshopDebtsTableAnnotationComposer,
    $$WorkshopDebtsTableCreateCompanionBuilder,
    $$WorkshopDebtsTableUpdateCompanionBuilder,
    (
      WorkshopDebt,
      BaseReferences<_$AppDatabase, $WorkshopDebtsTable, WorkshopDebt>
    ),
    WorkshopDebt,
    PrefetchHooks Function()> {
  $$WorkshopDebtsTableTableManager(_$AppDatabase db, $WorkshopDebtsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkshopDebtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkshopDebtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkshopDebtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> creditorName = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<double> paidAmount = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkshopDebtsCompanion(
            id: id,
            creditorName: creditorName,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            notes: notes,
            orderId: orderId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String creditorName,
            Value<double> totalAmount = const Value.absent(),
            Value<double> paidAmount = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkshopDebtsCompanion.insert(
            id: id,
            creditorName: creditorName,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            notes: notes,
            orderId: orderId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$WorkshopDebtsTable, WorkshopDebt>(table),
                    BaseReferences<_$AppDatabase, $WorkshopDebtsTable,
                        WorkshopDebt>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkshopDebtsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkshopDebtsTable,
    WorkshopDebt,
    $$WorkshopDebtsTableFilterComposer,
    $$WorkshopDebtsTableOrderingComposer,
    $$WorkshopDebtsTableAnnotationComposer,
    $$WorkshopDebtsTableCreateCompanionBuilder,
    $$WorkshopDebtsTableUpdateCompanionBuilder,
    (
      WorkshopDebt,
      BaseReferences<_$AppDatabase, $WorkshopDebtsTable, WorkshopDebt>
    ),
    WorkshopDebt,
    PrefetchHooks Function()>;
typedef $$CashTransfersTableCreateCompanionBuilder = CashTransfersCompanion
    Function({
  required String id,
  required double amount,
  Value<String> note,
  required int date,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$CashTransfersTableUpdateCompanionBuilder = CashTransfersCompanion
    Function({
  Value<String> id,
  Value<double> amount,
  Value<String> note,
  Value<int> date,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$CashTransfersTableFilterComposer
    extends Composer<_$AppDatabase, $CashTransfersTable> {
  $$CashTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$CashTransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $CashTransfersTable> {
  $$CashTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$CashTransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashTransfersTable> {
  $$CashTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$CashTransfersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CashTransfersTable,
    CashTransfer,
    $$CashTransfersTableFilterComposer,
    $$CashTransfersTableOrderingComposer,
    $$CashTransfersTableAnnotationComposer,
    $$CashTransfersTableCreateCompanionBuilder,
    $$CashTransfersTableUpdateCompanionBuilder,
    (
      CashTransfer,
      BaseReferences<_$AppDatabase, $CashTransfersTable, CashTransfer>
    ),
    CashTransfer,
    PrefetchHooks Function()> {
  $$CashTransfersTableTableManager(_$AppDatabase db, $CashTransfersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashTransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashTransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CashTransfersCompanion(
            id: id,
            amount: amount,
            note: note,
            date: date,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required double amount,
            Value<String> note = const Value.absent(),
            required int date,
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CashTransfersCompanion.insert(
            id: id,
            amount: amount,
            note: note,
            date: date,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CashTransfersTable, CashTransfer>(table),
                    BaseReferences<_$AppDatabase, $CashTransfersTable,
                        CashTransfer>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CashTransfersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CashTransfersTable,
    CashTransfer,
    $$CashTransfersTableFilterComposer,
    $$CashTransfersTableOrderingComposer,
    $$CashTransfersTableAnnotationComposer,
    $$CashTransfersTableCreateCompanionBuilder,
    $$CashTransfersTableUpdateCompanionBuilder,
    (
      CashTransfer,
      BaseReferences<_$AppDatabase, $CashTransfersTable, CashTransfer>
    ),
    CashTransfer,
    PrefetchHooks Function()>;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaData, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>),
    SyncMetaData,
    PrefetchHooks Function()> {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncMetaTable, SyncMetaData>(table),
                    BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaData, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>),
    SyncMetaData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$PaymentTransactionsTableTableManager get paymentTransactions =>
      $$PaymentTransactionsTableTableManager(_db, _db.paymentTransactions);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$MaterialItemsTableTableManager get materialItems =>
      $$MaterialItemsTableTableManager(_db, _db.materialItems);
  $$WorkersTableTableManager get workers =>
      $$WorkersTableTableManager(_db, _db.workers);
  $$WorkerPaymentsTableTableManager get workerPayments =>
      $$WorkerPaymentsTableTableManager(_db, _db.workerPayments);
  $$WorkshopDebtsTableTableManager get workshopDebts =>
      $$WorkshopDebtsTableTableManager(_db, _db.workshopDebts);
  $$CashTransfersTableTableManager get cashTransfers =>
      $$CashTransfersTableTableManager(_db, _db.cashTransfers);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
