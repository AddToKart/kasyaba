// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_providers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) =>
    _$AccountImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'cash',
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
    };

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['iconKey'] as String? ?? 'receipt',
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconKey': instance.iconKey,
    };

_$TransactionEntryImpl _$$TransactionEntryImplFromJson(
  Map<String, dynamic> json,
) => _$TransactionEntryImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  amount: (json['amount'] as num).toDouble(),
  isExpense: json['isExpense'] as bool,
  date: DateTime.parse(json['date'] as String),
  categoryName: json['categoryName'] as String,
  type: json['type'] as String? ?? 'expense',
  status: json['status'] as String? ?? 'posted',
  accountId: json['accountId'] as String?,
  categoryId: json['categoryId'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$TransactionEntryImplToJson(
  _$TransactionEntryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'amount': instance.amount,
  'isExpense': instance.isExpense,
  'date': instance.date.toIso8601String(),
  'categoryName': instance.categoryName,
  'type': instance.type,
  'status': instance.status,
  'accountId': instance.accountId,
  'categoryId': instance.categoryId,
  'notes': instance.notes,
};

_$AlertItemImpl _$$AlertItemImplFromJson(Map<String, dynamic> json) =>
    _$AlertItemImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      severity: json['severity'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$$AlertItemImplToJson(_$AlertItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'severity': instance.severity,
      'title': instance.title,
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
    };
