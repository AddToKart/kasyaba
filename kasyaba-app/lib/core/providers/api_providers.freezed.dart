// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Account _$AccountFromJson(Map<String, dynamic> json) {
  return _Account.fromJson(json);
}

/// @nodoc
mixin _$Account {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountCopyWith<Account> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountCopyWith<$Res> {
  factory $AccountCopyWith(Account value, $Res Function(Account) then) =
      _$AccountCopyWithImpl<$Res, Account>;
  @useResult
  $Res call({String id, String name, String type});
}

/// @nodoc
class _$AccountCopyWithImpl<$Res, $Val extends Account>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? type = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountImplCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$$AccountImplCopyWith(
    _$AccountImpl value,
    $Res Function(_$AccountImpl) then,
  ) = __$$AccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String type});
}

/// @nodoc
class __$$AccountImplCopyWithImpl<$Res>
    extends _$AccountCopyWithImpl<$Res, _$AccountImpl>
    implements _$$AccountImplCopyWith<$Res> {
  __$$AccountImplCopyWithImpl(
    _$AccountImpl _value,
    $Res Function(_$AccountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? type = null}) {
    return _then(
      _$AccountImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountImpl implements _Account {
  const _$AccountImpl({
    required this.id,
    required this.name,
    this.type = 'cash',
  });

  factory _$AccountImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String type;

  @override
  String toString() {
    return 'Account(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, type);

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      __$$AccountImplCopyWithImpl<_$AccountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountImplToJson(this);
  }
}

abstract class _Account implements Account {
  const factory _Account({
    required final String id,
    required final String name,
    final String type,
  }) = _$AccountImpl;

  factory _Account.fromJson(Map<String, dynamic> json) = _$AccountImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get type;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Category _$CategoryFromJson(Map<String, dynamic> json) {
  return _Category.fromJson(json);
}

/// @nodoc
mixin _$Category {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get iconKey => throw _privateConstructorUsedError;

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryCopyWith<Category> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryCopyWith<$Res> {
  factory $CategoryCopyWith(Category value, $Res Function(Category) then) =
      _$CategoryCopyWithImpl<$Res, Category>;
  @useResult
  $Res call({String id, String name, String iconKey});
}

/// @nodoc
class _$CategoryCopyWithImpl<$Res, $Val extends Category>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? iconKey = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            iconKey: null == iconKey
                ? _value.iconKey
                : iconKey // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryImplCopyWith<$Res>
    implements $CategoryCopyWith<$Res> {
  factory _$$CategoryImplCopyWith(
    _$CategoryImpl value,
    $Res Function(_$CategoryImpl) then,
  ) = __$$CategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String iconKey});
}

/// @nodoc
class __$$CategoryImplCopyWithImpl<$Res>
    extends _$CategoryCopyWithImpl<$Res, _$CategoryImpl>
    implements _$$CategoryImplCopyWith<$Res> {
  __$$CategoryImplCopyWithImpl(
    _$CategoryImpl _value,
    $Res Function(_$CategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? iconKey = null}) {
    return _then(
      _$CategoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        iconKey: null == iconKey
            ? _value.iconKey
            : iconKey // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryImpl implements _Category {
  const _$CategoryImpl({
    required this.id,
    required this.name,
    this.iconKey = 'receipt',
  });

  factory _$CategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String iconKey;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, iconKey: $iconKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, iconKey);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      __$$CategoryImplCopyWithImpl<_$CategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryImplToJson(this);
  }
}

abstract class _Category implements Category {
  const factory _Category({
    required final String id,
    required final String name,
    final String iconKey,
  }) = _$CategoryImpl;

  factory _Category.fromJson(Map<String, dynamic> json) =
      _$CategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get iconKey;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CategoryExpenseSummary {
  String get categoryName => throw _privateConstructorUsedError;
  String get iconKey => throw _privateConstructorUsedError;
  double get total => throw _privateConstructorUsedError;

  /// Create a copy of CategoryExpenseSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryExpenseSummaryCopyWith<CategoryExpenseSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryExpenseSummaryCopyWith<$Res> {
  factory $CategoryExpenseSummaryCopyWith(
    CategoryExpenseSummary value,
    $Res Function(CategoryExpenseSummary) then,
  ) = _$CategoryExpenseSummaryCopyWithImpl<$Res, CategoryExpenseSummary>;
  @useResult
  $Res call({String categoryName, String iconKey, double total});
}

/// @nodoc
class _$CategoryExpenseSummaryCopyWithImpl<
  $Res,
  $Val extends CategoryExpenseSummary
>
    implements $CategoryExpenseSummaryCopyWith<$Res> {
  _$CategoryExpenseSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryExpenseSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryName = null,
    Object? iconKey = null,
    Object? total = null,
  }) {
    return _then(
      _value.copyWith(
            categoryName: null == categoryName
                ? _value.categoryName
                : categoryName // ignore: cast_nullable_to_non_nullable
                      as String,
            iconKey: null == iconKey
                ? _value.iconKey
                : iconKey // ignore: cast_nullable_to_non_nullable
                      as String,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryExpenseSummaryImplCopyWith<$Res>
    implements $CategoryExpenseSummaryCopyWith<$Res> {
  factory _$$CategoryExpenseSummaryImplCopyWith(
    _$CategoryExpenseSummaryImpl value,
    $Res Function(_$CategoryExpenseSummaryImpl) then,
  ) = __$$CategoryExpenseSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String categoryName, String iconKey, double total});
}

/// @nodoc
class __$$CategoryExpenseSummaryImplCopyWithImpl<$Res>
    extends
        _$CategoryExpenseSummaryCopyWithImpl<$Res, _$CategoryExpenseSummaryImpl>
    implements _$$CategoryExpenseSummaryImplCopyWith<$Res> {
  __$$CategoryExpenseSummaryImplCopyWithImpl(
    _$CategoryExpenseSummaryImpl _value,
    $Res Function(_$CategoryExpenseSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CategoryExpenseSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryName = null,
    Object? iconKey = null,
    Object? total = null,
  }) {
    return _then(
      _$CategoryExpenseSummaryImpl(
        categoryName: null == categoryName
            ? _value.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String,
        iconKey: null == iconKey
            ? _value.iconKey
            : iconKey // ignore: cast_nullable_to_non_nullable
                  as String,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$CategoryExpenseSummaryImpl implements _CategoryExpenseSummary {
  const _$CategoryExpenseSummaryImpl({
    this.categoryName = 'Other',
    this.iconKey = 'receipt',
    this.total = 0.0,
  });

  @override
  @JsonKey()
  final String categoryName;
  @override
  @JsonKey()
  final String iconKey;
  @override
  @JsonKey()
  final double total;

  @override
  String toString() {
    return 'CategoryExpenseSummary(categoryName: $categoryName, iconKey: $iconKey, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryExpenseSummaryImpl &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey) &&
            (identical(other.total, total) || other.total == total));
  }

  @override
  int get hashCode => Object.hash(runtimeType, categoryName, iconKey, total);

  /// Create a copy of CategoryExpenseSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryExpenseSummaryImplCopyWith<_$CategoryExpenseSummaryImpl>
  get copyWith =>
      __$$CategoryExpenseSummaryImplCopyWithImpl<_$CategoryExpenseSummaryImpl>(
        this,
        _$identity,
      );
}

abstract class _CategoryExpenseSummary implements CategoryExpenseSummary {
  const factory _CategoryExpenseSummary({
    final String categoryName,
    final String iconKey,
    final double total,
  }) = _$CategoryExpenseSummaryImpl;

  @override
  String get categoryName;
  @override
  String get iconKey;
  @override
  double get total;

  /// Create a copy of CategoryExpenseSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryExpenseSummaryImplCopyWith<_$CategoryExpenseSummaryImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DailyBalancePoint {
  String get date => throw _privateConstructorUsedError;
  double get balance => throw _privateConstructorUsedError;
  double? get projected => throw _privateConstructorUsedError;

  /// Create a copy of DailyBalancePoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyBalancePointCopyWith<DailyBalancePoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyBalancePointCopyWith<$Res> {
  factory $DailyBalancePointCopyWith(
    DailyBalancePoint value,
    $Res Function(DailyBalancePoint) then,
  ) = _$DailyBalancePointCopyWithImpl<$Res, DailyBalancePoint>;
  @useResult
  $Res call({String date, double balance, double? projected});
}

/// @nodoc
class _$DailyBalancePointCopyWithImpl<$Res, $Val extends DailyBalancePoint>
    implements $DailyBalancePointCopyWith<$Res> {
  _$DailyBalancePointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyBalancePoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? balance = null,
    Object? projected = freezed,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            balance: null == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double,
            projected: freezed == projected
                ? _value.projected
                : projected // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DailyBalancePointImplCopyWith<$Res>
    implements $DailyBalancePointCopyWith<$Res> {
  factory _$$DailyBalancePointImplCopyWith(
    _$DailyBalancePointImpl value,
    $Res Function(_$DailyBalancePointImpl) then,
  ) = __$$DailyBalancePointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, double balance, double? projected});
}

/// @nodoc
class __$$DailyBalancePointImplCopyWithImpl<$Res>
    extends _$DailyBalancePointCopyWithImpl<$Res, _$DailyBalancePointImpl>
    implements _$$DailyBalancePointImplCopyWith<$Res> {
  __$$DailyBalancePointImplCopyWithImpl(
    _$DailyBalancePointImpl _value,
    $Res Function(_$DailyBalancePointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DailyBalancePoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? balance = null,
    Object? projected = freezed,
  }) {
    return _then(
      _$DailyBalancePointImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double,
        projected: freezed == projected
            ? _value.projected
            : projected // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc

class _$DailyBalancePointImpl implements _DailyBalancePoint {
  const _$DailyBalancePointImpl({
    required this.date,
    required this.balance,
    this.projected,
  });

  @override
  final String date;
  @override
  final double balance;
  @override
  final double? projected;

  @override
  String toString() {
    return 'DailyBalancePoint(date: $date, balance: $balance, projected: $projected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyBalancePointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.projected, projected) ||
                other.projected == projected));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, balance, projected);

  /// Create a copy of DailyBalancePoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyBalancePointImplCopyWith<_$DailyBalancePointImpl> get copyWith =>
      __$$DailyBalancePointImplCopyWithImpl<_$DailyBalancePointImpl>(
        this,
        _$identity,
      );
}

abstract class _DailyBalancePoint implements DailyBalancePoint {
  const factory _DailyBalancePoint({
    required final String date,
    required final double balance,
    final double? projected,
  }) = _$DailyBalancePointImpl;

  @override
  String get date;
  @override
  double get balance;
  @override
  double? get projected;

  /// Create a copy of DailyBalancePoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyBalancePointImplCopyWith<_$DailyBalancePointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DashboardData {
  double get totalBalance => throw _privateConstructorUsedError;
  double get income => throw _privateConstructorUsedError;
  double get expenses => throw _privateConstructorUsedError;
  double get savings => throw _privateConstructorUsedError;
  String get healthScore => throw _privateConstructorUsedError;
  double get predictedMonthEnd => throw _privateConstructorUsedError;
  double get budgetUsedPercent => throw _privateConstructorUsedError;
  List<CategoryExpenseSummary> get categoryExpenses =>
      throw _privateConstructorUsedError;
  List<DailyBalancePoint> get dailyBalance =>
      throw _privateConstructorUsedError;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardDataCopyWith<DashboardData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardDataCopyWith<$Res> {
  factory $DashboardDataCopyWith(
    DashboardData value,
    $Res Function(DashboardData) then,
  ) = _$DashboardDataCopyWithImpl<$Res, DashboardData>;
  @useResult
  $Res call({
    double totalBalance,
    double income,
    double expenses,
    double savings,
    String healthScore,
    double predictedMonthEnd,
    double budgetUsedPercent,
    List<CategoryExpenseSummary> categoryExpenses,
    List<DailyBalancePoint> dailyBalance,
  });
}

/// @nodoc
class _$DashboardDataCopyWithImpl<$Res, $Val extends DashboardData>
    implements $DashboardDataCopyWith<$Res> {
  _$DashboardDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBalance = null,
    Object? income = null,
    Object? expenses = null,
    Object? savings = null,
    Object? healthScore = null,
    Object? predictedMonthEnd = null,
    Object? budgetUsedPercent = null,
    Object? categoryExpenses = null,
    Object? dailyBalance = null,
  }) {
    return _then(
      _value.copyWith(
            totalBalance: null == totalBalance
                ? _value.totalBalance
                : totalBalance // ignore: cast_nullable_to_non_nullable
                      as double,
            income: null == income
                ? _value.income
                : income // ignore: cast_nullable_to_non_nullable
                      as double,
            expenses: null == expenses
                ? _value.expenses
                : expenses // ignore: cast_nullable_to_non_nullable
                      as double,
            savings: null == savings
                ? _value.savings
                : savings // ignore: cast_nullable_to_non_nullable
                      as double,
            healthScore: null == healthScore
                ? _value.healthScore
                : healthScore // ignore: cast_nullable_to_non_nullable
                      as String,
            predictedMonthEnd: null == predictedMonthEnd
                ? _value.predictedMonthEnd
                : predictedMonthEnd // ignore: cast_nullable_to_non_nullable
                      as double,
            budgetUsedPercent: null == budgetUsedPercent
                ? _value.budgetUsedPercent
                : budgetUsedPercent // ignore: cast_nullable_to_non_nullable
                      as double,
            categoryExpenses: null == categoryExpenses
                ? _value.categoryExpenses
                : categoryExpenses // ignore: cast_nullable_to_non_nullable
                      as List<CategoryExpenseSummary>,
            dailyBalance: null == dailyBalance
                ? _value.dailyBalance
                : dailyBalance // ignore: cast_nullable_to_non_nullable
                      as List<DailyBalancePoint>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardDataImplCopyWith<$Res>
    implements $DashboardDataCopyWith<$Res> {
  factory _$$DashboardDataImplCopyWith(
    _$DashboardDataImpl value,
    $Res Function(_$DashboardDataImpl) then,
  ) = __$$DashboardDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double totalBalance,
    double income,
    double expenses,
    double savings,
    String healthScore,
    double predictedMonthEnd,
    double budgetUsedPercent,
    List<CategoryExpenseSummary> categoryExpenses,
    List<DailyBalancePoint> dailyBalance,
  });
}

/// @nodoc
class __$$DashboardDataImplCopyWithImpl<$Res>
    extends _$DashboardDataCopyWithImpl<$Res, _$DashboardDataImpl>
    implements _$$DashboardDataImplCopyWith<$Res> {
  __$$DashboardDataImplCopyWithImpl(
    _$DashboardDataImpl _value,
    $Res Function(_$DashboardDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBalance = null,
    Object? income = null,
    Object? expenses = null,
    Object? savings = null,
    Object? healthScore = null,
    Object? predictedMonthEnd = null,
    Object? budgetUsedPercent = null,
    Object? categoryExpenses = null,
    Object? dailyBalance = null,
  }) {
    return _then(
      _$DashboardDataImpl(
        totalBalance: null == totalBalance
            ? _value.totalBalance
            : totalBalance // ignore: cast_nullable_to_non_nullable
                  as double,
        income: null == income
            ? _value.income
            : income // ignore: cast_nullable_to_non_nullable
                  as double,
        expenses: null == expenses
            ? _value.expenses
            : expenses // ignore: cast_nullable_to_non_nullable
                  as double,
        savings: null == savings
            ? _value.savings
            : savings // ignore: cast_nullable_to_non_nullable
                  as double,
        healthScore: null == healthScore
            ? _value.healthScore
            : healthScore // ignore: cast_nullable_to_non_nullable
                  as String,
        predictedMonthEnd: null == predictedMonthEnd
            ? _value.predictedMonthEnd
            : predictedMonthEnd // ignore: cast_nullable_to_non_nullable
                  as double,
        budgetUsedPercent: null == budgetUsedPercent
            ? _value.budgetUsedPercent
            : budgetUsedPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        categoryExpenses: null == categoryExpenses
            ? _value._categoryExpenses
            : categoryExpenses // ignore: cast_nullable_to_non_nullable
                  as List<CategoryExpenseSummary>,
        dailyBalance: null == dailyBalance
            ? _value._dailyBalance
            : dailyBalance // ignore: cast_nullable_to_non_nullable
                  as List<DailyBalancePoint>,
      ),
    );
  }
}

/// @nodoc

class _$DashboardDataImpl implements _DashboardData {
  const _$DashboardDataImpl({
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.healthScore,
    required this.predictedMonthEnd,
    this.budgetUsedPercent = 0.0,
    required final List<CategoryExpenseSummary> categoryExpenses,
    final List<DailyBalancePoint> dailyBalance = const [],
  }) : _categoryExpenses = categoryExpenses,
       _dailyBalance = dailyBalance;

  @override
  final double totalBalance;
  @override
  final double income;
  @override
  final double expenses;
  @override
  final double savings;
  @override
  final String healthScore;
  @override
  final double predictedMonthEnd;
  @override
  @JsonKey()
  final double budgetUsedPercent;
  final List<CategoryExpenseSummary> _categoryExpenses;
  @override
  List<CategoryExpenseSummary> get categoryExpenses {
    if (_categoryExpenses is EqualUnmodifiableListView)
      return _categoryExpenses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categoryExpenses);
  }

  final List<DailyBalancePoint> _dailyBalance;
  @override
  @JsonKey()
  List<DailyBalancePoint> get dailyBalance {
    if (_dailyBalance is EqualUnmodifiableListView) return _dailyBalance;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dailyBalance);
  }

  @override
  String toString() {
    return 'DashboardData(totalBalance: $totalBalance, income: $income, expenses: $expenses, savings: $savings, healthScore: $healthScore, predictedMonthEnd: $predictedMonthEnd, budgetUsedPercent: $budgetUsedPercent, categoryExpenses: $categoryExpenses, dailyBalance: $dailyBalance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardDataImpl &&
            (identical(other.totalBalance, totalBalance) ||
                other.totalBalance == totalBalance) &&
            (identical(other.income, income) || other.income == income) &&
            (identical(other.expenses, expenses) ||
                other.expenses == expenses) &&
            (identical(other.savings, savings) || other.savings == savings) &&
            (identical(other.healthScore, healthScore) ||
                other.healthScore == healthScore) &&
            (identical(other.predictedMonthEnd, predictedMonthEnd) ||
                other.predictedMonthEnd == predictedMonthEnd) &&
            (identical(other.budgetUsedPercent, budgetUsedPercent) ||
                other.budgetUsedPercent == budgetUsedPercent) &&
            const DeepCollectionEquality().equals(
              other._categoryExpenses,
              _categoryExpenses,
            ) &&
            const DeepCollectionEquality().equals(
              other._dailyBalance,
              _dailyBalance,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalBalance,
    income,
    expenses,
    savings,
    healthScore,
    predictedMonthEnd,
    budgetUsedPercent,
    const DeepCollectionEquality().hash(_categoryExpenses),
    const DeepCollectionEquality().hash(_dailyBalance),
  );

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardDataImplCopyWith<_$DashboardDataImpl> get copyWith =>
      __$$DashboardDataImplCopyWithImpl<_$DashboardDataImpl>(this, _$identity);
}

abstract class _DashboardData implements DashboardData {
  const factory _DashboardData({
    required final double totalBalance,
    required final double income,
    required final double expenses,
    required final double savings,
    required final String healthScore,
    required final double predictedMonthEnd,
    final double budgetUsedPercent,
    required final List<CategoryExpenseSummary> categoryExpenses,
    final List<DailyBalancePoint> dailyBalance,
  }) = _$DashboardDataImpl;

  @override
  double get totalBalance;
  @override
  double get income;
  @override
  double get expenses;
  @override
  double get savings;
  @override
  String get healthScore;
  @override
  double get predictedMonthEnd;
  @override
  double get budgetUsedPercent;
  @override
  List<CategoryExpenseSummary> get categoryExpenses;
  @override
  List<DailyBalancePoint> get dailyBalance;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardDataImplCopyWith<_$DashboardDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TransactionEntry _$TransactionEntryFromJson(Map<String, dynamic> json) {
  return _TransactionEntry.fromJson(json);
}

/// @nodoc
mixin _$TransactionEntry {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  bool get isExpense => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get categoryName => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get accountId => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this TransactionEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionEntryCopyWith<TransactionEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionEntryCopyWith<$Res> {
  factory $TransactionEntryCopyWith(
    TransactionEntry value,
    $Res Function(TransactionEntry) then,
  ) = _$TransactionEntryCopyWithImpl<$Res, TransactionEntry>;
  @useResult
  $Res call({
    String id,
    String title,
    double amount,
    bool isExpense,
    DateTime date,
    String categoryName,
    String type,
    String status,
    String? accountId,
    String? categoryId,
    String? notes,
  });
}

/// @nodoc
class _$TransactionEntryCopyWithImpl<$Res, $Val extends TransactionEntry>
    implements $TransactionEntryCopyWith<$Res> {
  _$TransactionEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? amount = null,
    Object? isExpense = null,
    Object? date = null,
    Object? categoryName = null,
    Object? type = null,
    Object? status = null,
    Object? accountId = freezed,
    Object? categoryId = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            isExpense: null == isExpense
                ? _value.isExpense
                : isExpense // ignore: cast_nullable_to_non_nullable
                      as bool,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            categoryName: null == categoryName
                ? _value.categoryName
                : categoryName // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            accountId: freezed == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransactionEntryImplCopyWith<$Res>
    implements $TransactionEntryCopyWith<$Res> {
  factory _$$TransactionEntryImplCopyWith(
    _$TransactionEntryImpl value,
    $Res Function(_$TransactionEntryImpl) then,
  ) = __$$TransactionEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    double amount,
    bool isExpense,
    DateTime date,
    String categoryName,
    String type,
    String status,
    String? accountId,
    String? categoryId,
    String? notes,
  });
}

/// @nodoc
class __$$TransactionEntryImplCopyWithImpl<$Res>
    extends _$TransactionEntryCopyWithImpl<$Res, _$TransactionEntryImpl>
    implements _$$TransactionEntryImplCopyWith<$Res> {
  __$$TransactionEntryImplCopyWithImpl(
    _$TransactionEntryImpl _value,
    $Res Function(_$TransactionEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransactionEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? amount = null,
    Object? isExpense = null,
    Object? date = null,
    Object? categoryName = null,
    Object? type = null,
    Object? status = null,
    Object? accountId = freezed,
    Object? categoryId = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$TransactionEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        isExpense: null == isExpense
            ? _value.isExpense
            : isExpense // ignore: cast_nullable_to_non_nullable
                  as bool,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        categoryName: null == categoryName
            ? _value.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        accountId: freezed == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionEntryImpl implements _TransactionEntry {
  const _$TransactionEntryImpl({
    required this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.date,
    required this.categoryName,
    this.type = 'expense',
    this.status = 'posted',
    this.accountId,
    this.categoryId,
    this.notes,
  });

  factory _$TransactionEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final double amount;
  @override
  final bool isExpense;
  @override
  final DateTime date;
  @override
  final String categoryName;
  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final String status;
  @override
  final String? accountId;
  @override
  final String? categoryId;
  @override
  final String? notes;

  @override
  String toString() {
    return 'TransactionEntry(id: $id, title: $title, amount: $amount, isExpense: $isExpense, date: $date, categoryName: $categoryName, type: $type, status: $status, accountId: $accountId, categoryId: $categoryId, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.isExpense, isExpense) ||
                other.isExpense == isExpense) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    amount,
    isExpense,
    date,
    categoryName,
    type,
    status,
    accountId,
    categoryId,
    notes,
  );

  /// Create a copy of TransactionEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionEntryImplCopyWith<_$TransactionEntryImpl> get copyWith =>
      __$$TransactionEntryImplCopyWithImpl<_$TransactionEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionEntryImplToJson(this);
  }
}

abstract class _TransactionEntry implements TransactionEntry {
  const factory _TransactionEntry({
    required final String id,
    required final String title,
    required final double amount,
    required final bool isExpense,
    required final DateTime date,
    required final String categoryName,
    final String type,
    final String status,
    final String? accountId,
    final String? categoryId,
    final String? notes,
  }) = _$TransactionEntryImpl;

  factory _TransactionEntry.fromJson(Map<String, dynamic> json) =
      _$TransactionEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  double get amount;
  @override
  bool get isExpense;
  @override
  DateTime get date;
  @override
  String get categoryName;
  @override
  String get type;
  @override
  String get status;
  @override
  String? get accountId;
  @override
  String? get categoryId;
  @override
  String? get notes;

  /// Create a copy of TransactionEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionEntryImplCopyWith<_$TransactionEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SavingsGoal {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get targetAmount => throw _privateConstructorUsedError;
  double get currentAmount => throw _privateConstructorUsedError;
  String? get targetDate => throw _privateConstructorUsedError;
  bool? get canAffordByTargetDate => throw _privateConstructorUsedError;
  String? get earliestAffordableDate => throw _privateConstructorUsedError;
  double? get monthlySavingsRequired => throw _privateConstructorUsedError;
  int? get daysRemaining => throw _privateConstructorUsedError;

  /// Create a copy of SavingsGoal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SavingsGoalCopyWith<SavingsGoal> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavingsGoalCopyWith<$Res> {
  factory $SavingsGoalCopyWith(
    SavingsGoal value,
    $Res Function(SavingsGoal) then,
  ) = _$SavingsGoalCopyWithImpl<$Res, SavingsGoal>;
  @useResult
  $Res call({
    String id,
    String name,
    double targetAmount,
    double currentAmount,
    String? targetDate,
    bool? canAffordByTargetDate,
    String? earliestAffordableDate,
    double? monthlySavingsRequired,
    int? daysRemaining,
  });
}

/// @nodoc
class _$SavingsGoalCopyWithImpl<$Res, $Val extends SavingsGoal>
    implements $SavingsGoalCopyWith<$Res> {
  _$SavingsGoalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SavingsGoal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetAmount = null,
    Object? currentAmount = null,
    Object? targetDate = freezed,
    Object? canAffordByTargetDate = freezed,
    Object? earliestAffordableDate = freezed,
    Object? monthlySavingsRequired = freezed,
    Object? daysRemaining = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            targetAmount: null == targetAmount
                ? _value.targetAmount
                : targetAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            currentAmount: null == currentAmount
                ? _value.currentAmount
                : currentAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            targetDate: freezed == targetDate
                ? _value.targetDate
                : targetDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            canAffordByTargetDate: freezed == canAffordByTargetDate
                ? _value.canAffordByTargetDate
                : canAffordByTargetDate // ignore: cast_nullable_to_non_nullable
                      as bool?,
            earliestAffordableDate: freezed == earliestAffordableDate
                ? _value.earliestAffordableDate
                : earliestAffordableDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            monthlySavingsRequired: freezed == monthlySavingsRequired
                ? _value.monthlySavingsRequired
                : monthlySavingsRequired // ignore: cast_nullable_to_non_nullable
                      as double?,
            daysRemaining: freezed == daysRemaining
                ? _value.daysRemaining
                : daysRemaining // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SavingsGoalImplCopyWith<$Res>
    implements $SavingsGoalCopyWith<$Res> {
  factory _$$SavingsGoalImplCopyWith(
    _$SavingsGoalImpl value,
    $Res Function(_$SavingsGoalImpl) then,
  ) = __$$SavingsGoalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double targetAmount,
    double currentAmount,
    String? targetDate,
    bool? canAffordByTargetDate,
    String? earliestAffordableDate,
    double? monthlySavingsRequired,
    int? daysRemaining,
  });
}

/// @nodoc
class __$$SavingsGoalImplCopyWithImpl<$Res>
    extends _$SavingsGoalCopyWithImpl<$Res, _$SavingsGoalImpl>
    implements _$$SavingsGoalImplCopyWith<$Res> {
  __$$SavingsGoalImplCopyWithImpl(
    _$SavingsGoalImpl _value,
    $Res Function(_$SavingsGoalImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SavingsGoal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetAmount = null,
    Object? currentAmount = null,
    Object? targetDate = freezed,
    Object? canAffordByTargetDate = freezed,
    Object? earliestAffordableDate = freezed,
    Object? monthlySavingsRequired = freezed,
    Object? daysRemaining = freezed,
  }) {
    return _then(
      _$SavingsGoalImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        targetAmount: null == targetAmount
            ? _value.targetAmount
            : targetAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        currentAmount: null == currentAmount
            ? _value.currentAmount
            : currentAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        targetDate: freezed == targetDate
            ? _value.targetDate
            : targetDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        canAffordByTargetDate: freezed == canAffordByTargetDate
            ? _value.canAffordByTargetDate
            : canAffordByTargetDate // ignore: cast_nullable_to_non_nullable
                  as bool?,
        earliestAffordableDate: freezed == earliestAffordableDate
            ? _value.earliestAffordableDate
            : earliestAffordableDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        monthlySavingsRequired: freezed == monthlySavingsRequired
            ? _value.monthlySavingsRequired
            : monthlySavingsRequired // ignore: cast_nullable_to_non_nullable
                  as double?,
        daysRemaining: freezed == daysRemaining
            ? _value.daysRemaining
            : daysRemaining // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$SavingsGoalImpl extends _SavingsGoal {
  const _$SavingsGoalImpl({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    this.canAffordByTargetDate,
    this.earliestAffordableDate,
    this.monthlySavingsRequired,
    this.daysRemaining,
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final double targetAmount;
  @override
  final double currentAmount;
  @override
  final String? targetDate;
  @override
  final bool? canAffordByTargetDate;
  @override
  final String? earliestAffordableDate;
  @override
  final double? monthlySavingsRequired;
  @override
  final int? daysRemaining;

  @override
  String toString() {
    return 'SavingsGoal(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, targetDate: $targetDate, canAffordByTargetDate: $canAffordByTargetDate, earliestAffordableDate: $earliestAffordableDate, monthlySavingsRequired: $monthlySavingsRequired, daysRemaining: $daysRemaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavingsGoalImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetAmount, targetAmount) ||
                other.targetAmount == targetAmount) &&
            (identical(other.currentAmount, currentAmount) ||
                other.currentAmount == currentAmount) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.canAffordByTargetDate, canAffordByTargetDate) ||
                other.canAffordByTargetDate == canAffordByTargetDate) &&
            (identical(other.earliestAffordableDate, earliestAffordableDate) ||
                other.earliestAffordableDate == earliestAffordableDate) &&
            (identical(other.monthlySavingsRequired, monthlySavingsRequired) ||
                other.monthlySavingsRequired == monthlySavingsRequired) &&
            (identical(other.daysRemaining, daysRemaining) ||
                other.daysRemaining == daysRemaining));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    targetAmount,
    currentAmount,
    targetDate,
    canAffordByTargetDate,
    earliestAffordableDate,
    monthlySavingsRequired,
    daysRemaining,
  );

  /// Create a copy of SavingsGoal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SavingsGoalImplCopyWith<_$SavingsGoalImpl> get copyWith =>
      __$$SavingsGoalImplCopyWithImpl<_$SavingsGoalImpl>(this, _$identity);
}

abstract class _SavingsGoal extends SavingsGoal {
  const factory _SavingsGoal({
    required final String id,
    required final String name,
    required final double targetAmount,
    required final double currentAmount,
    final String? targetDate,
    final bool? canAffordByTargetDate,
    final String? earliestAffordableDate,
    final double? monthlySavingsRequired,
    final int? daysRemaining,
  }) = _$SavingsGoalImpl;
  const _SavingsGoal._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  double get targetAmount;
  @override
  double get currentAmount;
  @override
  String? get targetDate;
  @override
  bool? get canAffordByTargetDate;
  @override
  String? get earliestAffordableDate;
  @override
  double? get monthlySavingsRequired;
  @override
  int? get daysRemaining;

  /// Create a copy of SavingsGoal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SavingsGoalImplCopyWith<_$SavingsGoalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BillItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  DateTime get dueDate => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Create a copy of BillItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BillItemCopyWith<BillItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BillItemCopyWith<$Res> {
  factory $BillItemCopyWith(BillItem value, $Res Function(BillItem) then) =
      _$BillItemCopyWithImpl<$Res, BillItem>;
  @useResult
  $Res call({
    String id,
    String name,
    double amount,
    DateTime dueDate,
    String status,
  });
}

/// @nodoc
class _$BillItemCopyWithImpl<$Res, $Val extends BillItem>
    implements $BillItemCopyWith<$Res> {
  _$BillItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BillItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? amount = null,
    Object? dueDate = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            dueDate: null == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BillItemImplCopyWith<$Res>
    implements $BillItemCopyWith<$Res> {
  factory _$$BillItemImplCopyWith(
    _$BillItemImpl value,
    $Res Function(_$BillItemImpl) then,
  ) = __$$BillItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double amount,
    DateTime dueDate,
    String status,
  });
}

/// @nodoc
class __$$BillItemImplCopyWithImpl<$Res>
    extends _$BillItemCopyWithImpl<$Res, _$BillItemImpl>
    implements _$$BillItemImplCopyWith<$Res> {
  __$$BillItemImplCopyWithImpl(
    _$BillItemImpl _value,
    $Res Function(_$BillItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BillItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? amount = null,
    Object? dueDate = null,
    Object? status = null,
  }) {
    return _then(
      _$BillItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        dueDate: null == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$BillItemImpl implements _BillItem {
  const _$BillItemImpl({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.status = 'upcoming',
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final double amount;
  @override
  final DateTime dueDate;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'BillItem(id: $id, name: $name, amount: $amount, dueDate: $dueDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BillItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, amount, dueDate, status);

  /// Create a copy of BillItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BillItemImplCopyWith<_$BillItemImpl> get copyWith =>
      __$$BillItemImplCopyWithImpl<_$BillItemImpl>(this, _$identity);
}

abstract class _BillItem implements BillItem {
  const factory _BillItem({
    required final String id,
    required final String name,
    required final double amount,
    required final DateTime dueDate,
    final String status,
  }) = _$BillItemImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  double get amount;
  @override
  DateTime get dueDate;
  @override
  String get status;

  /// Create a copy of BillItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BillItemImplCopyWith<_$BillItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$UserProfile {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  double? get salaryAmount => throw _privateConstructorUsedError;
  String? get paydayFrequency => throw _privateConstructorUsedError;
  String? get paydaySchedule => throw _privateConstructorUsedError;
  double? get minimumBalanceThreshold => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
    UserProfile value,
    $Res Function(UserProfile) then,
  ) = _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call({
    String id,
    String email,
    String? displayName,
    double? salaryAmount,
    String? paydayFrequency,
    String? paydaySchedule,
    double? minimumBalanceThreshold,
  });
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? salaryAmount = freezed,
    Object? paydayFrequency = freezed,
    Object? paydaySchedule = freezed,
    Object? minimumBalanceThreshold = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            salaryAmount: freezed == salaryAmount
                ? _value.salaryAmount
                : salaryAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            paydayFrequency: freezed == paydayFrequency
                ? _value.paydayFrequency
                : paydayFrequency // ignore: cast_nullable_to_non_nullable
                      as String?,
            paydaySchedule: freezed == paydaySchedule
                ? _value.paydaySchedule
                : paydaySchedule // ignore: cast_nullable_to_non_nullable
                      as String?,
            minimumBalanceThreshold: freezed == minimumBalanceThreshold
                ? _value.minimumBalanceThreshold
                : minimumBalanceThreshold // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
    _$UserProfileImpl value,
    $Res Function(_$UserProfileImpl) then,
  ) = __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String email,
    String? displayName,
    double? salaryAmount,
    String? paydayFrequency,
    String? paydaySchedule,
    double? minimumBalanceThreshold,
  });
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
    _$UserProfileImpl _value,
    $Res Function(_$UserProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? salaryAmount = freezed,
    Object? paydayFrequency = freezed,
    Object? paydaySchedule = freezed,
    Object? minimumBalanceThreshold = freezed,
  }) {
    return _then(
      _$UserProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        salaryAmount: freezed == salaryAmount
            ? _value.salaryAmount
            : salaryAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        paydayFrequency: freezed == paydayFrequency
            ? _value.paydayFrequency
            : paydayFrequency // ignore: cast_nullable_to_non_nullable
                  as String?,
        paydaySchedule: freezed == paydaySchedule
            ? _value.paydaySchedule
            : paydaySchedule // ignore: cast_nullable_to_non_nullable
                  as String?,
        minimumBalanceThreshold: freezed == minimumBalanceThreshold
            ? _value.minimumBalanceThreshold
            : minimumBalanceThreshold // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc

class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl({
    required this.id,
    required this.email,
    this.displayName,
    this.salaryAmount,
    this.paydayFrequency,
    this.paydaySchedule,
    this.minimumBalanceThreshold,
  });

  @override
  final String id;
  @override
  final String email;
  @override
  final String? displayName;
  @override
  final double? salaryAmount;
  @override
  final String? paydayFrequency;
  @override
  final String? paydaySchedule;
  @override
  final double? minimumBalanceThreshold;

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName, salaryAmount: $salaryAmount, paydayFrequency: $paydayFrequency, paydaySchedule: $paydaySchedule, minimumBalanceThreshold: $minimumBalanceThreshold)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.salaryAmount, salaryAmount) ||
                other.salaryAmount == salaryAmount) &&
            (identical(other.paydayFrequency, paydayFrequency) ||
                other.paydayFrequency == paydayFrequency) &&
            (identical(other.paydaySchedule, paydaySchedule) ||
                other.paydaySchedule == paydaySchedule) &&
            (identical(
                  other.minimumBalanceThreshold,
                  minimumBalanceThreshold,
                ) ||
                other.minimumBalanceThreshold == minimumBalanceThreshold));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    email,
    displayName,
    salaryAmount,
    paydayFrequency,
    paydaySchedule,
    minimumBalanceThreshold,
  );

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile({
    required final String id,
    required final String email,
    final String? displayName,
    final double? salaryAmount,
    final String? paydayFrequency,
    final String? paydaySchedule,
    final double? minimumBalanceThreshold,
  }) = _$UserProfileImpl;

  @override
  String get id;
  @override
  String get email;
  @override
  String? get displayName;
  @override
  double? get salaryAmount;
  @override
  String? get paydayFrequency;
  @override
  String? get paydaySchedule;
  @override
  double? get minimumBalanceThreshold;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AlertItem _$AlertItemFromJson(Map<String, dynamic> json) {
  return _AlertItem.fromJson(json);
}

/// @nodoc
mixin _$AlertItem {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get severity => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get readAt => throw _privateConstructorUsedError;

  /// Serializes this AlertItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlertItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlertItemCopyWith<AlertItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlertItemCopyWith<$Res> {
  factory $AlertItemCopyWith(AlertItem value, $Res Function(AlertItem) then) =
      _$AlertItemCopyWithImpl<$Res, AlertItem>;
  @useResult
  $Res call({
    String id,
    String type,
    String severity,
    String title,
    String message,
    DateTime createdAt,
    DateTime? readAt,
  });
}

/// @nodoc
class _$AlertItemCopyWithImpl<$Res, $Val extends AlertItem>
    implements $AlertItemCopyWith<$Res> {
  _$AlertItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlertItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? severity = null,
    Object? title = null,
    Object? message = null,
    Object? createdAt = null,
    Object? readAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            readAt: freezed == readAt
                ? _value.readAt
                : readAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AlertItemImplCopyWith<$Res>
    implements $AlertItemCopyWith<$Res> {
  factory _$$AlertItemImplCopyWith(
    _$AlertItemImpl value,
    $Res Function(_$AlertItemImpl) then,
  ) = __$$AlertItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String type,
    String severity,
    String title,
    String message,
    DateTime createdAt,
    DateTime? readAt,
  });
}

/// @nodoc
class __$$AlertItemImplCopyWithImpl<$Res>
    extends _$AlertItemCopyWithImpl<$Res, _$AlertItemImpl>
    implements _$$AlertItemImplCopyWith<$Res> {
  __$$AlertItemImplCopyWithImpl(
    _$AlertItemImpl _value,
    $Res Function(_$AlertItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AlertItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? severity = null,
    Object? title = null,
    Object? message = null,
    Object? createdAt = null,
    Object? readAt = freezed,
  }) {
    return _then(
      _$AlertItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        readAt: freezed == readAt
            ? _value.readAt
            : readAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AlertItemImpl implements _AlertItem {
  const _$AlertItemImpl({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  factory _$AlertItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlertItemImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final String severity;
  @override
  final String title;
  @override
  final String message;
  @override
  final DateTime createdAt;
  @override
  final DateTime? readAt;

  @override
  String toString() {
    return 'AlertItem(id: $id, type: $type, severity: $severity, title: $title, message: $message, createdAt: $createdAt, readAt: $readAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlertItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.readAt, readAt) || other.readAt == readAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    severity,
    title,
    message,
    createdAt,
    readAt,
  );

  /// Create a copy of AlertItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlertItemImplCopyWith<_$AlertItemImpl> get copyWith =>
      __$$AlertItemImplCopyWithImpl<_$AlertItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlertItemImplToJson(this);
  }
}

abstract class _AlertItem implements AlertItem {
  const factory _AlertItem({
    required final String id,
    required final String type,
    required final String severity,
    required final String title,
    required final String message,
    required final DateTime createdAt,
    final DateTime? readAt,
  }) = _$AlertItemImpl;

  factory _AlertItem.fromJson(Map<String, dynamic> json) =
      _$AlertItemImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String get severity;
  @override
  String get title;
  @override
  String get message;
  @override
  DateTime get createdAt;
  @override
  DateTime? get readAt;

  /// Create a copy of AlertItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlertItemImplCopyWith<_$AlertItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BudgetItemStatus {
  String get budgetId => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  double get spent => throw _privateConstructorUsedError;
  double get remaining => throw _privateConstructorUsedError;
  double get percentUsed => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Create a copy of BudgetItemStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetItemStatusCopyWith<BudgetItemStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetItemStatusCopyWith<$Res> {
  factory $BudgetItemStatusCopyWith(
    BudgetItemStatus value,
    $Res Function(BudgetItemStatus) then,
  ) = _$BudgetItemStatusCopyWithImpl<$Res, BudgetItemStatus>;
  @useResult
  $Res call({
    String budgetId,
    String? categoryId,
    double amount,
    double spent,
    double remaining,
    double percentUsed,
    String status,
  });
}

/// @nodoc
class _$BudgetItemStatusCopyWithImpl<$Res, $Val extends BudgetItemStatus>
    implements $BudgetItemStatusCopyWith<$Res> {
  _$BudgetItemStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetItemStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? budgetId = null,
    Object? categoryId = freezed,
    Object? amount = null,
    Object? spent = null,
    Object? remaining = null,
    Object? percentUsed = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            budgetId: null == budgetId
                ? _value.budgetId
                : budgetId // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            spent: null == spent
                ? _value.spent
                : spent // ignore: cast_nullable_to_non_nullable
                      as double,
            remaining: null == remaining
                ? _value.remaining
                : remaining // ignore: cast_nullable_to_non_nullable
                      as double,
            percentUsed: null == percentUsed
                ? _value.percentUsed
                : percentUsed // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BudgetItemStatusImplCopyWith<$Res>
    implements $BudgetItemStatusCopyWith<$Res> {
  factory _$$BudgetItemStatusImplCopyWith(
    _$BudgetItemStatusImpl value,
    $Res Function(_$BudgetItemStatusImpl) then,
  ) = __$$BudgetItemStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String budgetId,
    String? categoryId,
    double amount,
    double spent,
    double remaining,
    double percentUsed,
    String status,
  });
}

/// @nodoc
class __$$BudgetItemStatusImplCopyWithImpl<$Res>
    extends _$BudgetItemStatusCopyWithImpl<$Res, _$BudgetItemStatusImpl>
    implements _$$BudgetItemStatusImplCopyWith<$Res> {
  __$$BudgetItemStatusImplCopyWithImpl(
    _$BudgetItemStatusImpl _value,
    $Res Function(_$BudgetItemStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BudgetItemStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? budgetId = null,
    Object? categoryId = freezed,
    Object? amount = null,
    Object? spent = null,
    Object? remaining = null,
    Object? percentUsed = null,
    Object? status = null,
  }) {
    return _then(
      _$BudgetItemStatusImpl(
        budgetId: null == budgetId
            ? _value.budgetId
            : budgetId // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        spent: null == spent
            ? _value.spent
            : spent // ignore: cast_nullable_to_non_nullable
                  as double,
        remaining: null == remaining
            ? _value.remaining
            : remaining // ignore: cast_nullable_to_non_nullable
                  as double,
        percentUsed: null == percentUsed
            ? _value.percentUsed
            : percentUsed // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$BudgetItemStatusImpl implements _BudgetItemStatus {
  const _$BudgetItemStatusImpl({
    this.budgetId = '',
    this.categoryId,
    this.amount = 0.0,
    this.spent = 0.0,
    this.remaining = 0.0,
    this.percentUsed = 0.0,
    this.status = 'on_track',
  });

  @override
  @JsonKey()
  final String budgetId;
  @override
  final String? categoryId;
  @override
  @JsonKey()
  final double amount;
  @override
  @JsonKey()
  final double spent;
  @override
  @JsonKey()
  final double remaining;
  @override
  @JsonKey()
  final double percentUsed;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'BudgetItemStatus(budgetId: $budgetId, categoryId: $categoryId, amount: $amount, spent: $spent, remaining: $remaining, percentUsed: $percentUsed, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetItemStatusImpl &&
            (identical(other.budgetId, budgetId) ||
                other.budgetId == budgetId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.spent, spent) || other.spent == spent) &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining) &&
            (identical(other.percentUsed, percentUsed) ||
                other.percentUsed == percentUsed) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    budgetId,
    categoryId,
    amount,
    spent,
    remaining,
    percentUsed,
    status,
  );

  /// Create a copy of BudgetItemStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetItemStatusImplCopyWith<_$BudgetItemStatusImpl> get copyWith =>
      __$$BudgetItemStatusImplCopyWithImpl<_$BudgetItemStatusImpl>(
        this,
        _$identity,
      );
}

abstract class _BudgetItemStatus implements BudgetItemStatus {
  const factory _BudgetItemStatus({
    final String budgetId,
    final String? categoryId,
    final double amount,
    final double spent,
    final double remaining,
    final double percentUsed,
    final String status,
  }) = _$BudgetItemStatusImpl;

  @override
  String get budgetId;
  @override
  String? get categoryId;
  @override
  double get amount;
  @override
  double get spent;
  @override
  double get remaining;
  @override
  double get percentUsed;
  @override
  String get status;

  /// Create a copy of BudgetItemStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetItemStatusImplCopyWith<_$BudgetItemStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BudgetStatus {
  String get month => throw _privateConstructorUsedError;
  double get totalBudget => throw _privateConstructorUsedError;
  double get totalSpent => throw _privateConstructorUsedError;
  double get overallPercent => throw _privateConstructorUsedError;
  int get budgetCount => throw _privateConstructorUsedError;
  List<BudgetItemStatus> get budgets => throw _privateConstructorUsedError;

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetStatusCopyWith<BudgetStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetStatusCopyWith<$Res> {
  factory $BudgetStatusCopyWith(
    BudgetStatus value,
    $Res Function(BudgetStatus) then,
  ) = _$BudgetStatusCopyWithImpl<$Res, BudgetStatus>;
  @useResult
  $Res call({
    String month,
    double totalBudget,
    double totalSpent,
    double overallPercent,
    int budgetCount,
    List<BudgetItemStatus> budgets,
  });
}

/// @nodoc
class _$BudgetStatusCopyWithImpl<$Res, $Val extends BudgetStatus>
    implements $BudgetStatusCopyWith<$Res> {
  _$BudgetStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? totalBudget = null,
    Object? totalSpent = null,
    Object? overallPercent = null,
    Object? budgetCount = null,
    Object? budgets = null,
  }) {
    return _then(
      _value.copyWith(
            month: null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
                      as String,
            totalBudget: null == totalBudget
                ? _value.totalBudget
                : totalBudget // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSpent: null == totalSpent
                ? _value.totalSpent
                : totalSpent // ignore: cast_nullable_to_non_nullable
                      as double,
            overallPercent: null == overallPercent
                ? _value.overallPercent
                : overallPercent // ignore: cast_nullable_to_non_nullable
                      as double,
            budgetCount: null == budgetCount
                ? _value.budgetCount
                : budgetCount // ignore: cast_nullable_to_non_nullable
                      as int,
            budgets: null == budgets
                ? _value.budgets
                : budgets // ignore: cast_nullable_to_non_nullable
                      as List<BudgetItemStatus>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BudgetStatusImplCopyWith<$Res>
    implements $BudgetStatusCopyWith<$Res> {
  factory _$$BudgetStatusImplCopyWith(
    _$BudgetStatusImpl value,
    $Res Function(_$BudgetStatusImpl) then,
  ) = __$$BudgetStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String month,
    double totalBudget,
    double totalSpent,
    double overallPercent,
    int budgetCount,
    List<BudgetItemStatus> budgets,
  });
}

/// @nodoc
class __$$BudgetStatusImplCopyWithImpl<$Res>
    extends _$BudgetStatusCopyWithImpl<$Res, _$BudgetStatusImpl>
    implements _$$BudgetStatusImplCopyWith<$Res> {
  __$$BudgetStatusImplCopyWithImpl(
    _$BudgetStatusImpl _value,
    $Res Function(_$BudgetStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? totalBudget = null,
    Object? totalSpent = null,
    Object? overallPercent = null,
    Object? budgetCount = null,
    Object? budgets = null,
  }) {
    return _then(
      _$BudgetStatusImpl(
        month: null == month
            ? _value.month
            : month // ignore: cast_nullable_to_non_nullable
                  as String,
        totalBudget: null == totalBudget
            ? _value.totalBudget
            : totalBudget // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSpent: null == totalSpent
            ? _value.totalSpent
            : totalSpent // ignore: cast_nullable_to_non_nullable
                  as double,
        overallPercent: null == overallPercent
            ? _value.overallPercent
            : overallPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        budgetCount: null == budgetCount
            ? _value.budgetCount
            : budgetCount // ignore: cast_nullable_to_non_nullable
                  as int,
        budgets: null == budgets
            ? _value._budgets
            : budgets // ignore: cast_nullable_to_non_nullable
                  as List<BudgetItemStatus>,
      ),
    );
  }
}

/// @nodoc

class _$BudgetStatusImpl implements _BudgetStatus {
  const _$BudgetStatusImpl({
    this.month = '',
    this.totalBudget = 0.0,
    this.totalSpent = 0.0,
    this.overallPercent = 0.0,
    this.budgetCount = 0,
    required final List<BudgetItemStatus> budgets,
  }) : _budgets = budgets;

  @override
  @JsonKey()
  final String month;
  @override
  @JsonKey()
  final double totalBudget;
  @override
  @JsonKey()
  final double totalSpent;
  @override
  @JsonKey()
  final double overallPercent;
  @override
  @JsonKey()
  final int budgetCount;
  final List<BudgetItemStatus> _budgets;
  @override
  List<BudgetItemStatus> get budgets {
    if (_budgets is EqualUnmodifiableListView) return _budgets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_budgets);
  }

  @override
  String toString() {
    return 'BudgetStatus(month: $month, totalBudget: $totalBudget, totalSpent: $totalSpent, overallPercent: $overallPercent, budgetCount: $budgetCount, budgets: $budgets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetStatusImpl &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalBudget, totalBudget) ||
                other.totalBudget == totalBudget) &&
            (identical(other.totalSpent, totalSpent) ||
                other.totalSpent == totalSpent) &&
            (identical(other.overallPercent, overallPercent) ||
                other.overallPercent == overallPercent) &&
            (identical(other.budgetCount, budgetCount) ||
                other.budgetCount == budgetCount) &&
            const DeepCollectionEquality().equals(other._budgets, _budgets));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    month,
    totalBudget,
    totalSpent,
    overallPercent,
    budgetCount,
    const DeepCollectionEquality().hash(_budgets),
  );

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetStatusImplCopyWith<_$BudgetStatusImpl> get copyWith =>
      __$$BudgetStatusImplCopyWithImpl<_$BudgetStatusImpl>(this, _$identity);
}

abstract class _BudgetStatus implements BudgetStatus {
  const factory _BudgetStatus({
    final String month,
    final double totalBudget,
    final double totalSpent,
    final double overallPercent,
    final int budgetCount,
    required final List<BudgetItemStatus> budgets,
  }) = _$BudgetStatusImpl;

  @override
  String get month;
  @override
  double get totalBudget;
  @override
  double get totalSpent;
  @override
  double get overallPercent;
  @override
  int get budgetCount;
  @override
  List<BudgetItemStatus> get budgets;

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetStatusImplCopyWith<_$BudgetStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
