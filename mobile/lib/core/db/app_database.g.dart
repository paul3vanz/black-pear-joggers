// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MembershipsTable extends Memberships
    with TableInfo<$MembershipsTable, Membership> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembershipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubNameMeta = const VerificationMeta(
    'clubName',
  );
  @override
  late final GeneratedColumn<String> clubName = GeneratedColumn<String>(
    'club_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubSlugMeta = const VerificationMeta(
    'clubSlug',
  );
  @override
  late final GeneratedColumn<String> clubSlug = GeneratedColumn<String>(
    'club_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinUrlMeta = const VerificationMeta(
    'joinUrl',
  );
  @override
  late final GeneratedColumn<String> joinUrl = GeneratedColumn<String>(
    'join_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolesJsonMeta = const VerificationMeta(
    'rolesJson',
  );
  @override
  late final GeneratedColumn<String> rolesJson = GeneratedColumn<String>(
    'roles_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _athleteIdMeta = const VerificationMeta(
    'athleteId',
  );
  @override
  late final GeneratedColumn<int> athleteId = GeneratedColumn<int>(
    'athlete_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    memberId,
    clubId,
    clubName,
    clubSlug,
    joinUrl,
    status,
    rolesJson,
    athleteId,
    firstName,
    lastName,
    gender,
    category,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memberships';
  @override
  VerificationContext validateIntegrity(
    Insertable<Membership> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('club_name')) {
      context.handle(
        _clubNameMeta,
        clubName.isAcceptableOrUnknown(data['club_name']!, _clubNameMeta),
      );
    } else if (isInserting) {
      context.missing(_clubNameMeta);
    }
    if (data.containsKey('club_slug')) {
      context.handle(
        _clubSlugMeta,
        clubSlug.isAcceptableOrUnknown(data['club_slug']!, _clubSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_clubSlugMeta);
    }
    if (data.containsKey('join_url')) {
      context.handle(
        _joinUrlMeta,
        joinUrl.isAcceptableOrUnknown(data['join_url']!, _joinUrlMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('roles_json')) {
      context.handle(
        _rolesJsonMeta,
        rolesJson.isAcceptableOrUnknown(data['roles_json']!, _rolesJsonMeta),
      );
    }
    if (data.containsKey('athlete_id')) {
      context.handle(
        _athleteIdMeta,
        athleteId.isAcceptableOrUnknown(data['athlete_id']!, _athleteIdMeta),
      );
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId};
  @override
  Membership map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Membership(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      clubName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_name'],
      )!,
      clubSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_slug'],
      )!,
      joinUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}join_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      rolesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roles_json'],
      )!,
      athleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}athlete_id'],
      ),
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MembershipsTable createAlias(String alias) {
    return $MembershipsTable(attachedDatabase, alias);
  }
}

class Membership extends DataClass implements Insertable<Membership> {
  final String memberId;
  final int clubId;
  final String clubName;
  final String clubSlug;
  final String? joinUrl;
  final String status;

  /// JSON array of role strings, e.g. `["leader"]`.
  final String rolesJson;
  final int? athleteId;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? category;
  final DateTime updatedAt;
  const Membership({
    required this.memberId,
    required this.clubId,
    required this.clubName,
    required this.clubSlug,
    this.joinUrl,
    required this.status,
    required this.rolesJson,
    this.athleteId,
    this.firstName,
    this.lastName,
    this.gender,
    this.category,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['club_id'] = Variable<int>(clubId);
    map['club_name'] = Variable<String>(clubName);
    map['club_slug'] = Variable<String>(clubSlug);
    if (!nullToAbsent || joinUrl != null) {
      map['join_url'] = Variable<String>(joinUrl);
    }
    map['status'] = Variable<String>(status);
    map['roles_json'] = Variable<String>(rolesJson);
    if (!nullToAbsent || athleteId != null) {
      map['athlete_id'] = Variable<int>(athleteId);
    }
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MembershipsCompanion toCompanion(bool nullToAbsent) {
    return MembershipsCompanion(
      memberId: Value(memberId),
      clubId: Value(clubId),
      clubName: Value(clubName),
      clubSlug: Value(clubSlug),
      joinUrl: joinUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(joinUrl),
      status: Value(status),
      rolesJson: Value(rolesJson),
      athleteId: athleteId == null && nullToAbsent
          ? const Value.absent()
          : Value(athleteId),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      updatedAt: Value(updatedAt),
    );
  }

  factory Membership.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Membership(
      memberId: serializer.fromJson<String>(json['memberId']),
      clubId: serializer.fromJson<int>(json['clubId']),
      clubName: serializer.fromJson<String>(json['clubName']),
      clubSlug: serializer.fromJson<String>(json['clubSlug']),
      joinUrl: serializer.fromJson<String?>(json['joinUrl']),
      status: serializer.fromJson<String>(json['status']),
      rolesJson: serializer.fromJson<String>(json['rolesJson']),
      athleteId: serializer.fromJson<int?>(json['athleteId']),
      firstName: serializer.fromJson<String?>(json['firstName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      gender: serializer.fromJson<String?>(json['gender']),
      category: serializer.fromJson<String?>(json['category']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'clubId': serializer.toJson<int>(clubId),
      'clubName': serializer.toJson<String>(clubName),
      'clubSlug': serializer.toJson<String>(clubSlug),
      'joinUrl': serializer.toJson<String?>(joinUrl),
      'status': serializer.toJson<String>(status),
      'rolesJson': serializer.toJson<String>(rolesJson),
      'athleteId': serializer.toJson<int?>(athleteId),
      'firstName': serializer.toJson<String?>(firstName),
      'lastName': serializer.toJson<String?>(lastName),
      'gender': serializer.toJson<String?>(gender),
      'category': serializer.toJson<String?>(category),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Membership copyWith({
    String? memberId,
    int? clubId,
    String? clubName,
    String? clubSlug,
    Value<String?> joinUrl = const Value.absent(),
    String? status,
    String? rolesJson,
    Value<int?> athleteId = const Value.absent(),
    Value<String?> firstName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<String?> category = const Value.absent(),
    DateTime? updatedAt,
  }) => Membership(
    memberId: memberId ?? this.memberId,
    clubId: clubId ?? this.clubId,
    clubName: clubName ?? this.clubName,
    clubSlug: clubSlug ?? this.clubSlug,
    joinUrl: joinUrl.present ? joinUrl.value : this.joinUrl,
    status: status ?? this.status,
    rolesJson: rolesJson ?? this.rolesJson,
    athleteId: athleteId.present ? athleteId.value : this.athleteId,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    gender: gender.present ? gender.value : this.gender,
    category: category.present ? category.value : this.category,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Membership copyWithCompanion(MembershipsCompanion data) {
    return Membership(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      clubName: data.clubName.present ? data.clubName.value : this.clubName,
      clubSlug: data.clubSlug.present ? data.clubSlug.value : this.clubSlug,
      joinUrl: data.joinUrl.present ? data.joinUrl.value : this.joinUrl,
      status: data.status.present ? data.status.value : this.status,
      rolesJson: data.rolesJson.present ? data.rolesJson.value : this.rolesJson,
      athleteId: data.athleteId.present ? data.athleteId.value : this.athleteId,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      gender: data.gender.present ? data.gender.value : this.gender,
      category: data.category.present ? data.category.value : this.category,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Membership(')
          ..write('memberId: $memberId, ')
          ..write('clubId: $clubId, ')
          ..write('clubName: $clubName, ')
          ..write('clubSlug: $clubSlug, ')
          ..write('joinUrl: $joinUrl, ')
          ..write('status: $status, ')
          ..write('rolesJson: $rolesJson, ')
          ..write('athleteId: $athleteId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('gender: $gender, ')
          ..write('category: $category, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    memberId,
    clubId,
    clubName,
    clubSlug,
    joinUrl,
    status,
    rolesJson,
    athleteId,
    firstName,
    lastName,
    gender,
    category,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Membership &&
          other.memberId == this.memberId &&
          other.clubId == this.clubId &&
          other.clubName == this.clubName &&
          other.clubSlug == this.clubSlug &&
          other.joinUrl == this.joinUrl &&
          other.status == this.status &&
          other.rolesJson == this.rolesJson &&
          other.athleteId == this.athleteId &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.gender == this.gender &&
          other.category == this.category &&
          other.updatedAt == this.updatedAt);
}

class MembershipsCompanion extends UpdateCompanion<Membership> {
  final Value<String> memberId;
  final Value<int> clubId;
  final Value<String> clubName;
  final Value<String> clubSlug;
  final Value<String?> joinUrl;
  final Value<String> status;
  final Value<String> rolesJson;
  final Value<int?> athleteId;
  final Value<String?> firstName;
  final Value<String?> lastName;
  final Value<String?> gender;
  final Value<String?> category;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MembershipsCompanion({
    this.memberId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.clubName = const Value.absent(),
    this.clubSlug = const Value.absent(),
    this.joinUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.rolesJson = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.gender = const Value.absent(),
    this.category = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembershipsCompanion.insert({
    required String memberId,
    required int clubId,
    required String clubName,
    required String clubSlug,
    this.joinUrl = const Value.absent(),
    required String status,
    this.rolesJson = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.gender = const Value.absent(),
    this.category = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       clubId = Value(clubId),
       clubName = Value(clubName),
       clubSlug = Value(clubSlug),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<Membership> custom({
    Expression<String>? memberId,
    Expression<int>? clubId,
    Expression<String>? clubName,
    Expression<String>? clubSlug,
    Expression<String>? joinUrl,
    Expression<String>? status,
    Expression<String>? rolesJson,
    Expression<int>? athleteId,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? gender,
    Expression<String>? category,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (clubId != null) 'club_id': clubId,
      if (clubName != null) 'club_name': clubName,
      if (clubSlug != null) 'club_slug': clubSlug,
      if (joinUrl != null) 'join_url': joinUrl,
      if (status != null) 'status': status,
      if (rolesJson != null) 'roles_json': rolesJson,
      if (athleteId != null) 'athlete_id': athleteId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (gender != null) 'gender': gender,
      if (category != null) 'category': category,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembershipsCompanion copyWith({
    Value<String>? memberId,
    Value<int>? clubId,
    Value<String>? clubName,
    Value<String>? clubSlug,
    Value<String?>? joinUrl,
    Value<String>? status,
    Value<String>? rolesJson,
    Value<int?>? athleteId,
    Value<String?>? firstName,
    Value<String?>? lastName,
    Value<String?>? gender,
    Value<String?>? category,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MembershipsCompanion(
      memberId: memberId ?? this.memberId,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      clubSlug: clubSlug ?? this.clubSlug,
      joinUrl: joinUrl ?? this.joinUrl,
      status: status ?? this.status,
      rolesJson: rolesJson ?? this.rolesJson,
      athleteId: athleteId ?? this.athleteId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (clubName.present) {
      map['club_name'] = Variable<String>(clubName.value);
    }
    if (clubSlug.present) {
      map['club_slug'] = Variable<String>(clubSlug.value);
    }
    if (joinUrl.present) {
      map['join_url'] = Variable<String>(joinUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rolesJson.present) {
      map['roles_json'] = Variable<String>(rolesJson.value);
    }
    if (athleteId.present) {
      map['athlete_id'] = Variable<int>(athleteId.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembershipsCompanion(')
          ..write('memberId: $memberId, ')
          ..write('clubId: $clubId, ')
          ..write('clubName: $clubName, ')
          ..write('clubSlug: $clubSlug, ')
          ..write('joinUrl: $joinUrl, ')
          ..write('status: $status, ')
          ..write('rolesJson: $rolesJson, ')
          ..write('athleteId: $athleteId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('gender: $gender, ')
          ..write('category: $category, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolesJsonMeta = const VerificationMeta(
    'rolesJson',
  );
  @override
  late final GeneratedColumn<String> rolesJson = GeneratedColumn<String>(
    'roles_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _athleteRowIdMeta = const VerificationMeta(
    'athleteRowId',
  );
  @override
  late final GeneratedColumn<int> athleteRowId = GeneratedColumn<int>(
    'athlete_row_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _athleteIdMeta = const VerificationMeta(
    'athleteId',
  );
  @override
  late final GeneratedColumn<int> athleteId = GeneratedColumn<int>(
    'athlete_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _po10GuidMeta = const VerificationMeta(
    'po10Guid',
  );
  @override
  late final GeneratedColumn<String> po10Guid = GeneratedColumn<String>(
    'po10_guid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _affiliatedMeta = const VerificationMeta(
    'affiliated',
  );
  @override
  late final GeneratedColumn<bool> affiliated = GeneratedColumn<bool>(
    'affiliated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("affiliated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _competitiveRegStatusMeta =
      const VerificationMeta('competitiveRegStatus');
  @override
  late final GeneratedColumn<String> competitiveRegStatus =
      GeneratedColumn<String>(
        'competitive_reg_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _firstClaimClubNameMeta =
      const VerificationMeta('firstClaimClubName');
  @override
  late final GeneratedColumn<String> firstClaimClubName =
      GeneratedColumn<String>(
        'first_claim_club_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resultsUrlMeta = const VerificationMeta(
    'resultsUrl',
  );
  @override
  late final GeneratedColumn<String> resultsUrl = GeneratedColumn<String>(
    'results_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerOf10UrlMeta = const VerificationMeta(
    'powerOf10Url',
  );
  @override
  late final GeneratedColumn<String> powerOf10Url = GeneratedColumn<String>(
    'power_of10_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _claimAwardUrlMeta = const VerificationMeta(
    'claimAwardUrl',
  );
  @override
  late final GeneratedColumn<String> claimAwardUrl = GeneratedColumn<String>(
    'claim_award_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    memberId,
    clubId,
    status,
    rolesJson,
    athleteRowId,
    athleteId,
    po10Guid,
    firstName,
    lastName,
    gender,
    category,
    active,
    affiliated,
    competitiveRegStatus,
    firstClaimClubName,
    resultsUrl,
    powerOf10Url,
    claimAwardUrl,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('roles_json')) {
      context.handle(
        _rolesJsonMeta,
        rolesJson.isAcceptableOrUnknown(data['roles_json']!, _rolesJsonMeta),
      );
    }
    if (data.containsKey('athlete_row_id')) {
      context.handle(
        _athleteRowIdMeta,
        athleteRowId.isAcceptableOrUnknown(
          data['athlete_row_id']!,
          _athleteRowIdMeta,
        ),
      );
    }
    if (data.containsKey('athlete_id')) {
      context.handle(
        _athleteIdMeta,
        athleteId.isAcceptableOrUnknown(data['athlete_id']!, _athleteIdMeta),
      );
    }
    if (data.containsKey('po10_guid')) {
      context.handle(
        _po10GuidMeta,
        po10Guid.isAcceptableOrUnknown(data['po10_guid']!, _po10GuidMeta),
      );
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('affiliated')) {
      context.handle(
        _affiliatedMeta,
        affiliated.isAcceptableOrUnknown(data['affiliated']!, _affiliatedMeta),
      );
    }
    if (data.containsKey('competitive_reg_status')) {
      context.handle(
        _competitiveRegStatusMeta,
        competitiveRegStatus.isAcceptableOrUnknown(
          data['competitive_reg_status']!,
          _competitiveRegStatusMeta,
        ),
      );
    }
    if (data.containsKey('first_claim_club_name')) {
      context.handle(
        _firstClaimClubNameMeta,
        firstClaimClubName.isAcceptableOrUnknown(
          data['first_claim_club_name']!,
          _firstClaimClubNameMeta,
        ),
      );
    }
    if (data.containsKey('results_url')) {
      context.handle(
        _resultsUrlMeta,
        resultsUrl.isAcceptableOrUnknown(data['results_url']!, _resultsUrlMeta),
      );
    }
    if (data.containsKey('power_of10_url')) {
      context.handle(
        _powerOf10UrlMeta,
        powerOf10Url.isAcceptableOrUnknown(
          data['power_of10_url']!,
          _powerOf10UrlMeta,
        ),
      );
    }
    if (data.containsKey('claim_award_url')) {
      context.handle(
        _claimAwardUrlMeta,
        claimAwardUrl.isAcceptableOrUnknown(
          data['claim_award_url']!,
          _claimAwardUrlMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      rolesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roles_json'],
      )!,
      athleteRowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}athlete_row_id'],
      ),
      athleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}athlete_id'],
      ),
      po10Guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}po10_guid'],
      ),
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      affiliated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}affiliated'],
      )!,
      competitiveRegStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competitive_reg_status'],
      ),
      firstClaimClubName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_claim_club_name'],
      ),
      resultsUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}results_url'],
      ),
      powerOf10Url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}power_of10_url'],
      ),
      claimAwardUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claim_award_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String memberId;
  final int clubId;
  final String status;
  final String rolesJson;
  final int? athleteRowId;
  final int? athleteId;
  final String? po10Guid;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? category;
  final bool active;
  final bool affiliated;
  final String? competitiveRegStatus;
  final String? firstClaimClubName;
  final String? resultsUrl;
  final String? powerOf10Url;
  final String? claimAwardUrl;
  final DateTime updatedAt;
  const Profile({
    required this.memberId,
    required this.clubId,
    required this.status,
    required this.rolesJson,
    this.athleteRowId,
    this.athleteId,
    this.po10Guid,
    this.firstName,
    this.lastName,
    this.gender,
    this.category,
    required this.active,
    required this.affiliated,
    this.competitiveRegStatus,
    this.firstClaimClubName,
    this.resultsUrl,
    this.powerOf10Url,
    this.claimAwardUrl,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['club_id'] = Variable<int>(clubId);
    map['status'] = Variable<String>(status);
    map['roles_json'] = Variable<String>(rolesJson);
    if (!nullToAbsent || athleteRowId != null) {
      map['athlete_row_id'] = Variable<int>(athleteRowId);
    }
    if (!nullToAbsent || athleteId != null) {
      map['athlete_id'] = Variable<int>(athleteId);
    }
    if (!nullToAbsent || po10Guid != null) {
      map['po10_guid'] = Variable<String>(po10Guid);
    }
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['active'] = Variable<bool>(active);
    map['affiliated'] = Variable<bool>(affiliated);
    if (!nullToAbsent || competitiveRegStatus != null) {
      map['competitive_reg_status'] = Variable<String>(competitiveRegStatus);
    }
    if (!nullToAbsent || firstClaimClubName != null) {
      map['first_claim_club_name'] = Variable<String>(firstClaimClubName);
    }
    if (!nullToAbsent || resultsUrl != null) {
      map['results_url'] = Variable<String>(resultsUrl);
    }
    if (!nullToAbsent || powerOf10Url != null) {
      map['power_of10_url'] = Variable<String>(powerOf10Url);
    }
    if (!nullToAbsent || claimAwardUrl != null) {
      map['claim_award_url'] = Variable<String>(claimAwardUrl);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      memberId: Value(memberId),
      clubId: Value(clubId),
      status: Value(status),
      rolesJson: Value(rolesJson),
      athleteRowId: athleteRowId == null && nullToAbsent
          ? const Value.absent()
          : Value(athleteRowId),
      athleteId: athleteId == null && nullToAbsent
          ? const Value.absent()
          : Value(athleteId),
      po10Guid: po10Guid == null && nullToAbsent
          ? const Value.absent()
          : Value(po10Guid),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      active: Value(active),
      affiliated: Value(affiliated),
      competitiveRegStatus: competitiveRegStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(competitiveRegStatus),
      firstClaimClubName: firstClaimClubName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstClaimClubName),
      resultsUrl: resultsUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(resultsUrl),
      powerOf10Url: powerOf10Url == null && nullToAbsent
          ? const Value.absent()
          : Value(powerOf10Url),
      claimAwardUrl: claimAwardUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(claimAwardUrl),
      updatedAt: Value(updatedAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      memberId: serializer.fromJson<String>(json['memberId']),
      clubId: serializer.fromJson<int>(json['clubId']),
      status: serializer.fromJson<String>(json['status']),
      rolesJson: serializer.fromJson<String>(json['rolesJson']),
      athleteRowId: serializer.fromJson<int?>(json['athleteRowId']),
      athleteId: serializer.fromJson<int?>(json['athleteId']),
      po10Guid: serializer.fromJson<String?>(json['po10Guid']),
      firstName: serializer.fromJson<String?>(json['firstName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      gender: serializer.fromJson<String?>(json['gender']),
      category: serializer.fromJson<String?>(json['category']),
      active: serializer.fromJson<bool>(json['active']),
      affiliated: serializer.fromJson<bool>(json['affiliated']),
      competitiveRegStatus: serializer.fromJson<String?>(
        json['competitiveRegStatus'],
      ),
      firstClaimClubName: serializer.fromJson<String?>(
        json['firstClaimClubName'],
      ),
      resultsUrl: serializer.fromJson<String?>(json['resultsUrl']),
      powerOf10Url: serializer.fromJson<String?>(json['powerOf10Url']),
      claimAwardUrl: serializer.fromJson<String?>(json['claimAwardUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'clubId': serializer.toJson<int>(clubId),
      'status': serializer.toJson<String>(status),
      'rolesJson': serializer.toJson<String>(rolesJson),
      'athleteRowId': serializer.toJson<int?>(athleteRowId),
      'athleteId': serializer.toJson<int?>(athleteId),
      'po10Guid': serializer.toJson<String?>(po10Guid),
      'firstName': serializer.toJson<String?>(firstName),
      'lastName': serializer.toJson<String?>(lastName),
      'gender': serializer.toJson<String?>(gender),
      'category': serializer.toJson<String?>(category),
      'active': serializer.toJson<bool>(active),
      'affiliated': serializer.toJson<bool>(affiliated),
      'competitiveRegStatus': serializer.toJson<String?>(competitiveRegStatus),
      'firstClaimClubName': serializer.toJson<String?>(firstClaimClubName),
      'resultsUrl': serializer.toJson<String?>(resultsUrl),
      'powerOf10Url': serializer.toJson<String?>(powerOf10Url),
      'claimAwardUrl': serializer.toJson<String?>(claimAwardUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Profile copyWith({
    String? memberId,
    int? clubId,
    String? status,
    String? rolesJson,
    Value<int?> athleteRowId = const Value.absent(),
    Value<int?> athleteId = const Value.absent(),
    Value<String?> po10Guid = const Value.absent(),
    Value<String?> firstName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<String?> category = const Value.absent(),
    bool? active,
    bool? affiliated,
    Value<String?> competitiveRegStatus = const Value.absent(),
    Value<String?> firstClaimClubName = const Value.absent(),
    Value<String?> resultsUrl = const Value.absent(),
    Value<String?> powerOf10Url = const Value.absent(),
    Value<String?> claimAwardUrl = const Value.absent(),
    DateTime? updatedAt,
  }) => Profile(
    memberId: memberId ?? this.memberId,
    clubId: clubId ?? this.clubId,
    status: status ?? this.status,
    rolesJson: rolesJson ?? this.rolesJson,
    athleteRowId: athleteRowId.present ? athleteRowId.value : this.athleteRowId,
    athleteId: athleteId.present ? athleteId.value : this.athleteId,
    po10Guid: po10Guid.present ? po10Guid.value : this.po10Guid,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    gender: gender.present ? gender.value : this.gender,
    category: category.present ? category.value : this.category,
    active: active ?? this.active,
    affiliated: affiliated ?? this.affiliated,
    competitiveRegStatus: competitiveRegStatus.present
        ? competitiveRegStatus.value
        : this.competitiveRegStatus,
    firstClaimClubName: firstClaimClubName.present
        ? firstClaimClubName.value
        : this.firstClaimClubName,
    resultsUrl: resultsUrl.present ? resultsUrl.value : this.resultsUrl,
    powerOf10Url: powerOf10Url.present ? powerOf10Url.value : this.powerOf10Url,
    claimAwardUrl: claimAwardUrl.present
        ? claimAwardUrl.value
        : this.claimAwardUrl,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      status: data.status.present ? data.status.value : this.status,
      rolesJson: data.rolesJson.present ? data.rolesJson.value : this.rolesJson,
      athleteRowId: data.athleteRowId.present
          ? data.athleteRowId.value
          : this.athleteRowId,
      athleteId: data.athleteId.present ? data.athleteId.value : this.athleteId,
      po10Guid: data.po10Guid.present ? data.po10Guid.value : this.po10Guid,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      gender: data.gender.present ? data.gender.value : this.gender,
      category: data.category.present ? data.category.value : this.category,
      active: data.active.present ? data.active.value : this.active,
      affiliated: data.affiliated.present
          ? data.affiliated.value
          : this.affiliated,
      competitiveRegStatus: data.competitiveRegStatus.present
          ? data.competitiveRegStatus.value
          : this.competitiveRegStatus,
      firstClaimClubName: data.firstClaimClubName.present
          ? data.firstClaimClubName.value
          : this.firstClaimClubName,
      resultsUrl: data.resultsUrl.present
          ? data.resultsUrl.value
          : this.resultsUrl,
      powerOf10Url: data.powerOf10Url.present
          ? data.powerOf10Url.value
          : this.powerOf10Url,
      claimAwardUrl: data.claimAwardUrl.present
          ? data.claimAwardUrl.value
          : this.claimAwardUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('memberId: $memberId, ')
          ..write('clubId: $clubId, ')
          ..write('status: $status, ')
          ..write('rolesJson: $rolesJson, ')
          ..write('athleteRowId: $athleteRowId, ')
          ..write('athleteId: $athleteId, ')
          ..write('po10Guid: $po10Guid, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('gender: $gender, ')
          ..write('category: $category, ')
          ..write('active: $active, ')
          ..write('affiliated: $affiliated, ')
          ..write('competitiveRegStatus: $competitiveRegStatus, ')
          ..write('firstClaimClubName: $firstClaimClubName, ')
          ..write('resultsUrl: $resultsUrl, ')
          ..write('powerOf10Url: $powerOf10Url, ')
          ..write('claimAwardUrl: $claimAwardUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    memberId,
    clubId,
    status,
    rolesJson,
    athleteRowId,
    athleteId,
    po10Guid,
    firstName,
    lastName,
    gender,
    category,
    active,
    affiliated,
    competitiveRegStatus,
    firstClaimClubName,
    resultsUrl,
    powerOf10Url,
    claimAwardUrl,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.memberId == this.memberId &&
          other.clubId == this.clubId &&
          other.status == this.status &&
          other.rolesJson == this.rolesJson &&
          other.athleteRowId == this.athleteRowId &&
          other.athleteId == this.athleteId &&
          other.po10Guid == this.po10Guid &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.gender == this.gender &&
          other.category == this.category &&
          other.active == this.active &&
          other.affiliated == this.affiliated &&
          other.competitiveRegStatus == this.competitiveRegStatus &&
          other.firstClaimClubName == this.firstClaimClubName &&
          other.resultsUrl == this.resultsUrl &&
          other.powerOf10Url == this.powerOf10Url &&
          other.claimAwardUrl == this.claimAwardUrl &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> memberId;
  final Value<int> clubId;
  final Value<String> status;
  final Value<String> rolesJson;
  final Value<int?> athleteRowId;
  final Value<int?> athleteId;
  final Value<String?> po10Guid;
  final Value<String?> firstName;
  final Value<String?> lastName;
  final Value<String?> gender;
  final Value<String?> category;
  final Value<bool> active;
  final Value<bool> affiliated;
  final Value<String?> competitiveRegStatus;
  final Value<String?> firstClaimClubName;
  final Value<String?> resultsUrl;
  final Value<String?> powerOf10Url;
  final Value<String?> claimAwardUrl;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.memberId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.status = const Value.absent(),
    this.rolesJson = const Value.absent(),
    this.athleteRowId = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.po10Guid = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.gender = const Value.absent(),
    this.category = const Value.absent(),
    this.active = const Value.absent(),
    this.affiliated = const Value.absent(),
    this.competitiveRegStatus = const Value.absent(),
    this.firstClaimClubName = const Value.absent(),
    this.resultsUrl = const Value.absent(),
    this.powerOf10Url = const Value.absent(),
    this.claimAwardUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String memberId,
    required int clubId,
    required String status,
    this.rolesJson = const Value.absent(),
    this.athleteRowId = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.po10Guid = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.gender = const Value.absent(),
    this.category = const Value.absent(),
    this.active = const Value.absent(),
    this.affiliated = const Value.absent(),
    this.competitiveRegStatus = const Value.absent(),
    this.firstClaimClubName = const Value.absent(),
    this.resultsUrl = const Value.absent(),
    this.powerOf10Url = const Value.absent(),
    this.claimAwardUrl = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       clubId = Value(clubId),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<Profile> custom({
    Expression<String>? memberId,
    Expression<int>? clubId,
    Expression<String>? status,
    Expression<String>? rolesJson,
    Expression<int>? athleteRowId,
    Expression<int>? athleteId,
    Expression<String>? po10Guid,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? gender,
    Expression<String>? category,
    Expression<bool>? active,
    Expression<bool>? affiliated,
    Expression<String>? competitiveRegStatus,
    Expression<String>? firstClaimClubName,
    Expression<String>? resultsUrl,
    Expression<String>? powerOf10Url,
    Expression<String>? claimAwardUrl,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (clubId != null) 'club_id': clubId,
      if (status != null) 'status': status,
      if (rolesJson != null) 'roles_json': rolesJson,
      if (athleteRowId != null) 'athlete_row_id': athleteRowId,
      if (athleteId != null) 'athlete_id': athleteId,
      if (po10Guid != null) 'po10_guid': po10Guid,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (gender != null) 'gender': gender,
      if (category != null) 'category': category,
      if (active != null) 'active': active,
      if (affiliated != null) 'affiliated': affiliated,
      if (competitiveRegStatus != null)
        'competitive_reg_status': competitiveRegStatus,
      if (firstClaimClubName != null)
        'first_claim_club_name': firstClaimClubName,
      if (resultsUrl != null) 'results_url': resultsUrl,
      if (powerOf10Url != null) 'power_of10_url': powerOf10Url,
      if (claimAwardUrl != null) 'claim_award_url': claimAwardUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? memberId,
    Value<int>? clubId,
    Value<String>? status,
    Value<String>? rolesJson,
    Value<int?>? athleteRowId,
    Value<int?>? athleteId,
    Value<String?>? po10Guid,
    Value<String?>? firstName,
    Value<String?>? lastName,
    Value<String?>? gender,
    Value<String?>? category,
    Value<bool>? active,
    Value<bool>? affiliated,
    Value<String?>? competitiveRegStatus,
    Value<String?>? firstClaimClubName,
    Value<String?>? resultsUrl,
    Value<String?>? powerOf10Url,
    Value<String?>? claimAwardUrl,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      memberId: memberId ?? this.memberId,
      clubId: clubId ?? this.clubId,
      status: status ?? this.status,
      rolesJson: rolesJson ?? this.rolesJson,
      athleteRowId: athleteRowId ?? this.athleteRowId,
      athleteId: athleteId ?? this.athleteId,
      po10Guid: po10Guid ?? this.po10Guid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      active: active ?? this.active,
      affiliated: affiliated ?? this.affiliated,
      competitiveRegStatus: competitiveRegStatus ?? this.competitiveRegStatus,
      firstClaimClubName: firstClaimClubName ?? this.firstClaimClubName,
      resultsUrl: resultsUrl ?? this.resultsUrl,
      powerOf10Url: powerOf10Url ?? this.powerOf10Url,
      claimAwardUrl: claimAwardUrl ?? this.claimAwardUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rolesJson.present) {
      map['roles_json'] = Variable<String>(rolesJson.value);
    }
    if (athleteRowId.present) {
      map['athlete_row_id'] = Variable<int>(athleteRowId.value);
    }
    if (athleteId.present) {
      map['athlete_id'] = Variable<int>(athleteId.value);
    }
    if (po10Guid.present) {
      map['po10_guid'] = Variable<String>(po10Guid.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (affiliated.present) {
      map['affiliated'] = Variable<bool>(affiliated.value);
    }
    if (competitiveRegStatus.present) {
      map['competitive_reg_status'] = Variable<String>(
        competitiveRegStatus.value,
      );
    }
    if (firstClaimClubName.present) {
      map['first_claim_club_name'] = Variable<String>(firstClaimClubName.value);
    }
    if (resultsUrl.present) {
      map['results_url'] = Variable<String>(resultsUrl.value);
    }
    if (powerOf10Url.present) {
      map['power_of10_url'] = Variable<String>(powerOf10Url.value);
    }
    if (claimAwardUrl.present) {
      map['claim_award_url'] = Variable<String>(claimAwardUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('memberId: $memberId, ')
          ..write('clubId: $clubId, ')
          ..write('status: $status, ')
          ..write('rolesJson: $rolesJson, ')
          ..write('athleteRowId: $athleteRowId, ')
          ..write('athleteId: $athleteId, ')
          ..write('po10Guid: $po10Guid, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('gender: $gender, ')
          ..write('category: $category, ')
          ..write('active: $active, ')
          ..write('affiliated: $affiliated, ')
          ..write('competitiveRegStatus: $competitiveRegStatus, ')
          ..write('firstClaimClubName: $firstClaimClubName, ')
          ..write('resultsUrl: $resultsUrl, ')
          ..write('powerOf10Url: $powerOf10Url, ')
          ..write('claimAwardUrl: $claimAwardUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PostsTable extends Posts with TableInfo<$PostsTable, Post> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMdMeta = const VerificationMeta('bodyMd');
  @override
  late final GeneratedColumn<String> bodyMd = GeneratedColumn<String>(
    'body_md',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _audienceMeta = const VerificationMeta(
    'audience',
  );
  @override
  late final GeneratedColumn<String> audience = GeneratedColumn<String>(
    'audience',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('all'),
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedUntilMeta = const VerificationMeta(
    'pinnedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> pinnedUntil = GeneratedColumn<DateTime>(
    'pinned_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMemberIdMeta = const VerificationMeta(
    'authorMemberId',
  );
  @override
  late final GeneratedColumn<String> authorMemberId = GeneratedColumn<String>(
    'author_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    title,
    bodyMd,
    priority,
    audience,
    publishedAt,
    pinnedUntil,
    authorMemberId,
    authorName,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'posts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Post> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body_md')) {
      context.handle(
        _bodyMdMeta,
        bodyMd.isAcceptableOrUnknown(data['body_md']!, _bodyMdMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMdMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('audience')) {
      context.handle(
        _audienceMeta,
        audience.isAcceptableOrUnknown(data['audience']!, _audienceMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('pinned_until')) {
      context.handle(
        _pinnedUntilMeta,
        pinnedUntil.isAcceptableOrUnknown(
          data['pinned_until']!,
          _pinnedUntilMeta,
        ),
      );
    }
    if (data.containsKey('author_member_id')) {
      context.handle(
        _authorMemberIdMeta,
        authorMemberId.isAcceptableOrUnknown(
          data['author_member_id']!,
          _authorMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authorMemberIdMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Post map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Post(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      bodyMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_md'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      audience: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audience'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      )!,
      pinnedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pinned_until'],
      ),
      authorMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_member_id'],
      )!,
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PostsTable createAlias(String alias) {
    return $PostsTable(attachedDatabase, alias);
  }
}

class Post extends DataClass implements Insertable<Post> {
  final String id;
  final int clubId;
  final String title;
  final String bodyMd;

  /// `normal` | `important`.
  final String priority;

  /// `all` | `leaders` | `committee`.
  final String audience;
  final DateTime publishedAt;
  final DateTime? pinnedUntil;
  final String authorMemberId;
  final String authorName;
  final DateTime updatedAt;
  const Post({
    required this.id,
    required this.clubId,
    required this.title,
    required this.bodyMd,
    required this.priority,
    required this.audience,
    required this.publishedAt,
    this.pinnedUntil,
    required this.authorMemberId,
    required this.authorName,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<int>(clubId);
    map['title'] = Variable<String>(title);
    map['body_md'] = Variable<String>(bodyMd);
    map['priority'] = Variable<String>(priority);
    map['audience'] = Variable<String>(audience);
    map['published_at'] = Variable<DateTime>(publishedAt);
    if (!nullToAbsent || pinnedUntil != null) {
      map['pinned_until'] = Variable<DateTime>(pinnedUntil);
    }
    map['author_member_id'] = Variable<String>(authorMemberId);
    map['author_name'] = Variable<String>(authorName);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PostsCompanion toCompanion(bool nullToAbsent) {
    return PostsCompanion(
      id: Value(id),
      clubId: Value(clubId),
      title: Value(title),
      bodyMd: Value(bodyMd),
      priority: Value(priority),
      audience: Value(audience),
      publishedAt: Value(publishedAt),
      pinnedUntil: pinnedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedUntil),
      authorMemberId: Value(authorMemberId),
      authorName: Value(authorName),
      updatedAt: Value(updatedAt),
    );
  }

  factory Post.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Post(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<int>(json['clubId']),
      title: serializer.fromJson<String>(json['title']),
      bodyMd: serializer.fromJson<String>(json['bodyMd']),
      priority: serializer.fromJson<String>(json['priority']),
      audience: serializer.fromJson<String>(json['audience']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      pinnedUntil: serializer.fromJson<DateTime?>(json['pinnedUntil']),
      authorMemberId: serializer.fromJson<String>(json['authorMemberId']),
      authorName: serializer.fromJson<String>(json['authorName']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<int>(clubId),
      'title': serializer.toJson<String>(title),
      'bodyMd': serializer.toJson<String>(bodyMd),
      'priority': serializer.toJson<String>(priority),
      'audience': serializer.toJson<String>(audience),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'pinnedUntil': serializer.toJson<DateTime?>(pinnedUntil),
      'authorMemberId': serializer.toJson<String>(authorMemberId),
      'authorName': serializer.toJson<String>(authorName),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Post copyWith({
    String? id,
    int? clubId,
    String? title,
    String? bodyMd,
    String? priority,
    String? audience,
    DateTime? publishedAt,
    Value<DateTime?> pinnedUntil = const Value.absent(),
    String? authorMemberId,
    String? authorName,
    DateTime? updatedAt,
  }) => Post(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    title: title ?? this.title,
    bodyMd: bodyMd ?? this.bodyMd,
    priority: priority ?? this.priority,
    audience: audience ?? this.audience,
    publishedAt: publishedAt ?? this.publishedAt,
    pinnedUntil: pinnedUntil.present ? pinnedUntil.value : this.pinnedUntil,
    authorMemberId: authorMemberId ?? this.authorMemberId,
    authorName: authorName ?? this.authorName,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Post copyWithCompanion(PostsCompanion data) {
    return Post(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      title: data.title.present ? data.title.value : this.title,
      bodyMd: data.bodyMd.present ? data.bodyMd.value : this.bodyMd,
      priority: data.priority.present ? data.priority.value : this.priority,
      audience: data.audience.present ? data.audience.value : this.audience,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      pinnedUntil: data.pinnedUntil.present
          ? data.pinnedUntil.value
          : this.pinnedUntil,
      authorMemberId: data.authorMemberId.present
          ? data.authorMemberId.value
          : this.authorMemberId,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Post(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('title: $title, ')
          ..write('bodyMd: $bodyMd, ')
          ..write('priority: $priority, ')
          ..write('audience: $audience, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('pinnedUntil: $pinnedUntil, ')
          ..write('authorMemberId: $authorMemberId, ')
          ..write('authorName: $authorName, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    title,
    bodyMd,
    priority,
    audience,
    publishedAt,
    pinnedUntil,
    authorMemberId,
    authorName,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Post &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.title == this.title &&
          other.bodyMd == this.bodyMd &&
          other.priority == this.priority &&
          other.audience == this.audience &&
          other.publishedAt == this.publishedAt &&
          other.pinnedUntil == this.pinnedUntil &&
          other.authorMemberId == this.authorMemberId &&
          other.authorName == this.authorName &&
          other.updatedAt == this.updatedAt);
}

class PostsCompanion extends UpdateCompanion<Post> {
  final Value<String> id;
  final Value<int> clubId;
  final Value<String> title;
  final Value<String> bodyMd;
  final Value<String> priority;
  final Value<String> audience;
  final Value<DateTime> publishedAt;
  final Value<DateTime?> pinnedUntil;
  final Value<String> authorMemberId;
  final Value<String> authorName;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PostsCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.title = const Value.absent(),
    this.bodyMd = const Value.absent(),
    this.priority = const Value.absent(),
    this.audience = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.pinnedUntil = const Value.absent(),
    this.authorMemberId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PostsCompanion.insert({
    required String id,
    required int clubId,
    required String title,
    required String bodyMd,
    this.priority = const Value.absent(),
    this.audience = const Value.absent(),
    required DateTime publishedAt,
    this.pinnedUntil = const Value.absent(),
    required String authorMemberId,
    required String authorName,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       title = Value(title),
       bodyMd = Value(bodyMd),
       publishedAt = Value(publishedAt),
       authorMemberId = Value(authorMemberId),
       authorName = Value(authorName),
       updatedAt = Value(updatedAt);
  static Insertable<Post> custom({
    Expression<String>? id,
    Expression<int>? clubId,
    Expression<String>? title,
    Expression<String>? bodyMd,
    Expression<String>? priority,
    Expression<String>? audience,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? pinnedUntil,
    Expression<String>? authorMemberId,
    Expression<String>? authorName,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (title != null) 'title': title,
      if (bodyMd != null) 'body_md': bodyMd,
      if (priority != null) 'priority': priority,
      if (audience != null) 'audience': audience,
      if (publishedAt != null) 'published_at': publishedAt,
      if (pinnedUntil != null) 'pinned_until': pinnedUntil,
      if (authorMemberId != null) 'author_member_id': authorMemberId,
      if (authorName != null) 'author_name': authorName,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PostsCompanion copyWith({
    Value<String>? id,
    Value<int>? clubId,
    Value<String>? title,
    Value<String>? bodyMd,
    Value<String>? priority,
    Value<String>? audience,
    Value<DateTime>? publishedAt,
    Value<DateTime?>? pinnedUntil,
    Value<String>? authorMemberId,
    Value<String>? authorName,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PostsCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      title: title ?? this.title,
      bodyMd: bodyMd ?? this.bodyMd,
      priority: priority ?? this.priority,
      audience: audience ?? this.audience,
      publishedAt: publishedAt ?? this.publishedAt,
      pinnedUntil: pinnedUntil ?? this.pinnedUntil,
      authorMemberId: authorMemberId ?? this.authorMemberId,
      authorName: authorName ?? this.authorName,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (bodyMd.present) {
      map['body_md'] = Variable<String>(bodyMd.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (audience.present) {
      map['audience'] = Variable<String>(audience.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (pinnedUntil.present) {
      map['pinned_until'] = Variable<DateTime>(pinnedUntil.value);
    }
    if (authorMemberId.present) {
      map['author_member_id'] = Variable<String>(authorMemberId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostsCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('title: $title, ')
          ..write('bodyMd: $bodyMd, ')
          ..write('priority: $priority, ')
          ..write('audience: $audience, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('pinnedUntil: $pinnedUntil, ')
          ..write('authorMemberId: $authorMemberId, ')
          ..write('authorName: $authorName, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InboxItemsTable extends InboxItems
    with TableInfo<$InboxItemsTable, InboxItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InboxItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readPendingMeta = const VerificationMeta(
    'readPending',
  );
  @override
  late final GeneratedColumn<bool> readPending = GeneratedColumn<bool>(
    'read_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    category,
    title,
    body,
    dataJson,
    createdAt,
    readAt,
    readPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbox_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InboxItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('read_pending')) {
      context.handle(
        _readPendingMeta,
        readPending.isAcceptableOrUnknown(
          data['read_pending']!,
          _readPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InboxItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InboxItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      readPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read_pending'],
      )!,
    );
  }

  @override
  $InboxItemsTable createAlias(String alias) {
    return $InboxItemsTable(attachedDatabase, alias);
  }
}

class InboxItem extends DataClass implements Insertable<InboxItem> {
  final String id;
  final int clubId;
  final String category;
  final String title;
  final String body;

  /// JSON object, e.g. `{"route":"/updates/<postId>"}`.
  final String dataJson;
  final DateTime createdAt;
  final DateTime? readAt;

  /// True while a local "mark read" hasn't reached the server yet. The next refresh
  /// retries it. Cleared once the POST succeeds.
  final bool readPending;
  const InboxItem({
    required this.id,
    required this.clubId,
    required this.category,
    required this.title,
    required this.body,
    required this.dataJson,
    required this.createdAt,
    this.readAt,
    required this.readPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<int>(clubId);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['data_json'] = Variable<String>(dataJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    map['read_pending'] = Variable<bool>(readPending);
    return map;
  }

  InboxItemsCompanion toCompanion(bool nullToAbsent) {
    return InboxItemsCompanion(
      id: Value(id),
      clubId: Value(clubId),
      category: Value(category),
      title: Value(title),
      body: Value(body),
      dataJson: Value(dataJson),
      createdAt: Value(createdAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      readPending: Value(readPending),
    );
  }

  factory InboxItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InboxItem(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<int>(json['clubId']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      readPending: serializer.fromJson<bool>(json['readPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<int>(clubId),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'dataJson': serializer.toJson<String>(dataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'readPending': serializer.toJson<bool>(readPending),
    };
  }

  InboxItem copyWith({
    String? id,
    int? clubId,
    String? category,
    String? title,
    String? body,
    String? dataJson,
    DateTime? createdAt,
    Value<DateTime?> readAt = const Value.absent(),
    bool? readPending,
  }) => InboxItem(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    category: category ?? this.category,
    title: title ?? this.title,
    body: body ?? this.body,
    dataJson: dataJson ?? this.dataJson,
    createdAt: createdAt ?? this.createdAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    readPending: readPending ?? this.readPending,
  );
  InboxItem copyWithCompanion(InboxItemsCompanion data) {
    return InboxItem(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      readPending: data.readPending.present
          ? data.readPending.value
          : this.readPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InboxItem(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('readPending: $readPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    category,
    title,
    body,
    dataJson,
    createdAt,
    readAt,
    readPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InboxItem &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.category == this.category &&
          other.title == this.title &&
          other.body == this.body &&
          other.dataJson == this.dataJson &&
          other.createdAt == this.createdAt &&
          other.readAt == this.readAt &&
          other.readPending == this.readPending);
}

class InboxItemsCompanion extends UpdateCompanion<InboxItem> {
  final Value<String> id;
  final Value<int> clubId;
  final Value<String> category;
  final Value<String> title;
  final Value<String> body;
  final Value<String> dataJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> readAt;
  final Value<bool> readPending;
  final Value<int> rowid;
  const InboxItemsCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.readPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InboxItemsCompanion.insert({
    required String id,
    required int clubId,
    required String category,
    required String title,
    required String body,
    this.dataJson = const Value.absent(),
    required DateTime createdAt,
    this.readAt = const Value.absent(),
    this.readPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       category = Value(category),
       title = Value(title),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<InboxItem> custom({
    Expression<String>? id,
    Expression<int>? clubId,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? dataJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? readAt,
    Expression<bool>? readPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (dataJson != null) 'data_json': dataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (readAt != null) 'read_at': readAt,
      if (readPending != null) 'read_pending': readPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InboxItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? clubId,
    Value<String>? category,
    Value<String>? title,
    Value<String>? body,
    Value<String>? dataJson,
    Value<DateTime>? createdAt,
    Value<DateTime?>? readAt,
    Value<bool>? readPending,
    Value<int>? rowid,
  }) {
    return InboxItemsCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      dataJson: dataJson ?? this.dataJson,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      readPending: readPending ?? this.readPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (readPending.present) {
      map['read_pending'] = Variable<bool>(readPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InboxItemsCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('readPending: $readPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverTimeMeta = const VerificationMeta(
    'serverTime',
  );
  @override
  late final GeneratedColumn<String> serverTime = GeneratedColumn<String>(
    'server_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, serverTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('server_time')) {
      context.handle(
        _serverTimeMeta,
        serverTime.isAcceptableOrUnknown(data['server_time']!, _serverTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_serverTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      serverTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_time'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String key;
  final String serverTime;
  const SyncCursor({required this.key, required this.serverTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['server_time'] = Variable<String>(serverTime);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(key: Value(key), serverTime: Value(serverTime));
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      key: serializer.fromJson<String>(json['key']),
      serverTime: serializer.fromJson<String>(json['serverTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'serverTime': serializer.toJson<String>(serverTime),
    };
  }

  SyncCursor copyWith({String? key, String? serverTime}) => SyncCursor(
    key: key ?? this.key,
    serverTime: serverTime ?? this.serverTime,
  );
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      key: data.key.present ? data.key.value : this.key,
      serverTime: data.serverTime.present
          ? data.serverTime.value
          : this.serverTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('key: $key, ')
          ..write('serverTime: $serverTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, serverTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.key == this.key &&
          other.serverTime == this.serverTime);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> key;
  final Value<String> serverTime;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.key = const Value.absent(),
    this.serverTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String key,
    required String serverTime,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       serverTime = Value(serverTime);
  static Insertable<SyncCursor> custom({
    Expression<String>? key,
    Expression<String>? serverTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (serverTime != null) 'server_time': serverTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? key,
    Value<String>? serverTime,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      key: key ?? this.key,
      serverTime: serverTime ?? this.serverTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (serverTime.present) {
      map['server_time'] = Variable<String>(serverTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('key: $key, ')
          ..write('serverTime: $serverTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VenuesTable extends Venues with TableInfo<$VenuesTable, Venue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VenuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    name,
    address,
    lat,
    lng,
    notes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'venues';
  @override
  VerificationContext validateIntegrity(
    Insertable<Venue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Venue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Venue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VenuesTable createAlias(String alias) {
    return $VenuesTable(attachedDatabase, alias);
  }
}

class Venue extends DataClass implements Insertable<Venue> {
  final String id;
  final int clubId;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final String? notes;
  final DateTime updatedAt;
  const Venue({
    required this.id,
    required this.clubId,
    required this.name,
    this.address,
    this.lat,
    this.lng,
    this.notes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<int>(clubId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VenuesCompanion toCompanion(bool nullToAbsent) {
    return VenuesCompanion(
      id: Value(id),
      clubId: Value(clubId),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      updatedAt: Value(updatedAt),
    );
  }

  factory Venue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Venue(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<int>(json['clubId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      notes: serializer.fromJson<String?>(json['notes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<int>(clubId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'notes': serializer.toJson<String?>(notes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Venue copyWith({
    String? id,
    int? clubId,
    String? name,
    Value<String?> address = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? updatedAt,
  }) => Venue(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    name: name ?? this.name,
    address: address.present ? address.value : this.address,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    notes: notes.present ? notes.value : this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Venue copyWithCompanion(VenuesCompanion data) {
    return Venue(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      notes: data.notes.present ? data.notes.value : this.notes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Venue(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, clubId, name, address, lat, lng, notes, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Venue &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.name == this.name &&
          other.address == this.address &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.notes == this.notes &&
          other.updatedAt == this.updatedAt);
}

class VenuesCompanion extends UpdateCompanion<Venue> {
  final Value<String> id;
  final Value<int> clubId;
  final Value<String> name;
  final Value<String?> address;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<String?> notes;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VenuesCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VenuesCompanion.insert({
    required String id,
    required int clubId,
    required String name,
    this.address = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<Venue> custom({
    Expression<String>? id,
    Expression<int>? clubId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? notes,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VenuesCompanion copyWith({
    Value<String>? id,
    Value<int>? clubId,
    Value<String>? name,
    Value<String?>? address,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<String?>? notes,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VenuesCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VenuesCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionSeriesTable extends SessionSeries
    with TableInfo<$SessionSeriesTable, RunSeries> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionSeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _venueIdMeta = const VerificationMeta(
    'venueId',
  );
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
    'venue_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalWeeksMeta = const VerificationMeta(
    'intervalWeeks',
  );
  @override
  late final GeneratedColumn<int> intervalWeeks = GeneratedColumn<int>(
    'interval_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<String> validFrom = GeneratedColumn<String>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validUntilMeta = const VerificationMeta(
    'validUntil',
  );
  @override
  late final GeneratedColumn<String> validUntil = GeneratedColumn<String>(
    'valid_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupModeMeta = const VerificationMeta(
    'groupMode',
  );
  @override
  late final GeneratedColumn<String> groupMode = GeneratedColumn<String>(
    'group_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cmsSlugMeta = const VerificationMeta(
    'cmsSlug',
  );
  @override
  late final GeneratedColumn<String> cmsSlug = GeneratedColumn<String>(
    'cms_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    title,
    description,
    venueId,
    weekday,
    startTime,
    durationMin,
    intervalWeeks,
    validFrom,
    validUntil,
    groupMode,
    cmsSlug,
    imageUrl,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_series';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunSeries> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('venue_id')) {
      context.handle(
        _venueIdMeta,
        venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    }
    if (data.containsKey('interval_weeks')) {
      context.handle(
        _intervalWeeksMeta,
        intervalWeeks.isAcceptableOrUnknown(
          data['interval_weeks']!,
          _intervalWeeksMeta,
        ),
      );
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('valid_until')) {
      context.handle(
        _validUntilMeta,
        validUntil.isAcceptableOrUnknown(data['valid_until']!, _validUntilMeta),
      );
    }
    if (data.containsKey('group_mode')) {
      context.handle(
        _groupModeMeta,
        groupMode.isAcceptableOrUnknown(data['group_mode']!, _groupModeMeta),
      );
    } else if (isInserting) {
      context.missing(_groupModeMeta);
    }
    if (data.containsKey('cms_slug')) {
      context.handle(
        _cmsSlugMeta,
        cmsSlug.isAcceptableOrUnknown(data['cms_slug']!, _cmsSlugMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunSeries map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunSeries(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      venueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue_id'],
      ),
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      ),
      intervalWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_weeks'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_from'],
      )!,
      validUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_until'],
      ),
      groupMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_mode'],
      )!,
      cmsSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cms_slug'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SessionSeriesTable createAlias(String alias) {
    return $SessionSeriesTable(attachedDatabase, alias);
  }
}

class RunSeries extends DataClass implements Insertable<RunSeries> {
  final String id;
  final int clubId;
  final String title;
  final String? description;
  final String? venueId;

  /// ISO weekday, 1 = Monday ... 7 = Sunday.
  final int weekday;
  final String startTime;

  /// Null = the run has no fixed end time (D47).
  final int? durationMin;
  final int intervalWeeks;
  final String validFrom;
  final String? validUntil;

  /// `paced` | `single` | `open` | `routes`.
  final String groupMode;
  final String? cmsSlug;

  /// Optional banner image URL (D49).
  final String? imageUrl;
  final DateTime updatedAt;
  const RunSeries({
    required this.id,
    required this.clubId,
    required this.title,
    this.description,
    this.venueId,
    required this.weekday,
    required this.startTime,
    this.durationMin,
    required this.intervalWeeks,
    required this.validFrom,
    this.validUntil,
    required this.groupMode,
    this.cmsSlug,
    this.imageUrl,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<int>(clubId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || venueId != null) {
      map['venue_id'] = Variable<String>(venueId);
    }
    map['weekday'] = Variable<int>(weekday);
    map['start_time'] = Variable<String>(startTime);
    if (!nullToAbsent || durationMin != null) {
      map['duration_min'] = Variable<int>(durationMin);
    }
    map['interval_weeks'] = Variable<int>(intervalWeeks);
    map['valid_from'] = Variable<String>(validFrom);
    if (!nullToAbsent || validUntil != null) {
      map['valid_until'] = Variable<String>(validUntil);
    }
    map['group_mode'] = Variable<String>(groupMode);
    if (!nullToAbsent || cmsSlug != null) {
      map['cms_slug'] = Variable<String>(cmsSlug);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionSeriesCompanion toCompanion(bool nullToAbsent) {
    return SessionSeriesCompanion(
      id: Value(id),
      clubId: Value(clubId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      venueId: venueId == null && nullToAbsent
          ? const Value.absent()
          : Value(venueId),
      weekday: Value(weekday),
      startTime: Value(startTime),
      durationMin: durationMin == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMin),
      intervalWeeks: Value(intervalWeeks),
      validFrom: Value(validFrom),
      validUntil: validUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(validUntil),
      groupMode: Value(groupMode),
      cmsSlug: cmsSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(cmsSlug),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      updatedAt: Value(updatedAt),
    );
  }

  factory RunSeries.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunSeries(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<int>(json['clubId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      venueId: serializer.fromJson<String?>(json['venueId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startTime: serializer.fromJson<String>(json['startTime']),
      durationMin: serializer.fromJson<int?>(json['durationMin']),
      intervalWeeks: serializer.fromJson<int>(json['intervalWeeks']),
      validFrom: serializer.fromJson<String>(json['validFrom']),
      validUntil: serializer.fromJson<String?>(json['validUntil']),
      groupMode: serializer.fromJson<String>(json['groupMode']),
      cmsSlug: serializer.fromJson<String?>(json['cmsSlug']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<int>(clubId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'venueId': serializer.toJson<String?>(venueId),
      'weekday': serializer.toJson<int>(weekday),
      'startTime': serializer.toJson<String>(startTime),
      'durationMin': serializer.toJson<int?>(durationMin),
      'intervalWeeks': serializer.toJson<int>(intervalWeeks),
      'validFrom': serializer.toJson<String>(validFrom),
      'validUntil': serializer.toJson<String?>(validUntil),
      'groupMode': serializer.toJson<String>(groupMode),
      'cmsSlug': serializer.toJson<String?>(cmsSlug),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RunSeries copyWith({
    String? id,
    int? clubId,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> venueId = const Value.absent(),
    int? weekday,
    String? startTime,
    Value<int?> durationMin = const Value.absent(),
    int? intervalWeeks,
    String? validFrom,
    Value<String?> validUntil = const Value.absent(),
    String? groupMode,
    Value<String?> cmsSlug = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    DateTime? updatedAt,
  }) => RunSeries(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    venueId: venueId.present ? venueId.value : this.venueId,
    weekday: weekday ?? this.weekday,
    startTime: startTime ?? this.startTime,
    durationMin: durationMin.present ? durationMin.value : this.durationMin,
    intervalWeeks: intervalWeeks ?? this.intervalWeeks,
    validFrom: validFrom ?? this.validFrom,
    validUntil: validUntil.present ? validUntil.value : this.validUntil,
    groupMode: groupMode ?? this.groupMode,
    cmsSlug: cmsSlug.present ? cmsSlug.value : this.cmsSlug,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RunSeries copyWithCompanion(SessionSeriesCompanion data) {
    return RunSeries(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      intervalWeeks: data.intervalWeeks.present
          ? data.intervalWeeks.value
          : this.intervalWeeks,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validUntil: data.validUntil.present
          ? data.validUntil.value
          : this.validUntil,
      groupMode: data.groupMode.present ? data.groupMode.value : this.groupMode,
      cmsSlug: data.cmsSlug.present ? data.cmsSlug.value : this.cmsSlug,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunSeries(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('venueId: $venueId, ')
          ..write('weekday: $weekday, ')
          ..write('startTime: $startTime, ')
          ..write('durationMin: $durationMin, ')
          ..write('intervalWeeks: $intervalWeeks, ')
          ..write('validFrom: $validFrom, ')
          ..write('validUntil: $validUntil, ')
          ..write('groupMode: $groupMode, ')
          ..write('cmsSlug: $cmsSlug, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    title,
    description,
    venueId,
    weekday,
    startTime,
    durationMin,
    intervalWeeks,
    validFrom,
    validUntil,
    groupMode,
    cmsSlug,
    imageUrl,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunSeries &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.title == this.title &&
          other.description == this.description &&
          other.venueId == this.venueId &&
          other.weekday == this.weekday &&
          other.startTime == this.startTime &&
          other.durationMin == this.durationMin &&
          other.intervalWeeks == this.intervalWeeks &&
          other.validFrom == this.validFrom &&
          other.validUntil == this.validUntil &&
          other.groupMode == this.groupMode &&
          other.cmsSlug == this.cmsSlug &&
          other.imageUrl == this.imageUrl &&
          other.updatedAt == this.updatedAt);
}

class SessionSeriesCompanion extends UpdateCompanion<RunSeries> {
  final Value<String> id;
  final Value<int> clubId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> venueId;
  final Value<int> weekday;
  final Value<String> startTime;
  final Value<int?> durationMin;
  final Value<int> intervalWeeks;
  final Value<String> validFrom;
  final Value<String?> validUntil;
  final Value<String> groupMode;
  final Value<String?> cmsSlug;
  final Value<String?> imageUrl;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SessionSeriesCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.venueId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startTime = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.intervalWeeks = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.groupMode = const Value.absent(),
    this.cmsSlug = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionSeriesCompanion.insert({
    required String id,
    required int clubId,
    required String title,
    this.description = const Value.absent(),
    this.venueId = const Value.absent(),
    required int weekday,
    required String startTime,
    this.durationMin = const Value.absent(),
    this.intervalWeeks = const Value.absent(),
    required String validFrom,
    this.validUntil = const Value.absent(),
    required String groupMode,
    this.cmsSlug = const Value.absent(),
    this.imageUrl = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       title = Value(title),
       weekday = Value(weekday),
       startTime = Value(startTime),
       validFrom = Value(validFrom),
       groupMode = Value(groupMode),
       updatedAt = Value(updatedAt);
  static Insertable<RunSeries> custom({
    Expression<String>? id,
    Expression<int>? clubId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? venueId,
    Expression<int>? weekday,
    Expression<String>? startTime,
    Expression<int>? durationMin,
    Expression<int>? intervalWeeks,
    Expression<String>? validFrom,
    Expression<String>? validUntil,
    Expression<String>? groupMode,
    Expression<String>? cmsSlug,
    Expression<String>? imageUrl,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (venueId != null) 'venue_id': venueId,
      if (weekday != null) 'weekday': weekday,
      if (startTime != null) 'start_time': startTime,
      if (durationMin != null) 'duration_min': durationMin,
      if (intervalWeeks != null) 'interval_weeks': intervalWeeks,
      if (validFrom != null) 'valid_from': validFrom,
      if (validUntil != null) 'valid_until': validUntil,
      if (groupMode != null) 'group_mode': groupMode,
      if (cmsSlug != null) 'cms_slug': cmsSlug,
      if (imageUrl != null) 'image_url': imageUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionSeriesCompanion copyWith({
    Value<String>? id,
    Value<int>? clubId,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? venueId,
    Value<int>? weekday,
    Value<String>? startTime,
    Value<int?>? durationMin,
    Value<int>? intervalWeeks,
    Value<String>? validFrom,
    Value<String?>? validUntil,
    Value<String>? groupMode,
    Value<String?>? cmsSlug,
    Value<String?>? imageUrl,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SessionSeriesCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      title: title ?? this.title,
      description: description ?? this.description,
      venueId: venueId ?? this.venueId,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      durationMin: durationMin ?? this.durationMin,
      intervalWeeks: intervalWeeks ?? this.intervalWeeks,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      groupMode: groupMode ?? this.groupMode,
      cmsSlug: cmsSlug ?? this.cmsSlug,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (intervalWeeks.present) {
      map['interval_weeks'] = Variable<int>(intervalWeeks.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<String>(validFrom.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<String>(validUntil.value);
    }
    if (groupMode.present) {
      map['group_mode'] = Variable<String>(groupMode.value);
    }
    if (cmsSlug.present) {
      map['cms_slug'] = Variable<String>(cmsSlug.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionSeriesCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('venueId: $venueId, ')
          ..write('weekday: $weekday, ')
          ..write('startTime: $startTime, ')
          ..write('durationMin: $durationMin, ')
          ..write('intervalWeeks: $intervalWeeks, ')
          ..write('validFrom: $validFrom, ')
          ..write('validUntil: $validUntil, ')
          ..write('groupMode: $groupMode, ')
          ..write('cmsSlug: $cmsSlug, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<String> occurrenceDate = GeneratedColumn<String>(
    'occurrence_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _venueIdMeta = const VerificationMeta(
    'venueId',
  );
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
    'venue_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
    'ends_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localStartTimeMeta = const VerificationMeta(
    'localStartTime',
  );
  @override
  late final GeneratedColumn<String> localStartTime = GeneratedColumn<String>(
    'local_start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localEndTimeMeta = const VerificationMeta(
    'localEndTime',
  );
  @override
  late final GeneratedColumn<String> localEndTime = GeneratedColumn<String>(
    'local_end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupModeMeta = const VerificationMeta(
    'groupMode',
  );
  @override
  late final GeneratedColumn<String> groupMode = GeneratedColumn<String>(
    'group_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('scheduled'),
  );
  static const VerificationMeta _cancelReasonMeta = const VerificationMeta(
    'cancelReason',
  );
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
    'cancel_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coordinatorMemberIdMeta =
      const VerificationMeta('coordinatorMemberId');
  @override
  late final GeneratedColumn<String> coordinatorMemberId =
      GeneratedColumn<String>(
        'coordinator_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _coordinatorNameMeta = const VerificationMeta(
    'coordinatorName',
  );
  @override
  late final GeneratedColumn<String> coordinatorName = GeneratedColumn<String>(
    'coordinator_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDetachedMeta = const VerificationMeta(
    'isDetached',
  );
  @override
  late final GeneratedColumn<bool> isDetached = GeneratedColumn<bool>(
    'is_detached',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_detached" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _originalJsonMeta = const VerificationMeta(
    'originalJson',
  );
  @override
  late final GeneratedColumn<String> originalJson = GeneratedColumn<String>(
    'original_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupsJsonMeta = const VerificationMeta(
    'groupsJson',
  );
  @override
  late final GeneratedColumn<String> groupsJson = GeneratedColumn<String>(
    'groups_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    seriesId,
    occurrenceDate,
    title,
    venueId,
    notes,
    startsAt,
    endsAt,
    localDate,
    localStartTime,
    localEndTime,
    groupMode,
    status,
    cancelReason,
    imageUrl,
    coordinatorMemberId,
    coordinatorName,
    isDetached,
    originalJson,
    groupsJson,
    summaryJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('venue_id')) {
      context.handle(
        _venueIdMeta,
        venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endsAtMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('local_start_time')) {
      context.handle(
        _localStartTimeMeta,
        localStartTime.isAcceptableOrUnknown(
          data['local_start_time']!,
          _localStartTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localStartTimeMeta);
    }
    if (data.containsKey('local_end_time')) {
      context.handle(
        _localEndTimeMeta,
        localEndTime.isAcceptableOrUnknown(
          data['local_end_time']!,
          _localEndTimeMeta,
        ),
      );
    }
    if (data.containsKey('group_mode')) {
      context.handle(
        _groupModeMeta,
        groupMode.isAcceptableOrUnknown(data['group_mode']!, _groupModeMeta),
      );
    } else if (isInserting) {
      context.missing(_groupModeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
        _cancelReasonMeta,
        cancelReason.isAcceptableOrUnknown(
          data['cancel_reason']!,
          _cancelReasonMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('coordinator_member_id')) {
      context.handle(
        _coordinatorMemberIdMeta,
        coordinatorMemberId.isAcceptableOrUnknown(
          data['coordinator_member_id']!,
          _coordinatorMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('coordinator_name')) {
      context.handle(
        _coordinatorNameMeta,
        coordinatorName.isAcceptableOrUnknown(
          data['coordinator_name']!,
          _coordinatorNameMeta,
        ),
      );
    }
    if (data.containsKey('is_detached')) {
      context.handle(
        _isDetachedMeta,
        isDetached.isAcceptableOrUnknown(data['is_detached']!, _isDetachedMeta),
      );
    }
    if (data.containsKey('original_json')) {
      context.handle(
        _originalJsonMeta,
        originalJson.isAcceptableOrUnknown(
          data['original_json']!,
          _originalJsonMeta,
        ),
      );
    }
    if (data.containsKey('groups_json')) {
      context.handle(
        _groupsJsonMeta,
        groupsJson.isAcceptableOrUnknown(data['groups_json']!, _groupsJsonMeta),
      );
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_date'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      venueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_at'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      localStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_start_time'],
      )!,
      localEndTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_end_time'],
      ),
      groupMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      cancelReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancel_reason'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      coordinatorMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coordinator_member_id'],
      ),
      coordinatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coordinator_name'],
      ),
      isDetached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_detached'],
      )!,
      originalJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_json'],
      ),
      groupsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}groups_json'],
      ),
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final int clubId;
  final String? seriesId;
  final String? occurrenceDate;
  final String title;
  final String? venueId;
  final String? notes;
  final DateTime startsAt;
  final DateTime endsAt;
  final String localDate;
  final String localStartTime;

  /// Null when the run has no end time (D47). `endsAt` stays filled (start + 3 h)
  /// so "is it over" checks keep working; see D52.
  final String? localEndTime;
  final String groupMode;

  /// `scheduled` | `cancelled`.
  final String status;
  final String? cancelReason;

  /// The series' banner image URL, copied onto the run by the server (D49).
  final String? imageUrl;
  final String? coordinatorMemberId;
  final String? coordinatorName;
  final bool isDetached;

  /// JSON of the contract's `original` block (what the series says), or null.
  final String? originalJson;

  /// JSON array of the contract's embedded `groups` (Phase 4), or null for an
  /// older payload that had none.
  final String? groupsJson;

  /// JSON of the contract's `summary` block for the caller (Phase 4), or null.
  final String? summaryJson;
  final DateTime updatedAt;
  const Session({
    required this.id,
    required this.clubId,
    this.seriesId,
    this.occurrenceDate,
    required this.title,
    this.venueId,
    this.notes,
    required this.startsAt,
    required this.endsAt,
    required this.localDate,
    required this.localStartTime,
    this.localEndTime,
    required this.groupMode,
    required this.status,
    this.cancelReason,
    this.imageUrl,
    this.coordinatorMemberId,
    this.coordinatorName,
    required this.isDetached,
    this.originalJson,
    this.groupsJson,
    this.summaryJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<int>(clubId);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || occurrenceDate != null) {
      map['occurrence_date'] = Variable<String>(occurrenceDate);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || venueId != null) {
      map['venue_id'] = Variable<String>(venueId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['ends_at'] = Variable<DateTime>(endsAt);
    map['local_date'] = Variable<String>(localDate);
    map['local_start_time'] = Variable<String>(localStartTime);
    if (!nullToAbsent || localEndTime != null) {
      map['local_end_time'] = Variable<String>(localEndTime);
    }
    map['group_mode'] = Variable<String>(groupMode);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || cancelReason != null) {
      map['cancel_reason'] = Variable<String>(cancelReason);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || coordinatorMemberId != null) {
      map['coordinator_member_id'] = Variable<String>(coordinatorMemberId);
    }
    if (!nullToAbsent || coordinatorName != null) {
      map['coordinator_name'] = Variable<String>(coordinatorName);
    }
    map['is_detached'] = Variable<bool>(isDetached);
    if (!nullToAbsent || originalJson != null) {
      map['original_json'] = Variable<String>(originalJson);
    }
    if (!nullToAbsent || groupsJson != null) {
      map['groups_json'] = Variable<String>(groupsJson);
    }
    if (!nullToAbsent || summaryJson != null) {
      map['summary_json'] = Variable<String>(summaryJson);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      clubId: Value(clubId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      occurrenceDate: occurrenceDate == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceDate),
      title: Value(title),
      venueId: venueId == null && nullToAbsent
          ? const Value.absent()
          : Value(venueId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      startsAt: Value(startsAt),
      endsAt: Value(endsAt),
      localDate: Value(localDate),
      localStartTime: Value(localStartTime),
      localEndTime: localEndTime == null && nullToAbsent
          ? const Value.absent()
          : Value(localEndTime),
      groupMode: Value(groupMode),
      status: Value(status),
      cancelReason: cancelReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelReason),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      coordinatorMemberId: coordinatorMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(coordinatorMemberId),
      coordinatorName: coordinatorName == null && nullToAbsent
          ? const Value.absent()
          : Value(coordinatorName),
      isDetached: Value(isDetached),
      originalJson: originalJson == null && nullToAbsent
          ? const Value.absent()
          : Value(originalJson),
      groupsJson: groupsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(groupsJson),
      summaryJson: summaryJson == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<int>(json['clubId']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      occurrenceDate: serializer.fromJson<String?>(json['occurrenceDate']),
      title: serializer.fromJson<String>(json['title']),
      venueId: serializer.fromJson<String?>(json['venueId']),
      notes: serializer.fromJson<String?>(json['notes']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime>(json['endsAt']),
      localDate: serializer.fromJson<String>(json['localDate']),
      localStartTime: serializer.fromJson<String>(json['localStartTime']),
      localEndTime: serializer.fromJson<String?>(json['localEndTime']),
      groupMode: serializer.fromJson<String>(json['groupMode']),
      status: serializer.fromJson<String>(json['status']),
      cancelReason: serializer.fromJson<String?>(json['cancelReason']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      coordinatorMemberId: serializer.fromJson<String?>(
        json['coordinatorMemberId'],
      ),
      coordinatorName: serializer.fromJson<String?>(json['coordinatorName']),
      isDetached: serializer.fromJson<bool>(json['isDetached']),
      originalJson: serializer.fromJson<String?>(json['originalJson']),
      groupsJson: serializer.fromJson<String?>(json['groupsJson']),
      summaryJson: serializer.fromJson<String?>(json['summaryJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<int>(clubId),
      'seriesId': serializer.toJson<String?>(seriesId),
      'occurrenceDate': serializer.toJson<String?>(occurrenceDate),
      'title': serializer.toJson<String>(title),
      'venueId': serializer.toJson<String?>(venueId),
      'notes': serializer.toJson<String?>(notes),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'endsAt': serializer.toJson<DateTime>(endsAt),
      'localDate': serializer.toJson<String>(localDate),
      'localStartTime': serializer.toJson<String>(localStartTime),
      'localEndTime': serializer.toJson<String?>(localEndTime),
      'groupMode': serializer.toJson<String>(groupMode),
      'status': serializer.toJson<String>(status),
      'cancelReason': serializer.toJson<String?>(cancelReason),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'coordinatorMemberId': serializer.toJson<String?>(coordinatorMemberId),
      'coordinatorName': serializer.toJson<String?>(coordinatorName),
      'isDetached': serializer.toJson<bool>(isDetached),
      'originalJson': serializer.toJson<String?>(originalJson),
      'groupsJson': serializer.toJson<String?>(groupsJson),
      'summaryJson': serializer.toJson<String?>(summaryJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Session copyWith({
    String? id,
    int? clubId,
    Value<String?> seriesId = const Value.absent(),
    Value<String?> occurrenceDate = const Value.absent(),
    String? title,
    Value<String?> venueId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? startsAt,
    DateTime? endsAt,
    String? localDate,
    String? localStartTime,
    Value<String?> localEndTime = const Value.absent(),
    String? groupMode,
    String? status,
    Value<String?> cancelReason = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> coordinatorMemberId = const Value.absent(),
    Value<String?> coordinatorName = const Value.absent(),
    bool? isDetached,
    Value<String?> originalJson = const Value.absent(),
    Value<String?> groupsJson = const Value.absent(),
    Value<String?> summaryJson = const Value.absent(),
    DateTime? updatedAt,
  }) => Session(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    occurrenceDate: occurrenceDate.present
        ? occurrenceDate.value
        : this.occurrenceDate,
    title: title ?? this.title,
    venueId: venueId.present ? venueId.value : this.venueId,
    notes: notes.present ? notes.value : this.notes,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    localDate: localDate ?? this.localDate,
    localStartTime: localStartTime ?? this.localStartTime,
    localEndTime: localEndTime.present ? localEndTime.value : this.localEndTime,
    groupMode: groupMode ?? this.groupMode,
    status: status ?? this.status,
    cancelReason: cancelReason.present ? cancelReason.value : this.cancelReason,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    coordinatorMemberId: coordinatorMemberId.present
        ? coordinatorMemberId.value
        : this.coordinatorMemberId,
    coordinatorName: coordinatorName.present
        ? coordinatorName.value
        : this.coordinatorName,
    isDetached: isDetached ?? this.isDetached,
    originalJson: originalJson.present ? originalJson.value : this.originalJson,
    groupsJson: groupsJson.present ? groupsJson.value : this.groupsJson,
    summaryJson: summaryJson.present ? summaryJson.value : this.summaryJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      title: data.title.present ? data.title.value : this.title,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      notes: data.notes.present ? data.notes.value : this.notes,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      localStartTime: data.localStartTime.present
          ? data.localStartTime.value
          : this.localStartTime,
      localEndTime: data.localEndTime.present
          ? data.localEndTime.value
          : this.localEndTime,
      groupMode: data.groupMode.present ? data.groupMode.value : this.groupMode,
      status: data.status.present ? data.status.value : this.status,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      coordinatorMemberId: data.coordinatorMemberId.present
          ? data.coordinatorMemberId.value
          : this.coordinatorMemberId,
      coordinatorName: data.coordinatorName.present
          ? data.coordinatorName.value
          : this.coordinatorName,
      isDetached: data.isDetached.present
          ? data.isDetached.value
          : this.isDetached,
      originalJson: data.originalJson.present
          ? data.originalJson.value
          : this.originalJson,
      groupsJson: data.groupsJson.present
          ? data.groupsJson.value
          : this.groupsJson,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('seriesId: $seriesId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('title: $title, ')
          ..write('venueId: $venueId, ')
          ..write('notes: $notes, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('localDate: $localDate, ')
          ..write('localStartTime: $localStartTime, ')
          ..write('localEndTime: $localEndTime, ')
          ..write('groupMode: $groupMode, ')
          ..write('status: $status, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('coordinatorMemberId: $coordinatorMemberId, ')
          ..write('coordinatorName: $coordinatorName, ')
          ..write('isDetached: $isDetached, ')
          ..write('originalJson: $originalJson, ')
          ..write('groupsJson: $groupsJson, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    clubId,
    seriesId,
    occurrenceDate,
    title,
    venueId,
    notes,
    startsAt,
    endsAt,
    localDate,
    localStartTime,
    localEndTime,
    groupMode,
    status,
    cancelReason,
    imageUrl,
    coordinatorMemberId,
    coordinatorName,
    isDetached,
    originalJson,
    groupsJson,
    summaryJson,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.seriesId == this.seriesId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.title == this.title &&
          other.venueId == this.venueId &&
          other.notes == this.notes &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.localDate == this.localDate &&
          other.localStartTime == this.localStartTime &&
          other.localEndTime == this.localEndTime &&
          other.groupMode == this.groupMode &&
          other.status == this.status &&
          other.cancelReason == this.cancelReason &&
          other.imageUrl == this.imageUrl &&
          other.coordinatorMemberId == this.coordinatorMemberId &&
          other.coordinatorName == this.coordinatorName &&
          other.isDetached == this.isDetached &&
          other.originalJson == this.originalJson &&
          other.groupsJson == this.groupsJson &&
          other.summaryJson == this.summaryJson &&
          other.updatedAt == this.updatedAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<int> clubId;
  final Value<String?> seriesId;
  final Value<String?> occurrenceDate;
  final Value<String> title;
  final Value<String?> venueId;
  final Value<String?> notes;
  final Value<DateTime> startsAt;
  final Value<DateTime> endsAt;
  final Value<String> localDate;
  final Value<String> localStartTime;
  final Value<String?> localEndTime;
  final Value<String> groupMode;
  final Value<String> status;
  final Value<String?> cancelReason;
  final Value<String?> imageUrl;
  final Value<String?> coordinatorMemberId;
  final Value<String?> coordinatorName;
  final Value<bool> isDetached;
  final Value<String?> originalJson;
  final Value<String?> groupsJson;
  final Value<String?> summaryJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.title = const Value.absent(),
    this.venueId = const Value.absent(),
    this.notes = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.localDate = const Value.absent(),
    this.localStartTime = const Value.absent(),
    this.localEndTime = const Value.absent(),
    this.groupMode = const Value.absent(),
    this.status = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.coordinatorMemberId = const Value.absent(),
    this.coordinatorName = const Value.absent(),
    this.isDetached = const Value.absent(),
    this.originalJson = const Value.absent(),
    this.groupsJson = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required int clubId,
    this.seriesId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    required String title,
    this.venueId = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime startsAt,
    required DateTime endsAt,
    required String localDate,
    required String localStartTime,
    this.localEndTime = const Value.absent(),
    required String groupMode,
    this.status = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.coordinatorMemberId = const Value.absent(),
    this.coordinatorName = const Value.absent(),
    this.isDetached = const Value.absent(),
    this.originalJson = const Value.absent(),
    this.groupsJson = const Value.absent(),
    this.summaryJson = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       title = Value(title),
       startsAt = Value(startsAt),
       endsAt = Value(endsAt),
       localDate = Value(localDate),
       localStartTime = Value(localStartTime),
       groupMode = Value(groupMode),
       updatedAt = Value(updatedAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<int>? clubId,
    Expression<String>? seriesId,
    Expression<String>? occurrenceDate,
    Expression<String>? title,
    Expression<String>? venueId,
    Expression<String>? notes,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<String>? localDate,
    Expression<String>? localStartTime,
    Expression<String>? localEndTime,
    Expression<String>? groupMode,
    Expression<String>? status,
    Expression<String>? cancelReason,
    Expression<String>? imageUrl,
    Expression<String>? coordinatorMemberId,
    Expression<String>? coordinatorName,
    Expression<bool>? isDetached,
    Expression<String>? originalJson,
    Expression<String>? groupsJson,
    Expression<String>? summaryJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (seriesId != null) 'series_id': seriesId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (title != null) 'title': title,
      if (venueId != null) 'venue_id': venueId,
      if (notes != null) 'notes': notes,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (localDate != null) 'local_date': localDate,
      if (localStartTime != null) 'local_start_time': localStartTime,
      if (localEndTime != null) 'local_end_time': localEndTime,
      if (groupMode != null) 'group_mode': groupMode,
      if (status != null) 'status': status,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (imageUrl != null) 'image_url': imageUrl,
      if (coordinatorMemberId != null)
        'coordinator_member_id': coordinatorMemberId,
      if (coordinatorName != null) 'coordinator_name': coordinatorName,
      if (isDetached != null) 'is_detached': isDetached,
      if (originalJson != null) 'original_json': originalJson,
      if (groupsJson != null) 'groups_json': groupsJson,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? clubId,
    Value<String?>? seriesId,
    Value<String?>? occurrenceDate,
    Value<String>? title,
    Value<String?>? venueId,
    Value<String?>? notes,
    Value<DateTime>? startsAt,
    Value<DateTime>? endsAt,
    Value<String>? localDate,
    Value<String>? localStartTime,
    Value<String?>? localEndTime,
    Value<String>? groupMode,
    Value<String>? status,
    Value<String?>? cancelReason,
    Value<String?>? imageUrl,
    Value<String?>? coordinatorMemberId,
    Value<String?>? coordinatorName,
    Value<bool>? isDetached,
    Value<String?>? originalJson,
    Value<String?>? groupsJson,
    Value<String?>? summaryJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      seriesId: seriesId ?? this.seriesId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      title: title ?? this.title,
      venueId: venueId ?? this.venueId,
      notes: notes ?? this.notes,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      localDate: localDate ?? this.localDate,
      localStartTime: localStartTime ?? this.localStartTime,
      localEndTime: localEndTime ?? this.localEndTime,
      groupMode: groupMode ?? this.groupMode,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      imageUrl: imageUrl ?? this.imageUrl,
      coordinatorMemberId: coordinatorMemberId ?? this.coordinatorMemberId,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      isDetached: isDetached ?? this.isDetached,
      originalJson: originalJson ?? this.originalJson,
      groupsJson: groupsJson ?? this.groupsJson,
      summaryJson: summaryJson ?? this.summaryJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<String>(occurrenceDate.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (localStartTime.present) {
      map['local_start_time'] = Variable<String>(localStartTime.value);
    }
    if (localEndTime.present) {
      map['local_end_time'] = Variable<String>(localEndTime.value);
    }
    if (groupMode.present) {
      map['group_mode'] = Variable<String>(groupMode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (coordinatorMemberId.present) {
      map['coordinator_member_id'] = Variable<String>(
        coordinatorMemberId.value,
      );
    }
    if (coordinatorName.present) {
      map['coordinator_name'] = Variable<String>(coordinatorName.value);
    }
    if (isDetached.present) {
      map['is_detached'] = Variable<bool>(isDetached.value);
    }
    if (originalJson.present) {
      map['original_json'] = Variable<String>(originalJson.value);
    }
    if (groupsJson.present) {
      map['groups_json'] = Variable<String>(groupsJson.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('seriesId: $seriesId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('title: $title, ')
          ..write('venueId: $venueId, ')
          ..write('notes: $notes, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('localDate: $localDate, ')
          ..write('localStartTime: $localStartTime, ')
          ..write('localEndTime: $localEndTime, ')
          ..write('groupMode: $groupMode, ')
          ..write('status: $status, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('coordinatorMemberId: $coordinatorMemberId, ')
          ..write('coordinatorName: $coordinatorName, ')
          ..write('isDetached: $isDetached, ')
          ..write('originalJson: $originalJson, ')
          ..write('groupsJson: $groupsJson, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionPlansTable extends SessionPlans
    with TableInfo<$SessionPlansTable, SessionPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, clubId, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  SessionPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionPlanRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $SessionPlansTable createAlias(String alias) {
    return $SessionPlansTable(attachedDatabase, alias);
  }
}

class SessionPlanRow extends DataClass implements Insertable<SessionPlanRow> {
  final String sessionId;
  final int clubId;
  final String json;
  final DateTime fetchedAt;
  const SessionPlanRow({
    required this.sessionId,
    required this.clubId,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['club_id'] = Variable<int>(clubId);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  SessionPlansCompanion toCompanion(bool nullToAbsent) {
    return SessionPlansCompanion(
      sessionId: Value(sessionId),
      clubId: Value(clubId),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory SessionPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionPlanRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      clubId: serializer.fromJson<int>(json['clubId']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'clubId': serializer.toJson<int>(clubId),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  SessionPlanRow copyWith({
    String? sessionId,
    int? clubId,
    String? json,
    DateTime? fetchedAt,
  }) => SessionPlanRow(
    sessionId: sessionId ?? this.sessionId,
    clubId: clubId ?? this.clubId,
    json: json ?? this.json,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  SessionPlanRow copyWithCompanion(SessionPlansCompanion data) {
    return SessionPlanRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionPlanRow(')
          ..write('sessionId: $sessionId, ')
          ..write('clubId: $clubId, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, clubId, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionPlanRow &&
          other.sessionId == this.sessionId &&
          other.clubId == this.clubId &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class SessionPlansCompanion extends UpdateCompanion<SessionPlanRow> {
  final Value<String> sessionId;
  final Value<int> clubId;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const SessionPlansCompanion({
    this.sessionId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionPlansCompanion.insert({
    required String sessionId,
    required int clubId,
    required String json,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       clubId = Value(clubId),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<SessionPlanRow> custom({
    Expression<String>? sessionId,
    Expression<int>? clubId,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (clubId != null) 'club_id': clubId,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionPlansCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? clubId,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return SessionPlansCompanion(
      sessionId: sessionId ?? this.sessionId,
      clubId: clubId ?? this.clubId,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionPlansCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('clubId: $clubId, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MyAttendanceTable extends MyAttendance
    with TableInfo<$MyAttendanceTable, MyAttendanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MyAttendanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paceUnitMeta = const VerificationMeta(
    'paceUnit',
  );
  @override
  late final GeneratedColumn<String> paceUnit = GeneratedColumn<String>(
    'pace_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paceFromSMeta = const VerificationMeta(
    'paceFromS',
  );
  @override
  late final GeneratedColumn<int> paceFromS = GeneratedColumn<int>(
    'pace_from_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paceToSMeta = const VerificationMeta(
    'paceToS',
  );
  @override
  late final GeneratedColumn<int> paceToS = GeneratedColumn<int>(
    'pace_to_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    clubId,
    status,
    groupId,
    paceUnit,
    paceFromS,
    paceToS,
    pending,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'my_attendance';
  @override
  VerificationContext validateIntegrity(
    Insertable<MyAttendanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('pace_unit')) {
      context.handle(
        _paceUnitMeta,
        paceUnit.isAcceptableOrUnknown(data['pace_unit']!, _paceUnitMeta),
      );
    }
    if (data.containsKey('pace_from_s')) {
      context.handle(
        _paceFromSMeta,
        paceFromS.isAcceptableOrUnknown(data['pace_from_s']!, _paceFromSMeta),
      );
    }
    if (data.containsKey('pace_to_s')) {
      context.handle(
        _paceToSMeta,
        paceToS.isAcceptableOrUnknown(data['pace_to_s']!, _paceToSMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  MyAttendanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MyAttendanceRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      paceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pace_unit'],
      ),
      paceFromS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_from_s'],
      ),
      paceToS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_to_s'],
      ),
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MyAttendanceTable createAlias(String alias) {
    return $MyAttendanceTable(attachedDatabase, alias);
  }
}

class MyAttendanceRow extends DataClass implements Insertable<MyAttendanceRow> {
  final String sessionId;
  final int clubId;

  /// `going` | `maybe` | `not_going`.
  final String status;
  final String? groupId;

  /// Per-run pace override, stored as entered (`mi`/`km` + seconds).
  final String? paceUnit;
  final int? paceFromS;
  final int? paceToS;
  final bool pending;
  final DateTime updatedAt;
  const MyAttendanceRow({
    required this.sessionId,
    required this.clubId,
    required this.status,
    this.groupId,
    this.paceUnit,
    this.paceFromS,
    this.paceToS,
    required this.pending,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['club_id'] = Variable<int>(clubId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || paceUnit != null) {
      map['pace_unit'] = Variable<String>(paceUnit);
    }
    if (!nullToAbsent || paceFromS != null) {
      map['pace_from_s'] = Variable<int>(paceFromS);
    }
    if (!nullToAbsent || paceToS != null) {
      map['pace_to_s'] = Variable<int>(paceToS);
    }
    map['pending'] = Variable<bool>(pending);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MyAttendanceCompanion toCompanion(bool nullToAbsent) {
    return MyAttendanceCompanion(
      sessionId: Value(sessionId),
      clubId: Value(clubId),
      status: Value(status),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      paceUnit: paceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(paceUnit),
      paceFromS: paceFromS == null && nullToAbsent
          ? const Value.absent()
          : Value(paceFromS),
      paceToS: paceToS == null && nullToAbsent
          ? const Value.absent()
          : Value(paceToS),
      pending: Value(pending),
      updatedAt: Value(updatedAt),
    );
  }

  factory MyAttendanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MyAttendanceRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      clubId: serializer.fromJson<int>(json['clubId']),
      status: serializer.fromJson<String>(json['status']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      paceUnit: serializer.fromJson<String?>(json['paceUnit']),
      paceFromS: serializer.fromJson<int?>(json['paceFromS']),
      paceToS: serializer.fromJson<int?>(json['paceToS']),
      pending: serializer.fromJson<bool>(json['pending']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'clubId': serializer.toJson<int>(clubId),
      'status': serializer.toJson<String>(status),
      'groupId': serializer.toJson<String?>(groupId),
      'paceUnit': serializer.toJson<String?>(paceUnit),
      'paceFromS': serializer.toJson<int?>(paceFromS),
      'paceToS': serializer.toJson<int?>(paceToS),
      'pending': serializer.toJson<bool>(pending),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MyAttendanceRow copyWith({
    String? sessionId,
    int? clubId,
    String? status,
    Value<String?> groupId = const Value.absent(),
    Value<String?> paceUnit = const Value.absent(),
    Value<int?> paceFromS = const Value.absent(),
    Value<int?> paceToS = const Value.absent(),
    bool? pending,
    DateTime? updatedAt,
  }) => MyAttendanceRow(
    sessionId: sessionId ?? this.sessionId,
    clubId: clubId ?? this.clubId,
    status: status ?? this.status,
    groupId: groupId.present ? groupId.value : this.groupId,
    paceUnit: paceUnit.present ? paceUnit.value : this.paceUnit,
    paceFromS: paceFromS.present ? paceFromS.value : this.paceFromS,
    paceToS: paceToS.present ? paceToS.value : this.paceToS,
    pending: pending ?? this.pending,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MyAttendanceRow copyWithCompanion(MyAttendanceCompanion data) {
    return MyAttendanceRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      status: data.status.present ? data.status.value : this.status,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      paceUnit: data.paceUnit.present ? data.paceUnit.value : this.paceUnit,
      paceFromS: data.paceFromS.present ? data.paceFromS.value : this.paceFromS,
      paceToS: data.paceToS.present ? data.paceToS.value : this.paceToS,
      pending: data.pending.present ? data.pending.value : this.pending,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MyAttendanceRow(')
          ..write('sessionId: $sessionId, ')
          ..write('clubId: $clubId, ')
          ..write('status: $status, ')
          ..write('groupId: $groupId, ')
          ..write('paceUnit: $paceUnit, ')
          ..write('paceFromS: $paceFromS, ')
          ..write('paceToS: $paceToS, ')
          ..write('pending: $pending, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    clubId,
    status,
    groupId,
    paceUnit,
    paceFromS,
    paceToS,
    pending,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MyAttendanceRow &&
          other.sessionId == this.sessionId &&
          other.clubId == this.clubId &&
          other.status == this.status &&
          other.groupId == this.groupId &&
          other.paceUnit == this.paceUnit &&
          other.paceFromS == this.paceFromS &&
          other.paceToS == this.paceToS &&
          other.pending == this.pending &&
          other.updatedAt == this.updatedAt);
}

class MyAttendanceCompanion extends UpdateCompanion<MyAttendanceRow> {
  final Value<String> sessionId;
  final Value<int> clubId;
  final Value<String> status;
  final Value<String?> groupId;
  final Value<String?> paceUnit;
  final Value<int?> paceFromS;
  final Value<int?> paceToS;
  final Value<bool> pending;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MyAttendanceCompanion({
    this.sessionId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.status = const Value.absent(),
    this.groupId = const Value.absent(),
    this.paceUnit = const Value.absent(),
    this.paceFromS = const Value.absent(),
    this.paceToS = const Value.absent(),
    this.pending = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MyAttendanceCompanion.insert({
    required String sessionId,
    required int clubId,
    required String status,
    this.groupId = const Value.absent(),
    this.paceUnit = const Value.absent(),
    this.paceFromS = const Value.absent(),
    this.paceToS = const Value.absent(),
    this.pending = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       clubId = Value(clubId),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<MyAttendanceRow> custom({
    Expression<String>? sessionId,
    Expression<int>? clubId,
    Expression<String>? status,
    Expression<String>? groupId,
    Expression<String>? paceUnit,
    Expression<int>? paceFromS,
    Expression<int>? paceToS,
    Expression<bool>? pending,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (clubId != null) 'club_id': clubId,
      if (status != null) 'status': status,
      if (groupId != null) 'group_id': groupId,
      if (paceUnit != null) 'pace_unit': paceUnit,
      if (paceFromS != null) 'pace_from_s': paceFromS,
      if (paceToS != null) 'pace_to_s': paceToS,
      if (pending != null) 'pending': pending,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MyAttendanceCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? clubId,
    Value<String>? status,
    Value<String?>? groupId,
    Value<String?>? paceUnit,
    Value<int?>? paceFromS,
    Value<int?>? paceToS,
    Value<bool>? pending,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MyAttendanceCompanion(
      sessionId: sessionId ?? this.sessionId,
      clubId: clubId ?? this.clubId,
      status: status ?? this.status,
      groupId: groupId ?? this.groupId,
      paceUnit: paceUnit ?? this.paceUnit,
      paceFromS: paceFromS ?? this.paceFromS,
      paceToS: paceToS ?? this.paceToS,
      pending: pending ?? this.pending,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (paceUnit.present) {
      map['pace_unit'] = Variable<String>(paceUnit.value);
    }
    if (paceFromS.present) {
      map['pace_from_s'] = Variable<int>(paceFromS.value);
    }
    if (paceToS.present) {
      map['pace_to_s'] = Variable<int>(paceToS.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MyAttendanceCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('clubId: $clubId, ')
          ..write('status: $status, ')
          ..write('groupId: $groupId, ')
          ..write('paceUnit: $paceUnit, ')
          ..write('paceFromS: $paceFromS, ')
          ..write('paceToS: $paceToS, ')
          ..write('pending: $pending, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, RunPreferences> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paceUnitMeta = const VerificationMeta(
    'paceUnit',
  );
  @override
  late final GeneratedColumn<String> paceUnit = GeneratedColumn<String>(
    'pace_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceUnitMeta = const VerificationMeta(
    'distanceUnit',
  );
  @override
  late final GeneratedColumn<String> distanceUnit = GeneratedColumn<String>(
    'distance_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paceFromSMeta = const VerificationMeta(
    'paceFromS',
  );
  @override
  late final GeneratedColumn<int> paceFromS = GeneratedColumn<int>(
    'pace_from_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paceToSMeta = const VerificationMeta(
    'paceToS',
  );
  @override
  late final GeneratedColumn<int> paceToS = GeneratedColumn<int>(
    'pace_to_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clubId,
    paceUnit,
    distanceUnit,
    paceFromS,
    paceToS,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunPreferences> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    }
    if (data.containsKey('pace_unit')) {
      context.handle(
        _paceUnitMeta,
        paceUnit.isAcceptableOrUnknown(data['pace_unit']!, _paceUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_paceUnitMeta);
    }
    if (data.containsKey('distance_unit')) {
      context.handle(
        _distanceUnitMeta,
        distanceUnit.isAcceptableOrUnknown(
          data['distance_unit']!,
          _distanceUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceUnitMeta);
    }
    if (data.containsKey('pace_from_s')) {
      context.handle(
        _paceFromSMeta,
        paceFromS.isAcceptableOrUnknown(data['pace_from_s']!, _paceFromSMeta),
      );
    }
    if (data.containsKey('pace_to_s')) {
      context.handle(
        _paceToSMeta,
        paceToS.isAcceptableOrUnknown(data['pace_to_s']!, _paceToSMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clubId};
  @override
  RunPreferences map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunPreferences(
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      paceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pace_unit'],
      )!,
      distanceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distance_unit'],
      )!,
      paceFromS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_from_s'],
      ),
      paceToS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_to_s'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class RunPreferences extends DataClass implements Insertable<RunPreferences> {
  final int clubId;
  final String paceUnit;
  final String distanceUnit;
  final int? paceFromS;
  final int? paceToS;

  /// Null until the server has stored them.
  final DateTime? updatedAt;
  const RunPreferences({
    required this.clubId,
    required this.paceUnit,
    required this.distanceUnit,
    this.paceFromS,
    this.paceToS,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['club_id'] = Variable<int>(clubId);
    map['pace_unit'] = Variable<String>(paceUnit);
    map['distance_unit'] = Variable<String>(distanceUnit);
    if (!nullToAbsent || paceFromS != null) {
      map['pace_from_s'] = Variable<int>(paceFromS);
    }
    if (!nullToAbsent || paceToS != null) {
      map['pace_to_s'] = Variable<int>(paceToS);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(
      clubId: Value(clubId),
      paceUnit: Value(paceUnit),
      distanceUnit: Value(distanceUnit),
      paceFromS: paceFromS == null && nullToAbsent
          ? const Value.absent()
          : Value(paceFromS),
      paceToS: paceToS == null && nullToAbsent
          ? const Value.absent()
          : Value(paceToS),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory RunPreferences.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunPreferences(
      clubId: serializer.fromJson<int>(json['clubId']),
      paceUnit: serializer.fromJson<String>(json['paceUnit']),
      distanceUnit: serializer.fromJson<String>(json['distanceUnit']),
      paceFromS: serializer.fromJson<int?>(json['paceFromS']),
      paceToS: serializer.fromJson<int?>(json['paceToS']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clubId': serializer.toJson<int>(clubId),
      'paceUnit': serializer.toJson<String>(paceUnit),
      'distanceUnit': serializer.toJson<String>(distanceUnit),
      'paceFromS': serializer.toJson<int?>(paceFromS),
      'paceToS': serializer.toJson<int?>(paceToS),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  RunPreferences copyWith({
    int? clubId,
    String? paceUnit,
    String? distanceUnit,
    Value<int?> paceFromS = const Value.absent(),
    Value<int?> paceToS = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => RunPreferences(
    clubId: clubId ?? this.clubId,
    paceUnit: paceUnit ?? this.paceUnit,
    distanceUnit: distanceUnit ?? this.distanceUnit,
    paceFromS: paceFromS.present ? paceFromS.value : this.paceFromS,
    paceToS: paceToS.present ? paceToS.value : this.paceToS,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  RunPreferences copyWithCompanion(PreferencesCompanion data) {
    return RunPreferences(
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      paceUnit: data.paceUnit.present ? data.paceUnit.value : this.paceUnit,
      distanceUnit: data.distanceUnit.present
          ? data.distanceUnit.value
          : this.distanceUnit,
      paceFromS: data.paceFromS.present ? data.paceFromS.value : this.paceFromS,
      paceToS: data.paceToS.present ? data.paceToS.value : this.paceToS,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunPreferences(')
          ..write('clubId: $clubId, ')
          ..write('paceUnit: $paceUnit, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('paceFromS: $paceFromS, ')
          ..write('paceToS: $paceToS, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clubId,
    paceUnit,
    distanceUnit,
    paceFromS,
    paceToS,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunPreferences &&
          other.clubId == this.clubId &&
          other.paceUnit == this.paceUnit &&
          other.distanceUnit == this.distanceUnit &&
          other.paceFromS == this.paceFromS &&
          other.paceToS == this.paceToS &&
          other.updatedAt == this.updatedAt);
}

class PreferencesCompanion extends UpdateCompanion<RunPreferences> {
  final Value<int> clubId;
  final Value<String> paceUnit;
  final Value<String> distanceUnit;
  final Value<int?> paceFromS;
  final Value<int?> paceToS;
  final Value<DateTime?> updatedAt;
  const PreferencesCompanion({
    this.clubId = const Value.absent(),
    this.paceUnit = const Value.absent(),
    this.distanceUnit = const Value.absent(),
    this.paceFromS = const Value.absent(),
    this.paceToS = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PreferencesCompanion.insert({
    this.clubId = const Value.absent(),
    required String paceUnit,
    required String distanceUnit,
    this.paceFromS = const Value.absent(),
    this.paceToS = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : paceUnit = Value(paceUnit),
       distanceUnit = Value(distanceUnit);
  static Insertable<RunPreferences> custom({
    Expression<int>? clubId,
    Expression<String>? paceUnit,
    Expression<String>? distanceUnit,
    Expression<int>? paceFromS,
    Expression<int>? paceToS,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (clubId != null) 'club_id': clubId,
      if (paceUnit != null) 'pace_unit': paceUnit,
      if (distanceUnit != null) 'distance_unit': distanceUnit,
      if (paceFromS != null) 'pace_from_s': paceFromS,
      if (paceToS != null) 'pace_to_s': paceToS,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PreferencesCompanion copyWith({
    Value<int>? clubId,
    Value<String>? paceUnit,
    Value<String>? distanceUnit,
    Value<int?>? paceFromS,
    Value<int?>? paceToS,
    Value<DateTime?>? updatedAt,
  }) {
    return PreferencesCompanion(
      clubId: clubId ?? this.clubId,
      paceUnit: paceUnit ?? this.paceUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      paceFromS: paceFromS ?? this.paceFromS,
      paceToS: paceToS ?? this.paceToS,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (paceUnit.present) {
      map['pace_unit'] = Variable<String>(paceUnit.value);
    }
    if (distanceUnit.present) {
      map['distance_unit'] = Variable<String>(distanceUnit.value);
    }
    if (paceFromS.present) {
      map['pace_from_s'] = Variable<int>(paceFromS.value);
    }
    if (paceToS.present) {
      map['pace_to_s'] = Variable<int>(paceToS.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('clubId: $clubId, ')
          ..write('paceUnit: $paceUnit, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('paceFromS: $paceFromS, ')
          ..write('paceToS: $paceToS, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GroupMessagesTable extends GroupMessages
    with TableInfo<$GroupMessagesTable, GroupMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorRoleMeta = const VerificationMeta(
    'authorRole',
  );
  @override
  late final GeneratedColumn<String> authorRole = GeneratedColumn<String>(
    'author_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('member'),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendStateMeta = const VerificationMeta(
    'sendState',
  );
  @override
  late final GeneratedColumn<String> sendState = GeneratedColumn<String>(
    'send_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sent'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    groupId,
    memberId,
    authorName,
    authorRole,
    body,
    createdAt,
    deletedAt,
    sendState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('author_role')) {
      context.handle(
        _authorRoleMeta,
        authorRole.isAcceptableOrUnknown(data['author_role']!, _authorRoleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('send_state')) {
      context.handle(
        _sendStateMeta,
        sendState.isAcceptableOrUnknown(data['send_state']!, _sendStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      )!,
      authorRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_role'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      sendState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}send_state'],
      )!,
    );
  }

  @override
  $GroupMessagesTable createAlias(String alias) {
    return $GroupMessagesTable(attachedDatabase, alias);
  }
}

class GroupMessage extends DataClass implements Insertable<GroupMessage> {
  final String id;
  final int clubId;
  final String groupId;
  final String memberId;

  /// First name + surname initial, as sent by the server (`Sam B.`).
  final String authorName;

  /// The author's role in this thread: `leader` | `coordinator` | `committee` | `member`.
  final String authorRole;
  final String body;
  final DateTime createdAt;
  final DateTime? deletedAt;

  /// `sent` | `pending` (outbox, retried) | `failed` (refused, Retry/Delete).
  final String sendState;
  const GroupMessage({
    required this.id,
    required this.clubId,
    required this.groupId,
    required this.memberId,
    required this.authorName,
    required this.authorRole,
    required this.body,
    required this.createdAt,
    this.deletedAt,
    required this.sendState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<int>(clubId);
    map['group_id'] = Variable<String>(groupId);
    map['member_id'] = Variable<String>(memberId);
    map['author_name'] = Variable<String>(authorName);
    map['author_role'] = Variable<String>(authorRole);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['send_state'] = Variable<String>(sendState);
    return map;
  }

  GroupMessagesCompanion toCompanion(bool nullToAbsent) {
    return GroupMessagesCompanion(
      id: Value(id),
      clubId: Value(clubId),
      groupId: Value(groupId),
      memberId: Value(memberId),
      authorName: Value(authorName),
      authorRole: Value(authorRole),
      body: Value(body),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      sendState: Value(sendState),
    );
  }

  factory GroupMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMessage(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<int>(json['clubId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      authorName: serializer.fromJson<String>(json['authorName']),
      authorRole: serializer.fromJson<String>(json['authorRole']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      sendState: serializer.fromJson<String>(json['sendState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<int>(clubId),
      'groupId': serializer.toJson<String>(groupId),
      'memberId': serializer.toJson<String>(memberId),
      'authorName': serializer.toJson<String>(authorName),
      'authorRole': serializer.toJson<String>(authorRole),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'sendState': serializer.toJson<String>(sendState),
    };
  }

  GroupMessage copyWith({
    String? id,
    int? clubId,
    String? groupId,
    String? memberId,
    String? authorName,
    String? authorRole,
    String? body,
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? sendState,
  }) => GroupMessage(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    groupId: groupId ?? this.groupId,
    memberId: memberId ?? this.memberId,
    authorName: authorName ?? this.authorName,
    authorRole: authorRole ?? this.authorRole,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    sendState: sendState ?? this.sendState,
  );
  GroupMessage copyWithCompanion(GroupMessagesCompanion data) {
    return GroupMessage(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      authorRole: data.authorRole.present
          ? data.authorRole.value
          : this.authorRole,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      sendState: data.sendState.present ? data.sendState.value : this.sendState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMessage(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('authorName: $authorName, ')
          ..write('authorRole: $authorRole, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('sendState: $sendState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    groupId,
    memberId,
    authorName,
    authorRole,
    body,
    createdAt,
    deletedAt,
    sendState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMessage &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.groupId == this.groupId &&
          other.memberId == this.memberId &&
          other.authorName == this.authorName &&
          other.authorRole == this.authorRole &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.sendState == this.sendState);
}

class GroupMessagesCompanion extends UpdateCompanion<GroupMessage> {
  final Value<String> id;
  final Value<int> clubId;
  final Value<String> groupId;
  final Value<String> memberId;
  final Value<String> authorName;
  final Value<String> authorRole;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<String> sendState;
  final Value<int> rowid;
  const GroupMessagesCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.authorRole = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.sendState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMessagesCompanion.insert({
    required String id,
    required int clubId,
    required String groupId,
    required String memberId,
    required String authorName,
    this.authorRole = const Value.absent(),
    required String body,
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.sendState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       groupId = Value(groupId),
       memberId = Value(memberId),
       authorName = Value(authorName),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<GroupMessage> custom({
    Expression<String>? id,
    Expression<int>? clubId,
    Expression<String>? groupId,
    Expression<String>? memberId,
    Expression<String>? authorName,
    Expression<String>? authorRole,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? sendState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (groupId != null) 'group_id': groupId,
      if (memberId != null) 'member_id': memberId,
      if (authorName != null) 'author_name': authorName,
      if (authorRole != null) 'author_role': authorRole,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (sendState != null) 'send_state': sendState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMessagesCompanion copyWith({
    Value<String>? id,
    Value<int>? clubId,
    Value<String>? groupId,
    Value<String>? memberId,
    Value<String>? authorName,
    Value<String>? authorRole,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<String>? sendState,
    Value<int>? rowid,
  }) {
    return GroupMessagesCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      sendState: sendState ?? this.sendState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (authorRole.present) {
      map['author_role'] = Variable<String>(authorRole.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (sendState.present) {
      map['send_state'] = Variable<String>(sendState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMessagesCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('authorName: $authorName, ')
          ..write('authorRole: $authorRole, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('sendState: $sendState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ThreadStatesTable extends ThreadStates
    with TableInfo<$ThreadStatesTable, ThreadState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThreadStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageAt =
      GeneratedColumn<DateTime>(
        'last_message_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastBodyMeta = const VerificationMeta(
    'lastBody',
  );
  @override
  late final GeneratedColumn<String> lastBody = GeneratedColumn<String>(
    'last_body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAuthorMeta = const VerificationMeta(
    'lastAuthor',
  );
  @override
  late final GeneratedColumn<String> lastAuthor = GeneratedColumn<String>(
    'last_author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mutedMeta = const VerificationMeta('muted');
  @override
  late final GeneratedColumn<bool> muted = GeneratedColumn<bool>(
    'muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _closedMeta = const VerificationMeta('closed');
  @override
  late final GeneratedColumn<bool> closed = GeneratedColumn<bool>(
    'closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    clubId,
    sessionId,
    label,
    localDate,
    lastMessageAt,
    lastBody,
    lastAuthor,
    unreadCount,
    muted,
    closed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thread_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThreadState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('last_body')) {
      context.handle(
        _lastBodyMeta,
        lastBody.isAcceptableOrUnknown(data['last_body']!, _lastBodyMeta),
      );
    }
    if (data.containsKey('last_author')) {
      context.handle(
        _lastAuthorMeta,
        lastAuthor.isAcceptableOrUnknown(data['last_author']!, _lastAuthorMeta),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('muted')) {
      context.handle(
        _mutedMeta,
        muted.isAcceptableOrUnknown(data['muted']!, _mutedMeta),
      );
    }
    if (data.containsKey('closed')) {
      context.handle(
        _closedMeta,
        closed.isAcceptableOrUnknown(data['closed']!, _closedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  ThreadState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThreadState(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_at'],
      ),
      lastBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_body'],
      ),
      lastAuthor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_author'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      muted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}muted'],
      )!,
      closed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}closed'],
      )!,
    );
  }

  @override
  $ThreadStatesTable createAlias(String alias) {
    return $ThreadStatesTable(attachedDatabase, alias);
  }
}

class ThreadState extends DataClass implements Insertable<ThreadState> {
  final String groupId;
  final int clubId;

  /// Null until the thread has been listed by `GET …/threads`.
  final String? sessionId;

  /// The group's pace/label text in the caller's units.
  final String? label;

  /// Club-local `yyyy-MM-dd` of the run.
  final String? localDate;
  final DateTime? lastMessageAt;
  final String? lastBody;
  final String? lastAuthor;
  final int unreadCount;
  final bool muted;
  final bool closed;
  const ThreadState({
    required this.groupId,
    required this.clubId,
    this.sessionId,
    this.label,
    this.localDate,
    this.lastMessageAt,
    this.lastBody,
    this.lastAuthor,
    required this.unreadCount,
    required this.muted,
    required this.closed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['club_id'] = Variable<int>(clubId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || localDate != null) {
      map['local_date'] = Variable<String>(localDate);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    if (!nullToAbsent || lastBody != null) {
      map['last_body'] = Variable<String>(lastBody);
    }
    if (!nullToAbsent || lastAuthor != null) {
      map['last_author'] = Variable<String>(lastAuthor);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['muted'] = Variable<bool>(muted);
    map['closed'] = Variable<bool>(closed);
    return map;
  }

  ThreadStatesCompanion toCompanion(bool nullToAbsent) {
    return ThreadStatesCompanion(
      groupId: Value(groupId),
      clubId: Value(clubId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      localDate: localDate == null && nullToAbsent
          ? const Value.absent()
          : Value(localDate),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      lastBody: lastBody == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBody),
      lastAuthor: lastAuthor == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAuthor),
      unreadCount: Value(unreadCount),
      muted: Value(muted),
      closed: Value(closed),
    );
  }

  factory ThreadState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThreadState(
      groupId: serializer.fromJson<String>(json['groupId']),
      clubId: serializer.fromJson<int>(json['clubId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      label: serializer.fromJson<String?>(json['label']),
      localDate: serializer.fromJson<String?>(json['localDate']),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      lastBody: serializer.fromJson<String?>(json['lastBody']),
      lastAuthor: serializer.fromJson<String?>(json['lastAuthor']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      muted: serializer.fromJson<bool>(json['muted']),
      closed: serializer.fromJson<bool>(json['closed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'clubId': serializer.toJson<int>(clubId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'label': serializer.toJson<String?>(label),
      'localDate': serializer.toJson<String?>(localDate),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'lastBody': serializer.toJson<String?>(lastBody),
      'lastAuthor': serializer.toJson<String?>(lastAuthor),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'muted': serializer.toJson<bool>(muted),
      'closed': serializer.toJson<bool>(closed),
    };
  }

  ThreadState copyWith({
    String? groupId,
    int? clubId,
    Value<String?> sessionId = const Value.absent(),
    Value<String?> label = const Value.absent(),
    Value<String?> localDate = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    Value<String?> lastBody = const Value.absent(),
    Value<String?> lastAuthor = const Value.absent(),
    int? unreadCount,
    bool? muted,
    bool? closed,
  }) => ThreadState(
    groupId: groupId ?? this.groupId,
    clubId: clubId ?? this.clubId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    label: label.present ? label.value : this.label,
    localDate: localDate.present ? localDate.value : this.localDate,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    lastBody: lastBody.present ? lastBody.value : this.lastBody,
    lastAuthor: lastAuthor.present ? lastAuthor.value : this.lastAuthor,
    unreadCount: unreadCount ?? this.unreadCount,
    muted: muted ?? this.muted,
    closed: closed ?? this.closed,
  );
  ThreadState copyWithCompanion(ThreadStatesCompanion data) {
    return ThreadState(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      label: data.label.present ? data.label.value : this.label,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      lastBody: data.lastBody.present ? data.lastBody.value : this.lastBody,
      lastAuthor: data.lastAuthor.present
          ? data.lastAuthor.value
          : this.lastAuthor,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      muted: data.muted.present ? data.muted.value : this.muted,
      closed: data.closed.present ? data.closed.value : this.closed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThreadState(')
          ..write('groupId: $groupId, ')
          ..write('clubId: $clubId, ')
          ..write('sessionId: $sessionId, ')
          ..write('label: $label, ')
          ..write('localDate: $localDate, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastBody: $lastBody, ')
          ..write('lastAuthor: $lastAuthor, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('muted: $muted, ')
          ..write('closed: $closed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    clubId,
    sessionId,
    label,
    localDate,
    lastMessageAt,
    lastBody,
    lastAuthor,
    unreadCount,
    muted,
    closed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThreadState &&
          other.groupId == this.groupId &&
          other.clubId == this.clubId &&
          other.sessionId == this.sessionId &&
          other.label == this.label &&
          other.localDate == this.localDate &&
          other.lastMessageAt == this.lastMessageAt &&
          other.lastBody == this.lastBody &&
          other.lastAuthor == this.lastAuthor &&
          other.unreadCount == this.unreadCount &&
          other.muted == this.muted &&
          other.closed == this.closed);
}

class ThreadStatesCompanion extends UpdateCompanion<ThreadState> {
  final Value<String> groupId;
  final Value<int> clubId;
  final Value<String?> sessionId;
  final Value<String?> label;
  final Value<String?> localDate;
  final Value<DateTime?> lastMessageAt;
  final Value<String?> lastBody;
  final Value<String?> lastAuthor;
  final Value<int> unreadCount;
  final Value<bool> muted;
  final Value<bool> closed;
  final Value<int> rowid;
  const ThreadStatesCompanion({
    this.groupId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.label = const Value.absent(),
    this.localDate = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastBody = const Value.absent(),
    this.lastAuthor = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.muted = const Value.absent(),
    this.closed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThreadStatesCompanion.insert({
    required String groupId,
    required int clubId,
    this.sessionId = const Value.absent(),
    this.label = const Value.absent(),
    this.localDate = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastBody = const Value.absent(),
    this.lastAuthor = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.muted = const Value.absent(),
    this.closed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       clubId = Value(clubId);
  static Insertable<ThreadState> custom({
    Expression<String>? groupId,
    Expression<int>? clubId,
    Expression<String>? sessionId,
    Expression<String>? label,
    Expression<String>? localDate,
    Expression<DateTime>? lastMessageAt,
    Expression<String>? lastBody,
    Expression<String>? lastAuthor,
    Expression<int>? unreadCount,
    Expression<bool>? muted,
    Expression<bool>? closed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (clubId != null) 'club_id': clubId,
      if (sessionId != null) 'session_id': sessionId,
      if (label != null) 'label': label,
      if (localDate != null) 'local_date': localDate,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (lastBody != null) 'last_body': lastBody,
      if (lastAuthor != null) 'last_author': lastAuthor,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (muted != null) 'muted': muted,
      if (closed != null) 'closed': closed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThreadStatesCompanion copyWith({
    Value<String>? groupId,
    Value<int>? clubId,
    Value<String?>? sessionId,
    Value<String?>? label,
    Value<String?>? localDate,
    Value<DateTime?>? lastMessageAt,
    Value<String?>? lastBody,
    Value<String?>? lastAuthor,
    Value<int>? unreadCount,
    Value<bool>? muted,
    Value<bool>? closed,
    Value<int>? rowid,
  }) {
    return ThreadStatesCompanion(
      groupId: groupId ?? this.groupId,
      clubId: clubId ?? this.clubId,
      sessionId: sessionId ?? this.sessionId,
      label: label ?? this.label,
      localDate: localDate ?? this.localDate,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastBody: lastBody ?? this.lastBody,
      lastAuthor: lastAuthor ?? this.lastAuthor,
      unreadCount: unreadCount ?? this.unreadCount,
      muted: muted ?? this.muted,
      closed: closed ?? this.closed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (lastBody.present) {
      map['last_body'] = Variable<String>(lastBody.value);
    }
    if (lastAuthor.present) {
      map['last_author'] = Variable<String>(lastAuthor.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (muted.present) {
      map['muted'] = Variable<bool>(muted.value);
    }
    if (closed.present) {
      map['closed'] = Variable<bool>(closed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThreadStatesCompanion(')
          ..write('groupId: $groupId, ')
          ..write('clubId: $clubId, ')
          ..write('sessionId: $sessionId, ')
          ..write('label: $label, ')
          ..write('localDate: $localDate, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastBody: $lastBody, ')
          ..write('lastAuthor: $lastAuthor, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('muted: $muted, ')
          ..write('closed: $closed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemberCardsTable extends MemberCards
    with TableInfo<$MemberCardsTable, MemberCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rolesCsvMeta = const VerificationMeta(
    'rolesCsv',
  );
  @override
  late final GeneratedColumn<String> rolesCsv = GeneratedColumn<String>(
    'roles_csv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hasBioMeta = const VerificationMeta('hasBio');
  @override
  late final GeneratedColumn<bool> hasBio = GeneratedColumn<bool>(
    'has_bio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_bio" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    memberId,
    clubId,
    displayName,
    photoPath,
    rolesCsv,
    hasBio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('roles_csv')) {
      context.handle(
        _rolesCsvMeta,
        rolesCsv.isAcceptableOrUnknown(data['roles_csv']!, _rolesCsvMeta),
      );
    }
    if (data.containsKey('has_bio')) {
      context.handle(
        _hasBioMeta,
        hasBio.isAcceptableOrUnknown(data['has_bio']!, _hasBioMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId};
  @override
  MemberCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberCard(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      rolesCsv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roles_csv'],
      )!,
      hasBio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_bio'],
      )!,
    );
  }

  @override
  $MemberCardsTable createAlias(String alias) {
    return $MemberCardsTable(attachedDatabase, alias);
  }
}

class MemberCard extends DataClass implements Insertable<MemberCard> {
  final String memberId;
  final int clubId;

  /// First name + surname initial (`Sam B.`).
  final String displayName;

  /// Relative signed link (`/app/clubs/1/members/<id>/photo?v=…&sig=…`) or null.
  final String? photoPath;

  /// Comma-separated subset of `leader,committee,admin` (empty for none).
  final String rolesCsv;
  final bool hasBio;
  const MemberCard({
    required this.memberId,
    required this.clubId,
    required this.displayName,
    this.photoPath,
    required this.rolesCsv,
    required this.hasBio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['club_id'] = Variable<int>(clubId);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['roles_csv'] = Variable<String>(rolesCsv);
    map['has_bio'] = Variable<bool>(hasBio);
    return map;
  }

  MemberCardsCompanion toCompanion(bool nullToAbsent) {
    return MemberCardsCompanion(
      memberId: Value(memberId),
      clubId: Value(clubId),
      displayName: Value(displayName),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      rolesCsv: Value(rolesCsv),
      hasBio: Value(hasBio),
    );
  }

  factory MemberCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberCard(
      memberId: serializer.fromJson<String>(json['memberId']),
      clubId: serializer.fromJson<int>(json['clubId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      rolesCsv: serializer.fromJson<String>(json['rolesCsv']),
      hasBio: serializer.fromJson<bool>(json['hasBio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'clubId': serializer.toJson<int>(clubId),
      'displayName': serializer.toJson<String>(displayName),
      'photoPath': serializer.toJson<String?>(photoPath),
      'rolesCsv': serializer.toJson<String>(rolesCsv),
      'hasBio': serializer.toJson<bool>(hasBio),
    };
  }

  MemberCard copyWith({
    String? memberId,
    int? clubId,
    String? displayName,
    Value<String?> photoPath = const Value.absent(),
    String? rolesCsv,
    bool? hasBio,
  }) => MemberCard(
    memberId: memberId ?? this.memberId,
    clubId: clubId ?? this.clubId,
    displayName: displayName ?? this.displayName,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    rolesCsv: rolesCsv ?? this.rolesCsv,
    hasBio: hasBio ?? this.hasBio,
  );
  MemberCard copyWithCompanion(MemberCardsCompanion data) {
    return MemberCard(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      rolesCsv: data.rolesCsv.present ? data.rolesCsv.value : this.rolesCsv,
      hasBio: data.hasBio.present ? data.hasBio.value : this.hasBio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberCard(')
          ..write('memberId: $memberId, ')
          ..write('clubId: $clubId, ')
          ..write('displayName: $displayName, ')
          ..write('photoPath: $photoPath, ')
          ..write('rolesCsv: $rolesCsv, ')
          ..write('hasBio: $hasBio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(memberId, clubId, displayName, photoPath, rolesCsv, hasBio);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberCard &&
          other.memberId == this.memberId &&
          other.clubId == this.clubId &&
          other.displayName == this.displayName &&
          other.photoPath == this.photoPath &&
          other.rolesCsv == this.rolesCsv &&
          other.hasBio == this.hasBio);
}

class MemberCardsCompanion extends UpdateCompanion<MemberCard> {
  final Value<String> memberId;
  final Value<int> clubId;
  final Value<String> displayName;
  final Value<String?> photoPath;
  final Value<String> rolesCsv;
  final Value<bool> hasBio;
  final Value<int> rowid;
  const MemberCardsCompanion({
    this.memberId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.rolesCsv = const Value.absent(),
    this.hasBio = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberCardsCompanion.insert({
    required String memberId,
    required int clubId,
    required String displayName,
    this.photoPath = const Value.absent(),
    this.rolesCsv = const Value.absent(),
    this.hasBio = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       clubId = Value(clubId),
       displayName = Value(displayName);
  static Insertable<MemberCard> custom({
    Expression<String>? memberId,
    Expression<int>? clubId,
    Expression<String>? displayName,
    Expression<String>? photoPath,
    Expression<String>? rolesCsv,
    Expression<bool>? hasBio,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (clubId != null) 'club_id': clubId,
      if (displayName != null) 'display_name': displayName,
      if (photoPath != null) 'photo_path': photoPath,
      if (rolesCsv != null) 'roles_csv': rolesCsv,
      if (hasBio != null) 'has_bio': hasBio,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberCardsCompanion copyWith({
    Value<String>? memberId,
    Value<int>? clubId,
    Value<String>? displayName,
    Value<String?>? photoPath,
    Value<String>? rolesCsv,
    Value<bool>? hasBio,
    Value<int>? rowid,
  }) {
    return MemberCardsCompanion(
      memberId: memberId ?? this.memberId,
      clubId: clubId ?? this.clubId,
      displayName: displayName ?? this.displayName,
      photoPath: photoPath ?? this.photoPath,
      rolesCsv: rolesCsv ?? this.rolesCsv,
      hasBio: hasBio ?? this.hasBio,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (rolesCsv.present) {
      map['roles_csv'] = Variable<String>(rolesCsv.value);
    }
    if (hasBio.present) {
      map['has_bio'] = Variable<bool>(hasBio.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberCardsCompanion(')
          ..write('memberId: $memberId, ')
          ..write('clubId: $clubId, ')
          ..write('displayName: $displayName, ')
          ..write('photoPath: $photoPath, ')
          ..write('rolesCsv: $rolesCsv, ')
          ..write('hasBio: $hasBio, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemberProfilesTable extends MemberProfiles
    with TableInfo<$MemberProfilesTable, MemberProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [memberId, clubId, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId, clubId};
  @override
  MemberProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberProfileRow(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $MemberProfilesTable createAlias(String alias) {
    return $MemberProfilesTable(attachedDatabase, alias);
  }
}

class MemberProfileRow extends DataClass
    implements Insertable<MemberProfileRow> {
  final String memberId;
  final int clubId;

  /// The response body, as sent.
  final String json;
  final DateTime fetchedAt;
  const MemberProfileRow({
    required this.memberId,
    required this.clubId,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['club_id'] = Variable<int>(clubId);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  MemberProfilesCompanion toCompanion(bool nullToAbsent) {
    return MemberProfilesCompanion(
      memberId: Value(memberId),
      clubId: Value(clubId),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory MemberProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberProfileRow(
      memberId: serializer.fromJson<String>(json['memberId']),
      clubId: serializer.fromJson<int>(json['clubId']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'clubId': serializer.toJson<int>(clubId),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  MemberProfileRow copyWith({
    String? memberId,
    int? clubId,
    String? json,
    DateTime? fetchedAt,
  }) => MemberProfileRow(
    memberId: memberId ?? this.memberId,
    clubId: clubId ?? this.clubId,
    json: json ?? this.json,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  MemberProfileRow copyWithCompanion(MemberProfilesCompanion data) {
    return MemberProfileRow(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberProfileRow(')
          ..write('memberId: $memberId, ')
          ..write('clubId: $clubId, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memberId, clubId, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberProfileRow &&
          other.memberId == this.memberId &&
          other.clubId == this.clubId &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class MemberProfilesCompanion extends UpdateCompanion<MemberProfileRow> {
  final Value<String> memberId;
  final Value<int> clubId;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const MemberProfilesCompanion({
    this.memberId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberProfilesCompanion.insert({
    required String memberId,
    required int clubId,
    required String json,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       clubId = Value(clubId),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<MemberProfileRow> custom({
    Expression<String>? memberId,
    Expression<int>? clubId,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (clubId != null) 'club_id': clubId,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberProfilesCompanion copyWith({
    Value<String>? memberId,
    Value<int>? clubId,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return MemberProfilesCompanion(
      memberId: memberId ?? this.memberId,
      clubId: clubId ?? this.clubId,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberProfilesCompanion(')
          ..write('memberId: $memberId, ')
          ..write('clubId: $clubId, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventLocationsTable extends EventLocations
    with TableInfo<$EventLocationsTable, EventLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    kind,
    name,
    slug,
    country,
    region,
    lat,
    lng,
    url,
    source,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventLocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventLocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $EventLocationsTable createAlias(String alias) {
    return $EventLocationsTable(attachedDatabase, alias);
  }
}

class EventLocation extends DataClass implements Insertable<EventLocation> {
  final String id;
  final int clubId;

  /// `parkrun` | `race` | `other`.
  final String kind;
  final String name;

  /// parkrun site code, e.g. `worcester`.
  final String? slug;
  final String? country;
  final String? region;
  final double? lat;
  final double? lng;
  final String? url;

  /// `import` | `manual`.
  final String source;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const EventLocation({
    required this.id,
    required this.clubId,
    required this.kind,
    required this.name,
    this.slug,
    this.country,
    this.region,
    this.lat,
    this.lng,
    this.url,
    required this.source,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<int>(clubId);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || slug != null) {
      map['slug'] = Variable<String>(slug);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['source'] = Variable<String>(source);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  EventLocationsCompanion toCompanion(bool nullToAbsent) {
    return EventLocationsCompanion(
      id: Value(id),
      clubId: Value(clubId),
      kind: Value(kind),
      name: Value(name),
      slug: slug == null && nullToAbsent ? const Value.absent() : Value(slug),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      source: Value(source),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory EventLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventLocation(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<int>(json['clubId']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      slug: serializer.fromJson<String?>(json['slug']),
      country: serializer.fromJson<String?>(json['country']),
      region: serializer.fromJson<String?>(json['region']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      url: serializer.fromJson<String?>(json['url']),
      source: serializer.fromJson<String>(json['source']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<int>(clubId),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'slug': serializer.toJson<String?>(slug),
      'country': serializer.toJson<String?>(country),
      'region': serializer.toJson<String?>(region),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'url': serializer.toJson<String?>(url),
      'source': serializer.toJson<String>(source),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  EventLocation copyWith({
    String? id,
    int? clubId,
    String? kind,
    String? name,
    Value<String?> slug = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<String?> region = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<String?> url = const Value.absent(),
    String? source,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => EventLocation(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    slug: slug.present ? slug.value : this.slug,
    country: country.present ? country.value : this.country,
    region: region.present ? region.value : this.region,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    url: url.present ? url.value : this.url,
    source: source ?? this.source,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  EventLocation copyWithCompanion(EventLocationsCompanion data) {
    return EventLocation(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      slug: data.slug.present ? data.slug.value : this.slug,
      country: data.country.present ? data.country.value : this.country,
      region: data.region.present ? data.region.value : this.region,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      url: data.url.present ? data.url.value : this.url,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventLocation(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('country: $country, ')
          ..write('region: $region, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('url: $url, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    kind,
    name,
    slug,
    country,
    region,
    lat,
    lng,
    url,
    source,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventLocation &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.slug == this.slug &&
          other.country == this.country &&
          other.region == this.region &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.url == this.url &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class EventLocationsCompanion extends UpdateCompanion<EventLocation> {
  final Value<String> id;
  final Value<int> clubId;
  final Value<String> kind;
  final Value<String> name;
  final Value<String?> slug;
  final Value<String?> country;
  final Value<String?> region;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<String?> url;
  final Value<String> source;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const EventLocationsCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.slug = const Value.absent(),
    this.country = const Value.absent(),
    this.region = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.url = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventLocationsCompanion.insert({
    required String id,
    required int clubId,
    required String kind,
    required String name,
    this.slug = const Value.absent(),
    this.country = const Value.absent(),
    this.region = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.url = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       kind = Value(kind),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<EventLocation> custom({
    Expression<String>? id,
    Expression<int>? clubId,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? slug,
    Expression<String>? country,
    Expression<String>? region,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? url,
    Expression<String>? source,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (slug != null) 'slug': slug,
      if (country != null) 'country': country,
      if (region != null) 'region': region,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (url != null) 'url': url,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventLocationsCompanion copyWith({
    Value<String>? id,
    Value<int>? clubId,
    Value<String>? kind,
    Value<String>? name,
    Value<String?>? slug,
    Value<String?>? country,
    Value<String?>? region,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<String?>? url,
    Value<String>? source,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return EventLocationsCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      country: country ?? this.country,
      region: region ?? this.region,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      url: url ?? this.url,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventLocationsCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('country: $country, ')
          ..write('region: $region, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('url: $url, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StandardsCacheTable extends StandardsCache
    with TableInfo<$StandardsCacheTable, StandardsCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StandardsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyJsonMeta = const VerificationMeta(
    'bodyJson',
  );
  @override
  late final GeneratedColumn<String> bodyJson = GeneratedColumn<String>(
    'body_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clubId, bodyJson, etag, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'standards_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<StandardsCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    }
    if (data.containsKey('body_json')) {
      context.handle(
        _bodyJsonMeta,
        bodyJson.isAcceptableOrUnknown(data['body_json']!, _bodyJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyJsonMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clubId};
  @override
  StandardsCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StandardsCacheRow(
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      bodyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_json'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $StandardsCacheTable createAlias(String alias) {
    return $StandardsCacheTable(attachedDatabase, alias);
  }
}

class StandardsCacheRow extends DataClass
    implements Insertable<StandardsCacheRow> {
  final int clubId;
  final String bodyJson;
  final String? etag;

  /// When the server last confirmed this copy (a 200 or a 304).
  final DateTime fetchedAt;
  const StandardsCacheRow({
    required this.clubId,
    required this.bodyJson,
    this.etag,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['club_id'] = Variable<int>(clubId);
    map['body_json'] = Variable<String>(bodyJson);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  StandardsCacheCompanion toCompanion(bool nullToAbsent) {
    return StandardsCacheCompanion(
      clubId: Value(clubId),
      bodyJson: Value(bodyJson),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory StandardsCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StandardsCacheRow(
      clubId: serializer.fromJson<int>(json['clubId']),
      bodyJson: serializer.fromJson<String>(json['bodyJson']),
      etag: serializer.fromJson<String?>(json['etag']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clubId': serializer.toJson<int>(clubId),
      'bodyJson': serializer.toJson<String>(bodyJson),
      'etag': serializer.toJson<String?>(etag),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  StandardsCacheRow copyWith({
    int? clubId,
    String? bodyJson,
    Value<String?> etag = const Value.absent(),
    DateTime? fetchedAt,
  }) => StandardsCacheRow(
    clubId: clubId ?? this.clubId,
    bodyJson: bodyJson ?? this.bodyJson,
    etag: etag.present ? etag.value : this.etag,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  StandardsCacheRow copyWithCompanion(StandardsCacheCompanion data) {
    return StandardsCacheRow(
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      bodyJson: data.bodyJson.present ? data.bodyJson.value : this.bodyJson,
      etag: data.etag.present ? data.etag.value : this.etag,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StandardsCacheRow(')
          ..write('clubId: $clubId, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clubId, bodyJson, etag, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StandardsCacheRow &&
          other.clubId == this.clubId &&
          other.bodyJson == this.bodyJson &&
          other.etag == this.etag &&
          other.fetchedAt == this.fetchedAt);
}

class StandardsCacheCompanion extends UpdateCompanion<StandardsCacheRow> {
  final Value<int> clubId;
  final Value<String> bodyJson;
  final Value<String?> etag;
  final Value<DateTime> fetchedAt;
  const StandardsCacheCompanion({
    this.clubId = const Value.absent(),
    this.bodyJson = const Value.absent(),
    this.etag = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  StandardsCacheCompanion.insert({
    this.clubId = const Value.absent(),
    required String bodyJson,
    this.etag = const Value.absent(),
    required DateTime fetchedAt,
  }) : bodyJson = Value(bodyJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<StandardsCacheRow> custom({
    Expression<int>? clubId,
    Expression<String>? bodyJson,
    Expression<String>? etag,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (clubId != null) 'club_id': clubId,
      if (bodyJson != null) 'body_json': bodyJson,
      if (etag != null) 'etag': etag,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  StandardsCacheCompanion copyWith({
    Value<int>? clubId,
    Value<String>? bodyJson,
    Value<String?>? etag,
    Value<DateTime>? fetchedAt,
  }) {
    return StandardsCacheCompanion(
      clubId: clubId ?? this.clubId,
      bodyJson: bodyJson ?? this.bodyJson,
      etag: etag ?? this.etag,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (bodyJson.present) {
      map['body_json'] = Variable<String>(bodyJson.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StandardsCacheCompanion(')
          ..write('clubId: $clubId, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MembershipsTable memberships = $MembershipsTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $PostsTable posts = $PostsTable(this);
  late final $InboxItemsTable inboxItems = $InboxItemsTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $VenuesTable venues = $VenuesTable(this);
  late final $SessionSeriesTable sessionSeries = $SessionSeriesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionPlansTable sessionPlans = $SessionPlansTable(this);
  late final $MyAttendanceTable myAttendance = $MyAttendanceTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $GroupMessagesTable groupMessages = $GroupMessagesTable(this);
  late final $ThreadStatesTable threadStates = $ThreadStatesTable(this);
  late final $MemberCardsTable memberCards = $MemberCardsTable(this);
  late final $MemberProfilesTable memberProfiles = $MemberProfilesTable(this);
  late final $EventLocationsTable eventLocations = $EventLocationsTable(this);
  late final $StandardsCacheTable standardsCache = $StandardsCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    memberships,
    profiles,
    posts,
    inboxItems,
    syncCursors,
    venues,
    sessionSeries,
    sessions,
    sessionPlans,
    myAttendance,
    preferences,
    groupMessages,
    threadStates,
    memberCards,
    memberProfiles,
    eventLocations,
    standardsCache,
  ];
}

typedef $$MembershipsTableCreateCompanionBuilder =
    MembershipsCompanion Function({
      required String memberId,
      required int clubId,
      required String clubName,
      required String clubSlug,
      Value<String?> joinUrl,
      required String status,
      Value<String> rolesJson,
      Value<int?> athleteId,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> gender,
      Value<String?> category,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MembershipsTableUpdateCompanionBuilder =
    MembershipsCompanion Function({
      Value<String> memberId,
      Value<int> clubId,
      Value<String> clubName,
      Value<String> clubSlug,
      Value<String?> joinUrl,
      Value<String> status,
      Value<String> rolesJson,
      Value<int?> athleteId,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> gender,
      Value<String?> category,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MembershipsTableFilterComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubName => $composableBuilder(
    column: $table.clubName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubSlug => $composableBuilder(
    column: $table.clubSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joinUrl => $composableBuilder(
    column: $table.joinUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolesJson => $composableBuilder(
    column: $table.rolesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get athleteId => $composableBuilder(
    column: $table.athleteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MembershipsTableOrderingComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubName => $composableBuilder(
    column: $table.clubName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubSlug => $composableBuilder(
    column: $table.clubSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joinUrl => $composableBuilder(
    column: $table.joinUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolesJson => $composableBuilder(
    column: $table.rolesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get athleteId => $composableBuilder(
    column: $table.athleteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MembershipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get clubName =>
      $composableBuilder(column: $table.clubName, builder: (column) => column);

  GeneratedColumn<String> get clubSlug =>
      $composableBuilder(column: $table.clubSlug, builder: (column) => column);

  GeneratedColumn<String> get joinUrl =>
      $composableBuilder(column: $table.joinUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get rolesJson =>
      $composableBuilder(column: $table.rolesJson, builder: (column) => column);

  GeneratedColumn<int> get athleteId =>
      $composableBuilder(column: $table.athleteId, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MembershipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembershipsTable,
          Membership,
          $$MembershipsTableFilterComposer,
          $$MembershipsTableOrderingComposer,
          $$MembershipsTableAnnotationComposer,
          $$MembershipsTableCreateCompanionBuilder,
          $$MembershipsTableUpdateCompanionBuilder,
          (
            Membership,
            BaseReferences<_$AppDatabase, $MembershipsTable, Membership>,
          ),
          Membership,
          PrefetchHooks Function()
        > {
  $$MembershipsTableTableManager(_$AppDatabase db, $MembershipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembershipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembershipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembershipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> clubName = const Value.absent(),
                Value<String> clubSlug = const Value.absent(),
                Value<String?> joinUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> rolesJson = const Value.absent(),
                Value<int?> athleteId = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembershipsCompanion(
                memberId: memberId,
                clubId: clubId,
                clubName: clubName,
                clubSlug: clubSlug,
                joinUrl: joinUrl,
                status: status,
                rolesJson: rolesJson,
                athleteId: athleteId,
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                category: category,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required int clubId,
                required String clubName,
                required String clubSlug,
                Value<String?> joinUrl = const Value.absent(),
                required String status,
                Value<String> rolesJson = const Value.absent(),
                Value<int?> athleteId = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MembershipsCompanion.insert(
                memberId: memberId,
                clubId: clubId,
                clubName: clubName,
                clubSlug: clubSlug,
                joinUrl: joinUrl,
                status: status,
                rolesJson: rolesJson,
                athleteId: athleteId,
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                category: category,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MembershipsTable, Membership>(table),
                  BaseReferences<_$AppDatabase, $MembershipsTable, Membership>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MembershipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembershipsTable,
      Membership,
      $$MembershipsTableFilterComposer,
      $$MembershipsTableOrderingComposer,
      $$MembershipsTableAnnotationComposer,
      $$MembershipsTableCreateCompanionBuilder,
      $$MembershipsTableUpdateCompanionBuilder,
      (
        Membership,
        BaseReferences<_$AppDatabase, $MembershipsTable, Membership>,
      ),
      Membership,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String memberId,
  required int clubId,
  required String status,
  Value<String> rolesJson,
  Value<int?> athleteRowId,
  Value<int?> athleteId,
  Value<String?> po10Guid,
  Value<String?> firstName,
  Value<String?> lastName,
  Value<String?> gender,
  Value<String?> category,
  Value<bool> active,
  Value<bool> affiliated,
  Value<String?> competitiveRegStatus,
  Value<String?> firstClaimClubName,
  Value<String?> resultsUrl,
  Value<String?> powerOf10Url,
  Value<String?> claimAwardUrl,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> memberId,
  Value<int> clubId,
  Value<String> status,
  Value<String> rolesJson,
  Value<int?> athleteRowId,
  Value<int?> athleteId,
  Value<String?> po10Guid,
  Value<String?> firstName,
  Value<String?> lastName,
  Value<String?> gender,
  Value<String?> category,
  Value<bool> active,
  Value<bool> affiliated,
  Value<String?> competitiveRegStatus,
  Value<String?> firstClaimClubName,
  Value<String?> resultsUrl,
  Value<String?> powerOf10Url,
  Value<String?> claimAwardUrl,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolesJson => $composableBuilder(
    column: $table.rolesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get athleteRowId => $composableBuilder(
    column: $table.athleteRowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get athleteId => $composableBuilder(
    column: $table.athleteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get po10Guid => $composableBuilder(
    column: $table.po10Guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get affiliated => $composableBuilder(
    column: $table.affiliated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get competitiveRegStatus => $composableBuilder(
    column: $table.competitiveRegStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstClaimClubName => $composableBuilder(
    column: $table.firstClaimClubName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultsUrl => $composableBuilder(
    column: $table.resultsUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get powerOf10Url => $composableBuilder(
    column: $table.powerOf10Url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimAwardUrl => $composableBuilder(
    column: $table.claimAwardUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolesJson => $composableBuilder(
    column: $table.rolesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get athleteRowId => $composableBuilder(
    column: $table.athleteRowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get athleteId => $composableBuilder(
    column: $table.athleteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get po10Guid => $composableBuilder(
    column: $table.po10Guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get affiliated => $composableBuilder(
    column: $table.affiliated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get competitiveRegStatus => $composableBuilder(
    column: $table.competitiveRegStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstClaimClubName => $composableBuilder(
    column: $table.firstClaimClubName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultsUrl => $composableBuilder(
    column: $table.resultsUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get powerOf10Url => $composableBuilder(
    column: $table.powerOf10Url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimAwardUrl => $composableBuilder(
    column: $table.claimAwardUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get rolesJson =>
      $composableBuilder(column: $table.rolesJson, builder: (column) => column);

  GeneratedColumn<int> get athleteRowId => $composableBuilder(
    column: $table.athleteRowId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get athleteId =>
      $composableBuilder(column: $table.athleteId, builder: (column) => column);

  GeneratedColumn<String> get po10Guid =>
      $composableBuilder(column: $table.po10Guid, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<bool> get affiliated => $composableBuilder(
    column: $table.affiliated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get competitiveRegStatus => $composableBuilder(
    column: $table.competitiveRegStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firstClaimClubName => $composableBuilder(
    column: $table.firstClaimClubName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultsUrl => $composableBuilder(
    column: $table.resultsUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get powerOf10Url => $composableBuilder(
    column: $table.powerOf10Url,
    builder: (column) => column,
  );

  GeneratedColumn<String> get claimAwardUrl => $composableBuilder(
    column: $table.claimAwardUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> rolesJson = const Value.absent(),
                Value<int?> athleteRowId = const Value.absent(),
                Value<int?> athleteId = const Value.absent(),
                Value<String?> po10Guid = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> affiliated = const Value.absent(),
                Value<String?> competitiveRegStatus = const Value.absent(),
                Value<String?> firstClaimClubName = const Value.absent(),
                Value<String?> resultsUrl = const Value.absent(),
                Value<String?> powerOf10Url = const Value.absent(),
                Value<String?> claimAwardUrl = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                memberId: memberId,
                clubId: clubId,
                status: status,
                rolesJson: rolesJson,
                athleteRowId: athleteRowId,
                athleteId: athleteId,
                po10Guid: po10Guid,
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                category: category,
                active: active,
                affiliated: affiliated,
                competitiveRegStatus: competitiveRegStatus,
                firstClaimClubName: firstClaimClubName,
                resultsUrl: resultsUrl,
                powerOf10Url: powerOf10Url,
                claimAwardUrl: claimAwardUrl,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required int clubId,
                required String status,
                Value<String> rolesJson = const Value.absent(),
                Value<int?> athleteRowId = const Value.absent(),
                Value<int?> athleteId = const Value.absent(),
                Value<String?> po10Guid = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> affiliated = const Value.absent(),
                Value<String?> competitiveRegStatus = const Value.absent(),
                Value<String?> firstClaimClubName = const Value.absent(),
                Value<String?> resultsUrl = const Value.absent(),
                Value<String?> powerOf10Url = const Value.absent(),
                Value<String?> claimAwardUrl = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                memberId: memberId,
                clubId: clubId,
                status: status,
                rolesJson: rolesJson,
                athleteRowId: athleteRowId,
                athleteId: athleteId,
                po10Guid: po10Guid,
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                category: category,
                active: active,
                affiliated: affiliated,
                competitiveRegStatus: competitiveRegStatus,
                firstClaimClubName: firstClaimClubName,
                resultsUrl: resultsUrl,
                powerOf10Url: powerOf10Url,
                claimAwardUrl: claimAwardUrl,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, Profile>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, Profile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$PostsTableCreateCompanionBuilder = PostsCompanion Function({
  required String id,
  required int clubId,
  required String title,
  required String bodyMd,
  Value<String> priority,
  Value<String> audience,
  required DateTime publishedAt,
  Value<DateTime?> pinnedUntil,
  required String authorMemberId,
  required String authorName,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PostsTableUpdateCompanionBuilder = PostsCompanion Function({
  Value<String> id,
  Value<int> clubId,
  Value<String> title,
  Value<String> bodyMd,
  Value<String> priority,
  Value<String> audience,
  Value<DateTime> publishedAt,
  Value<DateTime?> pinnedUntil,
  Value<String> authorMemberId,
  Value<String> authorName,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PostsTableFilterComposer extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyMd => $composableBuilder(
    column: $table.bodyMd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audience => $composableBuilder(
    column: $table.audience,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pinnedUntil => $composableBuilder(
    column: $table.pinnedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PostsTableOrderingComposer
    extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyMd => $composableBuilder(
    column: $table.bodyMd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audience => $composableBuilder(
    column: $table.audience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pinnedUntil => $composableBuilder(
    column: $table.pinnedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get bodyMd =>
      $composableBuilder(column: $table.bodyMd, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get audience =>
      $composableBuilder(column: $table.audience, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pinnedUntil => $composableBuilder(
    column: $table.pinnedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostsTable,
          Post,
          $$PostsTableFilterComposer,
          $$PostsTableOrderingComposer,
          $$PostsTableAnnotationComposer,
          $$PostsTableCreateCompanionBuilder,
          $$PostsTableUpdateCompanionBuilder,
          (Post, BaseReferences<_$AppDatabase, $PostsTable, Post>),
          Post,
          PrefetchHooks Function()
        > {
  $$PostsTableTableManager(_$AppDatabase db, $PostsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> bodyMd = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> audience = const Value.absent(),
                Value<DateTime> publishedAt = const Value.absent(),
                Value<DateTime?> pinnedUntil = const Value.absent(),
                Value<String> authorMemberId = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PostsCompanion(
                id: id,
                clubId: clubId,
                title: title,
                bodyMd: bodyMd,
                priority: priority,
                audience: audience,
                publishedAt: publishedAt,
                pinnedUntil: pinnedUntil,
                authorMemberId: authorMemberId,
                authorName: authorName,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clubId,
                required String title,
                required String bodyMd,
                Value<String> priority = const Value.absent(),
                Value<String> audience = const Value.absent(),
                required DateTime publishedAt,
                Value<DateTime?> pinnedUntil = const Value.absent(),
                required String authorMemberId,
                required String authorName,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PostsCompanion.insert(
                id: id,
                clubId: clubId,
                title: title,
                bodyMd: bodyMd,
                priority: priority,
                audience: audience,
                publishedAt: publishedAt,
                pinnedUntil: pinnedUntil,
                authorMemberId: authorMemberId,
                authorName: authorName,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PostsTable, Post>(table),
                  BaseReferences<_$AppDatabase, $PostsTable, Post>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostsTable,
      Post,
      $$PostsTableFilterComposer,
      $$PostsTableOrderingComposer,
      $$PostsTableAnnotationComposer,
      $$PostsTableCreateCompanionBuilder,
      $$PostsTableUpdateCompanionBuilder,
      (Post, BaseReferences<_$AppDatabase, $PostsTable, Post>),
      Post,
      PrefetchHooks Function()
    >;
typedef $$InboxItemsTableCreateCompanionBuilder = InboxItemsCompanion Function({
  required String id,
  required int clubId,
  required String category,
  required String title,
  required String body,
  Value<String> dataJson,
  required DateTime createdAt,
  Value<DateTime?> readAt,
  Value<bool> readPending,
  Value<int> rowid,
});
typedef $$InboxItemsTableUpdateCompanionBuilder = InboxItemsCompanion Function({
  Value<String> id,
  Value<int> clubId,
  Value<String> category,
  Value<String> title,
  Value<String> body,
  Value<String> dataJson,
  Value<DateTime> createdAt,
  Value<DateTime?> readAt,
  Value<bool> readPending,
  Value<int> rowid,
});

class $$InboxItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get readPending => $composableBuilder(
    column: $table.readPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InboxItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get readPending => $composableBuilder(
    column: $table.readPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InboxItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<bool> get readPending => $composableBuilder(
    column: $table.readPending,
    builder: (column) => column,
  );
}

class $$InboxItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InboxItemsTable,
          InboxItem,
          $$InboxItemsTableFilterComposer,
          $$InboxItemsTableOrderingComposer,
          $$InboxItemsTableAnnotationComposer,
          $$InboxItemsTableCreateCompanionBuilder,
          $$InboxItemsTableUpdateCompanionBuilder,
          (
            InboxItem,
            BaseReferences<_$AppDatabase, $InboxItemsTable, InboxItem>,
          ),
          InboxItem,
          PrefetchHooks Function()
        > {
  $$InboxItemsTableTableManager(_$AppDatabase db, $InboxItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InboxItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InboxItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InboxItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<bool> readPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboxItemsCompanion(
                id: id,
                clubId: clubId,
                category: category,
                title: title,
                body: body,
                dataJson: dataJson,
                createdAt: createdAt,
                readAt: readAt,
                readPending: readPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clubId,
                required String category,
                required String title,
                required String body,
                Value<String> dataJson = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> readAt = const Value.absent(),
                Value<bool> readPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboxItemsCompanion.insert(
                id: id,
                clubId: clubId,
                category: category,
                title: title,
                body: body,
                dataJson: dataJson,
                createdAt: createdAt,
                readAt: readAt,
                readPending: readPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InboxItemsTable, InboxItem>(table),
                  BaseReferences<_$AppDatabase, $InboxItemsTable, InboxItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InboxItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InboxItemsTable,
      InboxItem,
      $$InboxItemsTableFilterComposer,
      $$InboxItemsTableOrderingComposer,
      $$InboxItemsTableAnnotationComposer,
      $$InboxItemsTableCreateCompanionBuilder,
      $$InboxItemsTableUpdateCompanionBuilder,
      (InboxItem, BaseReferences<_$AppDatabase, $InboxItemsTable, InboxItem>),
      InboxItem,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String key,
      required String serverTime,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> key,
      Value<String> serverTime,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => column,
  );
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> serverTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                key: key,
                serverTime: serverTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String serverTime,
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                key: key,
                serverTime: serverTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursor>(table),
                  BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursor,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
      ),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$VenuesTableCreateCompanionBuilder = VenuesCompanion Function({
  required String id,
  required int clubId,
  required String name,
  Value<String?> address,
  Value<double?> lat,
  Value<double?> lng,
  Value<String?> notes,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$VenuesTableUpdateCompanionBuilder = VenuesCompanion Function({
  Value<String> id,
  Value<int> clubId,
  Value<String> name,
  Value<String?> address,
  Value<double?> lat,
  Value<double?> lng,
  Value<String?> notes,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$VenuesTableFilterComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VenuesTableOrderingComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VenuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VenuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VenuesTable,
          Venue,
          $$VenuesTableFilterComposer,
          $$VenuesTableOrderingComposer,
          $$VenuesTableAnnotationComposer,
          $$VenuesTableCreateCompanionBuilder,
          $$VenuesTableUpdateCompanionBuilder,
          (Venue, BaseReferences<_$AppDatabase, $VenuesTable, Venue>),
          Venue,
          PrefetchHooks Function()
        > {
  $$VenuesTableTableManager(_$AppDatabase db, $VenuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VenuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VenuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VenuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenuesCompanion(
                id: id,
                clubId: clubId,
                name: name,
                address: address,
                lat: lat,
                lng: lng,
                notes: notes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clubId,
                required String name,
                Value<String?> address = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VenuesCompanion.insert(
                id: id,
                clubId: clubId,
                name: name,
                address: address,
                lat: lat,
                lng: lng,
                notes: notes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VenuesTable, Venue>(table),
                  BaseReferences<_$AppDatabase, $VenuesTable, Venue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VenuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VenuesTable,
      Venue,
      $$VenuesTableFilterComposer,
      $$VenuesTableOrderingComposer,
      $$VenuesTableAnnotationComposer,
      $$VenuesTableCreateCompanionBuilder,
      $$VenuesTableUpdateCompanionBuilder,
      (Venue, BaseReferences<_$AppDatabase, $VenuesTable, Venue>),
      Venue,
      PrefetchHooks Function()
    >;
typedef $$SessionSeriesTableCreateCompanionBuilder =
    SessionSeriesCompanion Function({
      required String id,
      required int clubId,
      required String title,
      Value<String?> description,
      Value<String?> venueId,
      required int weekday,
      required String startTime,
      Value<int?> durationMin,
      Value<int> intervalWeeks,
      required String validFrom,
      Value<String?> validUntil,
      required String groupMode,
      Value<String?> cmsSlug,
      Value<String?> imageUrl,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SessionSeriesTableUpdateCompanionBuilder =
    SessionSeriesCompanion Function({
      Value<String> id,
      Value<int> clubId,
      Value<String> title,
      Value<String?> description,
      Value<String?> venueId,
      Value<int> weekday,
      Value<String> startTime,
      Value<int?> durationMin,
      Value<int> intervalWeeks,
      Value<String> validFrom,
      Value<String?> validUntil,
      Value<String> groupMode,
      Value<String?> cmsSlug,
      Value<String?> imageUrl,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SessionSeriesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionSeriesTable> {
  $$SessionSeriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venueId => $composableBuilder(
    column: $table.venueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalWeeks => $composableBuilder(
    column: $table.intervalWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupMode => $composableBuilder(
    column: $table.groupMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cmsSlug => $composableBuilder(
    column: $table.cmsSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionSeriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionSeriesTable> {
  $$SessionSeriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venueId => $composableBuilder(
    column: $table.venueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalWeeks => $composableBuilder(
    column: $table.intervalWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupMode => $composableBuilder(
    column: $table.groupMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cmsSlug => $composableBuilder(
    column: $table.cmsSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionSeriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionSeriesTable> {
  $$SessionSeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalWeeks => $composableBuilder(
    column: $table.intervalWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<String> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupMode =>
      $composableBuilder(column: $table.groupMode, builder: (column) => column);

  GeneratedColumn<String> get cmsSlug =>
      $composableBuilder(column: $table.cmsSlug, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SessionSeriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionSeriesTable,
          RunSeries,
          $$SessionSeriesTableFilterComposer,
          $$SessionSeriesTableOrderingComposer,
          $$SessionSeriesTableAnnotationComposer,
          $$SessionSeriesTableCreateCompanionBuilder,
          $$SessionSeriesTableUpdateCompanionBuilder,
          (
            RunSeries,
            BaseReferences<_$AppDatabase, $SessionSeriesTable, RunSeries>,
          ),
          RunSeries,
          PrefetchHooks Function()
        > {
  $$SessionSeriesTableTableManager(_$AppDatabase db, $SessionSeriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionSeriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionSeriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionSeriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> venueId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<int> intervalWeeks = const Value.absent(),
                Value<String> validFrom = const Value.absent(),
                Value<String?> validUntil = const Value.absent(),
                Value<String> groupMode = const Value.absent(),
                Value<String?> cmsSlug = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionSeriesCompanion(
                id: id,
                clubId: clubId,
                title: title,
                description: description,
                venueId: venueId,
                weekday: weekday,
                startTime: startTime,
                durationMin: durationMin,
                intervalWeeks: intervalWeeks,
                validFrom: validFrom,
                validUntil: validUntil,
                groupMode: groupMode,
                cmsSlug: cmsSlug,
                imageUrl: imageUrl,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clubId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> venueId = const Value.absent(),
                required int weekday,
                required String startTime,
                Value<int?> durationMin = const Value.absent(),
                Value<int> intervalWeeks = const Value.absent(),
                required String validFrom,
                Value<String?> validUntil = const Value.absent(),
                required String groupMode,
                Value<String?> cmsSlug = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionSeriesCompanion.insert(
                id: id,
                clubId: clubId,
                title: title,
                description: description,
                venueId: venueId,
                weekday: weekday,
                startTime: startTime,
                durationMin: durationMin,
                intervalWeeks: intervalWeeks,
                validFrom: validFrom,
                validUntil: validUntil,
                groupMode: groupMode,
                cmsSlug: cmsSlug,
                imageUrl: imageUrl,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionSeriesTable, RunSeries>(table),
                  BaseReferences<_$AppDatabase, $SessionSeriesTable, RunSeries>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionSeriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionSeriesTable,
      RunSeries,
      $$SessionSeriesTableFilterComposer,
      $$SessionSeriesTableOrderingComposer,
      $$SessionSeriesTableAnnotationComposer,
      $$SessionSeriesTableCreateCompanionBuilder,
      $$SessionSeriesTableUpdateCompanionBuilder,
      (
        RunSeries,
        BaseReferences<_$AppDatabase, $SessionSeriesTable, RunSeries>,
      ),
      RunSeries,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required int clubId,
  Value<String?> seriesId,
  Value<String?> occurrenceDate,
  required String title,
  Value<String?> venueId,
  Value<String?> notes,
  required DateTime startsAt,
  required DateTime endsAt,
  required String localDate,
  required String localStartTime,
  Value<String?> localEndTime,
  required String groupMode,
  Value<String> status,
  Value<String?> cancelReason,
  Value<String?> imageUrl,
  Value<String?> coordinatorMemberId,
  Value<String?> coordinatorName,
  Value<bool> isDetached,
  Value<String?> originalJson,
  Value<String?> groupsJson,
  Value<String?> summaryJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<int> clubId,
  Value<String?> seriesId,
  Value<String?> occurrenceDate,
  Value<String> title,
  Value<String?> venueId,
  Value<String?> notes,
  Value<DateTime> startsAt,
  Value<DateTime> endsAt,
  Value<String> localDate,
  Value<String> localStartTime,
  Value<String?> localEndTime,
  Value<String> groupMode,
  Value<String> status,
  Value<String?> cancelReason,
  Value<String?> imageUrl,
  Value<String?> coordinatorMemberId,
  Value<String?> coordinatorName,
  Value<bool> isDetached,
  Value<String?> originalJson,
  Value<String?> groupsJson,
  Value<String?> summaryJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venueId => $composableBuilder(
    column: $table.venueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localStartTime => $composableBuilder(
    column: $table.localStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localEndTime => $composableBuilder(
    column: $table.localEndTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupMode => $composableBuilder(
    column: $table.groupMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coordinatorMemberId => $composableBuilder(
    column: $table.coordinatorMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coordinatorName => $composableBuilder(
    column: $table.coordinatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDetached => $composableBuilder(
    column: $table.isDetached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalJson => $composableBuilder(
    column: $table.originalJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupsJson => $composableBuilder(
    column: $table.groupsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venueId => $composableBuilder(
    column: $table.venueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localStartTime => $composableBuilder(
    column: $table.localStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localEndTime => $composableBuilder(
    column: $table.localEndTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupMode => $composableBuilder(
    column: $table.groupMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coordinatorMemberId => $composableBuilder(
    column: $table.coordinatorMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coordinatorName => $composableBuilder(
    column: $table.coordinatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDetached => $composableBuilder(
    column: $table.isDetached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalJson => $composableBuilder(
    column: $table.originalJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupsJson => $composableBuilder(
    column: $table.groupsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get localStartTime => $composableBuilder(
    column: $table.localStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localEndTime => $composableBuilder(
    column: $table.localEndTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupMode =>
      $composableBuilder(column: $table.groupMode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get coordinatorMemberId => $composableBuilder(
    column: $table.coordinatorMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coordinatorName => $composableBuilder(
    column: $table.coordinatorName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDetached => $composableBuilder(
    column: $table.isDetached,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalJson => $composableBuilder(
    column: $table.originalJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupsJson => $composableBuilder(
    column: $table.groupsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> occurrenceDate = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> venueId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<DateTime> endsAt = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String> localStartTime = const Value.absent(),
                Value<String?> localEndTime = const Value.absent(),
                Value<String> groupMode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> coordinatorMemberId = const Value.absent(),
                Value<String?> coordinatorName = const Value.absent(),
                Value<bool> isDetached = const Value.absent(),
                Value<String?> originalJson = const Value.absent(),
                Value<String?> groupsJson = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                clubId: clubId,
                seriesId: seriesId,
                occurrenceDate: occurrenceDate,
                title: title,
                venueId: venueId,
                notes: notes,
                startsAt: startsAt,
                endsAt: endsAt,
                localDate: localDate,
                localStartTime: localStartTime,
                localEndTime: localEndTime,
                groupMode: groupMode,
                status: status,
                cancelReason: cancelReason,
                imageUrl: imageUrl,
                coordinatorMemberId: coordinatorMemberId,
                coordinatorName: coordinatorName,
                isDetached: isDetached,
                originalJson: originalJson,
                groupsJson: groupsJson,
                summaryJson: summaryJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clubId,
                Value<String?> seriesId = const Value.absent(),
                Value<String?> occurrenceDate = const Value.absent(),
                required String title,
                Value<String?> venueId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime startsAt,
                required DateTime endsAt,
                required String localDate,
                required String localStartTime,
                Value<String?> localEndTime = const Value.absent(),
                required String groupMode,
                Value<String> status = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> coordinatorMemberId = const Value.absent(),
                Value<String?> coordinatorName = const Value.absent(),
                Value<bool> isDetached = const Value.absent(),
                Value<String?> originalJson = const Value.absent(),
                Value<String?> groupsJson = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                clubId: clubId,
                seriesId: seriesId,
                occurrenceDate: occurrenceDate,
                title: title,
                venueId: venueId,
                notes: notes,
                startsAt: startsAt,
                endsAt: endsAt,
                localDate: localDate,
                localStartTime: localStartTime,
                localEndTime: localEndTime,
                groupMode: groupMode,
                status: status,
                cancelReason: cancelReason,
                imageUrl: imageUrl,
                coordinatorMemberId: coordinatorMemberId,
                coordinatorName: coordinatorName,
                isDetached: isDetached,
                originalJson: originalJson,
                groupsJson: groupsJson,
                summaryJson: summaryJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, Session>(table),
                  BaseReferences<_$AppDatabase, $SessionsTable, Session>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$SessionPlansTableCreateCompanionBuilder =
    SessionPlansCompanion Function({
      required String sessionId,
      required int clubId,
      required String json,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$SessionPlansTableUpdateCompanionBuilder =
    SessionPlansCompanion Function({
      Value<String> sessionId,
      Value<int> clubId,
      Value<String> json,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$SessionPlansTableFilterComposer
    extends Composer<_$AppDatabase, $SessionPlansTable> {
  $$SessionPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionPlansTable> {
  $$SessionPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionPlansTable> {
  $$SessionPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$SessionPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionPlansTable,
          SessionPlanRow,
          $$SessionPlansTableFilterComposer,
          $$SessionPlansTableOrderingComposer,
          $$SessionPlansTableAnnotationComposer,
          $$SessionPlansTableCreateCompanionBuilder,
          $$SessionPlansTableUpdateCompanionBuilder,
          (
            SessionPlanRow,
            BaseReferences<_$AppDatabase, $SessionPlansTable, SessionPlanRow>,
          ),
          SessionPlanRow,
          PrefetchHooks Function()
        > {
  $$SessionPlansTableTableManager(_$AppDatabase db, $SessionPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionPlansCompanion(
                sessionId: sessionId,
                clubId: clubId,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int clubId,
                required String json,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionPlansCompanion.insert(
                sessionId: sessionId,
                clubId: clubId,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionPlansTable, SessionPlanRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SessionPlansTable,
                    SessionPlanRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionPlansTable,
      SessionPlanRow,
      $$SessionPlansTableFilterComposer,
      $$SessionPlansTableOrderingComposer,
      $$SessionPlansTableAnnotationComposer,
      $$SessionPlansTableCreateCompanionBuilder,
      $$SessionPlansTableUpdateCompanionBuilder,
      (
        SessionPlanRow,
        BaseReferences<_$AppDatabase, $SessionPlansTable, SessionPlanRow>,
      ),
      SessionPlanRow,
      PrefetchHooks Function()
    >;
typedef $$MyAttendanceTableCreateCompanionBuilder =
    MyAttendanceCompanion Function({
      required String sessionId,
      required int clubId,
      required String status,
      Value<String?> groupId,
      Value<String?> paceUnit,
      Value<int?> paceFromS,
      Value<int?> paceToS,
      Value<bool> pending,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MyAttendanceTableUpdateCompanionBuilder =
    MyAttendanceCompanion Function({
      Value<String> sessionId,
      Value<int> clubId,
      Value<String> status,
      Value<String?> groupId,
      Value<String?> paceUnit,
      Value<int?> paceFromS,
      Value<int?> paceToS,
      Value<bool> pending,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MyAttendanceTableFilterComposer
    extends Composer<_$AppDatabase, $MyAttendanceTable> {
  $$MyAttendanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paceUnit => $composableBuilder(
    column: $table.paceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceFromS => $composableBuilder(
    column: $table.paceFromS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceToS => $composableBuilder(
    column: $table.paceToS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MyAttendanceTableOrderingComposer
    extends Composer<_$AppDatabase, $MyAttendanceTable> {
  $$MyAttendanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paceUnit => $composableBuilder(
    column: $table.paceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceFromS => $composableBuilder(
    column: $table.paceFromS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceToS => $composableBuilder(
    column: $table.paceToS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MyAttendanceTableAnnotationComposer
    extends Composer<_$AppDatabase, $MyAttendanceTable> {
  $$MyAttendanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get paceUnit =>
      $composableBuilder(column: $table.paceUnit, builder: (column) => column);

  GeneratedColumn<int> get paceFromS =>
      $composableBuilder(column: $table.paceFromS, builder: (column) => column);

  GeneratedColumn<int> get paceToS =>
      $composableBuilder(column: $table.paceToS, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MyAttendanceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MyAttendanceTable,
          MyAttendanceRow,
          $$MyAttendanceTableFilterComposer,
          $$MyAttendanceTableOrderingComposer,
          $$MyAttendanceTableAnnotationComposer,
          $$MyAttendanceTableCreateCompanionBuilder,
          $$MyAttendanceTableUpdateCompanionBuilder,
          (
            MyAttendanceRow,
            BaseReferences<_$AppDatabase, $MyAttendanceTable, MyAttendanceRow>,
          ),
          MyAttendanceRow,
          PrefetchHooks Function()
        > {
  $$MyAttendanceTableTableManager(_$AppDatabase db, $MyAttendanceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MyAttendanceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MyAttendanceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MyAttendanceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> paceUnit = const Value.absent(),
                Value<int?> paceFromS = const Value.absent(),
                Value<int?> paceToS = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MyAttendanceCompanion(
                sessionId: sessionId,
                clubId: clubId,
                status: status,
                groupId: groupId,
                paceUnit: paceUnit,
                paceFromS: paceFromS,
                paceToS: paceToS,
                pending: pending,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int clubId,
                required String status,
                Value<String?> groupId = const Value.absent(),
                Value<String?> paceUnit = const Value.absent(),
                Value<int?> paceFromS = const Value.absent(),
                Value<int?> paceToS = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MyAttendanceCompanion.insert(
                sessionId: sessionId,
                clubId: clubId,
                status: status,
                groupId: groupId,
                paceUnit: paceUnit,
                paceFromS: paceFromS,
                paceToS: paceToS,
                pending: pending,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MyAttendanceTable, MyAttendanceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MyAttendanceTable,
                    MyAttendanceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MyAttendanceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MyAttendanceTable,
      MyAttendanceRow,
      $$MyAttendanceTableFilterComposer,
      $$MyAttendanceTableOrderingComposer,
      $$MyAttendanceTableAnnotationComposer,
      $$MyAttendanceTableCreateCompanionBuilder,
      $$MyAttendanceTableUpdateCompanionBuilder,
      (
        MyAttendanceRow,
        BaseReferences<_$AppDatabase, $MyAttendanceTable, MyAttendanceRow>,
      ),
      MyAttendanceRow,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      Value<int> clubId,
      required String paceUnit,
      required String distanceUnit,
      Value<int?> paceFromS,
      Value<int?> paceToS,
      Value<DateTime?> updatedAt,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<int> clubId,
      Value<String> paceUnit,
      Value<String> distanceUnit,
      Value<int?> paceFromS,
      Value<int?> paceToS,
      Value<DateTime?> updatedAt,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paceUnit => $composableBuilder(
    column: $table.paceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceFromS => $composableBuilder(
    column: $table.paceFromS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceToS => $composableBuilder(
    column: $table.paceToS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paceUnit => $composableBuilder(
    column: $table.paceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceFromS => $composableBuilder(
    column: $table.paceFromS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceToS => $composableBuilder(
    column: $table.paceToS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get paceUnit =>
      $composableBuilder(column: $table.paceUnit, builder: (column) => column);

  GeneratedColumn<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paceFromS =>
      $composableBuilder(column: $table.paceFromS, builder: (column) => column);

  GeneratedColumn<int> get paceToS =>
      $composableBuilder(column: $table.paceToS, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          RunPreferences,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            RunPreferences,
            BaseReferences<_$AppDatabase, $PreferencesTable, RunPreferences>,
          ),
          RunPreferences,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> clubId = const Value.absent(),
                Value<String> paceUnit = const Value.absent(),
                Value<String> distanceUnit = const Value.absent(),
                Value<int?> paceFromS = const Value.absent(),
                Value<int?> paceToS = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => PreferencesCompanion(
                clubId: clubId,
                paceUnit: paceUnit,
                distanceUnit: distanceUnit,
                paceFromS: paceFromS,
                paceToS: paceToS,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> clubId = const Value.absent(),
                required String paceUnit,
                required String distanceUnit,
                Value<int?> paceFromS = const Value.absent(),
                Value<int?> paceToS = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => PreferencesCompanion.insert(
                clubId: clubId,
                paceUnit: paceUnit,
                distanceUnit: distanceUnit,
                paceFromS: paceFromS,
                paceToS: paceToS,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, RunPreferences>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PreferencesTable,
                    RunPreferences
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      RunPreferences,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        RunPreferences,
        BaseReferences<_$AppDatabase, $PreferencesTable, RunPreferences>,
      ),
      RunPreferences,
      PrefetchHooks Function()
    >;
typedef $$GroupMessagesTableCreateCompanionBuilder =
    GroupMessagesCompanion Function({
      required String id,
      required int clubId,
      required String groupId,
      required String memberId,
      required String authorName,
      Value<String> authorRole,
      required String body,
      required DateTime createdAt,
      Value<DateTime?> deletedAt,
      Value<String> sendState,
      Value<int> rowid,
    });
typedef $$GroupMessagesTableUpdateCompanionBuilder =
    GroupMessagesCompanion Function({
      Value<String> id,
      Value<int> clubId,
      Value<String> groupId,
      Value<String> memberId,
      Value<String> authorName,
      Value<String> authorRole,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<String> sendState,
      Value<int> rowid,
    });

class $$GroupMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMessagesTable> {
  $$GroupMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorRole => $composableBuilder(
    column: $table.authorRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sendState => $composableBuilder(
    column: $table.sendState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMessagesTable> {
  $$GroupMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorRole => $composableBuilder(
    column: $table.authorRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sendState => $composableBuilder(
    column: $table.sendState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMessagesTable> {
  $$GroupMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorRole => $composableBuilder(
    column: $table.authorRole,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get sendState =>
      $composableBuilder(column: $table.sendState, builder: (column) => column);
}

class $$GroupMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupMessagesTable,
          GroupMessage,
          $$GroupMessagesTableFilterComposer,
          $$GroupMessagesTableOrderingComposer,
          $$GroupMessagesTableAnnotationComposer,
          $$GroupMessagesTableCreateCompanionBuilder,
          $$GroupMessagesTableUpdateCompanionBuilder,
          (
            GroupMessage,
            BaseReferences<_$AppDatabase, $GroupMessagesTable, GroupMessage>,
          ),
          GroupMessage,
          PrefetchHooks Function()
        > {
  $$GroupMessagesTableTableManager(_$AppDatabase db, $GroupMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<String> authorRole = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> sendState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMessagesCompanion(
                id: id,
                clubId: clubId,
                groupId: groupId,
                memberId: memberId,
                authorName: authorName,
                authorRole: authorRole,
                body: body,
                createdAt: createdAt,
                deletedAt: deletedAt,
                sendState: sendState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clubId,
                required String groupId,
                required String memberId,
                required String authorName,
                Value<String> authorRole = const Value.absent(),
                required String body,
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> sendState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMessagesCompanion.insert(
                id: id,
                clubId: clubId,
                groupId: groupId,
                memberId: memberId,
                authorName: authorName,
                authorRole: authorRole,
                body: body,
                createdAt: createdAt,
                deletedAt: deletedAt,
                sendState: sendState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupMessagesTable, GroupMessage>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $GroupMessagesTable,
                    GroupMessage
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupMessagesTable,
      GroupMessage,
      $$GroupMessagesTableFilterComposer,
      $$GroupMessagesTableOrderingComposer,
      $$GroupMessagesTableAnnotationComposer,
      $$GroupMessagesTableCreateCompanionBuilder,
      $$GroupMessagesTableUpdateCompanionBuilder,
      (
        GroupMessage,
        BaseReferences<_$AppDatabase, $GroupMessagesTable, GroupMessage>,
      ),
      GroupMessage,
      PrefetchHooks Function()
    >;
typedef $$ThreadStatesTableCreateCompanionBuilder =
    ThreadStatesCompanion Function({
      required String groupId,
      required int clubId,
      Value<String?> sessionId,
      Value<String?> label,
      Value<String?> localDate,
      Value<DateTime?> lastMessageAt,
      Value<String?> lastBody,
      Value<String?> lastAuthor,
      Value<int> unreadCount,
      Value<bool> muted,
      Value<bool> closed,
      Value<int> rowid,
    });
typedef $$ThreadStatesTableUpdateCompanionBuilder =
    ThreadStatesCompanion Function({
      Value<String> groupId,
      Value<int> clubId,
      Value<String?> sessionId,
      Value<String?> label,
      Value<String?> localDate,
      Value<DateTime?> lastMessageAt,
      Value<String?> lastBody,
      Value<String?> lastAuthor,
      Value<int> unreadCount,
      Value<bool> muted,
      Value<bool> closed,
      Value<int> rowid,
    });

class $$ThreadStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ThreadStatesTable> {
  $$ThreadStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastBody => $composableBuilder(
    column: $table.lastBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAuthor => $composableBuilder(
    column: $table.lastAuthor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get muted => $composableBuilder(
    column: $table.muted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ThreadStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ThreadStatesTable> {
  $$ThreadStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastBody => $composableBuilder(
    column: $table.lastBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAuthor => $composableBuilder(
    column: $table.lastAuthor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get muted => $composableBuilder(
    column: $table.muted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ThreadStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThreadStatesTable> {
  $$ThreadStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastBody =>
      $composableBuilder(column: $table.lastBody, builder: (column) => column);

  GeneratedColumn<String> get lastAuthor => $composableBuilder(
    column: $table.lastAuthor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get muted =>
      $composableBuilder(column: $table.muted, builder: (column) => column);

  GeneratedColumn<bool> get closed =>
      $composableBuilder(column: $table.closed, builder: (column) => column);
}

class $$ThreadStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ThreadStatesTable,
          ThreadState,
          $$ThreadStatesTableFilterComposer,
          $$ThreadStatesTableOrderingComposer,
          $$ThreadStatesTableAnnotationComposer,
          $$ThreadStatesTableCreateCompanionBuilder,
          $$ThreadStatesTableUpdateCompanionBuilder,
          (
            ThreadState,
            BaseReferences<_$AppDatabase, $ThreadStatesTable, ThreadState>,
          ),
          ThreadState,
          PrefetchHooks Function()
        > {
  $$ThreadStatesTableTableManager(_$AppDatabase db, $ThreadStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThreadStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThreadStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThreadStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> localDate = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<String?> lastBody = const Value.absent(),
                Value<String?> lastAuthor = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> muted = const Value.absent(),
                Value<bool> closed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ThreadStatesCompanion(
                groupId: groupId,
                clubId: clubId,
                sessionId: sessionId,
                label: label,
                localDate: localDate,
                lastMessageAt: lastMessageAt,
                lastBody: lastBody,
                lastAuthor: lastAuthor,
                unreadCount: unreadCount,
                muted: muted,
                closed: closed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required int clubId,
                Value<String?> sessionId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> localDate = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<String?> lastBody = const Value.absent(),
                Value<String?> lastAuthor = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> muted = const Value.absent(),
                Value<bool> closed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ThreadStatesCompanion.insert(
                groupId: groupId,
                clubId: clubId,
                sessionId: sessionId,
                label: label,
                localDate: localDate,
                lastMessageAt: lastMessageAt,
                lastBody: lastBody,
                lastAuthor: lastAuthor,
                unreadCount: unreadCount,
                muted: muted,
                closed: closed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ThreadStatesTable, ThreadState>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ThreadStatesTable,
                    ThreadState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ThreadStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ThreadStatesTable,
      ThreadState,
      $$ThreadStatesTableFilterComposer,
      $$ThreadStatesTableOrderingComposer,
      $$ThreadStatesTableAnnotationComposer,
      $$ThreadStatesTableCreateCompanionBuilder,
      $$ThreadStatesTableUpdateCompanionBuilder,
      (
        ThreadState,
        BaseReferences<_$AppDatabase, $ThreadStatesTable, ThreadState>,
      ),
      ThreadState,
      PrefetchHooks Function()
    >;
typedef $$MemberCardsTableCreateCompanionBuilder =
    MemberCardsCompanion Function({
      required String memberId,
      required int clubId,
      required String displayName,
      Value<String?> photoPath,
      Value<String> rolesCsv,
      Value<bool> hasBio,
      Value<int> rowid,
    });
typedef $$MemberCardsTableUpdateCompanionBuilder =
    MemberCardsCompanion Function({
      Value<String> memberId,
      Value<int> clubId,
      Value<String> displayName,
      Value<String?> photoPath,
      Value<String> rolesCsv,
      Value<bool> hasBio,
      Value<int> rowid,
    });

class $$MemberCardsTableFilterComposer
    extends Composer<_$AppDatabase, $MemberCardsTable> {
  $$MemberCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolesCsv => $composableBuilder(
    column: $table.rolesCsv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasBio => $composableBuilder(
    column: $table.hasBio,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemberCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemberCardsTable> {
  $$MemberCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolesCsv => $composableBuilder(
    column: $table.rolesCsv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasBio => $composableBuilder(
    column: $table.hasBio,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemberCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemberCardsTable> {
  $$MemberCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get rolesCsv =>
      $composableBuilder(column: $table.rolesCsv, builder: (column) => column);

  GeneratedColumn<bool> get hasBio =>
      $composableBuilder(column: $table.hasBio, builder: (column) => column);
}

class $$MemberCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemberCardsTable,
          MemberCard,
          $$MemberCardsTableFilterComposer,
          $$MemberCardsTableOrderingComposer,
          $$MemberCardsTableAnnotationComposer,
          $$MemberCardsTableCreateCompanionBuilder,
          $$MemberCardsTableUpdateCompanionBuilder,
          (
            MemberCard,
            BaseReferences<_$AppDatabase, $MemberCardsTable, MemberCard>,
          ),
          MemberCard,
          PrefetchHooks Function()
        > {
  $$MemberCardsTableTableManager(_$AppDatabase db, $MemberCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemberCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String> rolesCsv = const Value.absent(),
                Value<bool> hasBio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberCardsCompanion(
                memberId: memberId,
                clubId: clubId,
                displayName: displayName,
                photoPath: photoPath,
                rolesCsv: rolesCsv,
                hasBio: hasBio,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required int clubId,
                required String displayName,
                Value<String?> photoPath = const Value.absent(),
                Value<String> rolesCsv = const Value.absent(),
                Value<bool> hasBio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberCardsCompanion.insert(
                memberId: memberId,
                clubId: clubId,
                displayName: displayName,
                photoPath: photoPath,
                rolesCsv: rolesCsv,
                hasBio: hasBio,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemberCardsTable, MemberCard>(table),
                  BaseReferences<_$AppDatabase, $MemberCardsTable, MemberCard>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemberCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemberCardsTable,
      MemberCard,
      $$MemberCardsTableFilterComposer,
      $$MemberCardsTableOrderingComposer,
      $$MemberCardsTableAnnotationComposer,
      $$MemberCardsTableCreateCompanionBuilder,
      $$MemberCardsTableUpdateCompanionBuilder,
      (
        MemberCard,
        BaseReferences<_$AppDatabase, $MemberCardsTable, MemberCard>,
      ),
      MemberCard,
      PrefetchHooks Function()
    >;
typedef $$MemberProfilesTableCreateCompanionBuilder =
    MemberProfilesCompanion Function({
      required String memberId,
      required int clubId,
      required String json,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$MemberProfilesTableUpdateCompanionBuilder =
    MemberProfilesCompanion Function({
      Value<String> memberId,
      Value<int> clubId,
      Value<String> json,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$MemberProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $MemberProfilesTable> {
  $$MemberProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemberProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $MemberProfilesTable> {
  $$MemberProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemberProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemberProfilesTable> {
  $$MemberProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$MemberProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemberProfilesTable,
          MemberProfileRow,
          $$MemberProfilesTableFilterComposer,
          $$MemberProfilesTableOrderingComposer,
          $$MemberProfilesTableAnnotationComposer,
          $$MemberProfilesTableCreateCompanionBuilder,
          $$MemberProfilesTableUpdateCompanionBuilder,
          (
            MemberProfileRow,
            BaseReferences<
              _$AppDatabase,
              $MemberProfilesTable,
              MemberProfileRow
            >,
          ),
          MemberProfileRow,
          PrefetchHooks Function()
        > {
  $$MemberProfilesTableTableManager(
    _$AppDatabase db,
    $MemberProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemberProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberProfilesCompanion(
                memberId: memberId,
                clubId: clubId,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required int clubId,
                required String json,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => MemberProfilesCompanion.insert(
                memberId: memberId,
                clubId: clubId,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemberProfilesTable, MemberProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MemberProfilesTable,
                    MemberProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemberProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemberProfilesTable,
      MemberProfileRow,
      $$MemberProfilesTableFilterComposer,
      $$MemberProfilesTableOrderingComposer,
      $$MemberProfilesTableAnnotationComposer,
      $$MemberProfilesTableCreateCompanionBuilder,
      $$MemberProfilesTableUpdateCompanionBuilder,
      (
        MemberProfileRow,
        BaseReferences<_$AppDatabase, $MemberProfilesTable, MemberProfileRow>,
      ),
      MemberProfileRow,
      PrefetchHooks Function()
    >;
typedef $$EventLocationsTableCreateCompanionBuilder =
    EventLocationsCompanion Function({
      required String id,
      required int clubId,
      required String kind,
      required String name,
      Value<String?> slug,
      Value<String?> country,
      Value<String?> region,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> url,
      Value<String> source,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$EventLocationsTableUpdateCompanionBuilder =
    EventLocationsCompanion Function({
      Value<String> id,
      Value<int> clubId,
      Value<String> kind,
      Value<String> name,
      Value<String?> slug,
      Value<String?> country,
      Value<String?> region,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> url,
      Value<String> source,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$EventLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $EventLocationsTable> {
  $$EventLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventLocationsTable> {
  $$EventLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventLocationsTable> {
  $$EventLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$EventLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventLocationsTable,
          EventLocation,
          $$EventLocationsTableFilterComposer,
          $$EventLocationsTableOrderingComposer,
          $$EventLocationsTableAnnotationComposer,
          $$EventLocationsTableCreateCompanionBuilder,
          $$EventLocationsTableUpdateCompanionBuilder,
          (
            EventLocation,
            BaseReferences<_$AppDatabase, $EventLocationsTable, EventLocation>,
          ),
          EventLocation,
          PrefetchHooks Function()
        > {
  $$EventLocationsTableTableManager(
    _$AppDatabase db,
    $EventLocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> slug = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventLocationsCompanion(
                id: id,
                clubId: clubId,
                kind: kind,
                name: name,
                slug: slug,
                country: country,
                region: region,
                lat: lat,
                lng: lng,
                url: url,
                source: source,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clubId,
                required String kind,
                required String name,
                Value<String?> slug = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String> source = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventLocationsCompanion.insert(
                id: id,
                clubId: clubId,
                kind: kind,
                name: name,
                slug: slug,
                country: country,
                region: region,
                lat: lat,
                lng: lng,
                url: url,
                source: source,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventLocationsTable, EventLocation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EventLocationsTable,
                    EventLocation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventLocationsTable,
      EventLocation,
      $$EventLocationsTableFilterComposer,
      $$EventLocationsTableOrderingComposer,
      $$EventLocationsTableAnnotationComposer,
      $$EventLocationsTableCreateCompanionBuilder,
      $$EventLocationsTableUpdateCompanionBuilder,
      (
        EventLocation,
        BaseReferences<_$AppDatabase, $EventLocationsTable, EventLocation>,
      ),
      EventLocation,
      PrefetchHooks Function()
    >;
typedef $$StandardsCacheTableCreateCompanionBuilder =
    StandardsCacheCompanion Function({
      Value<int> clubId,
      required String bodyJson,
      Value<String?> etag,
      required DateTime fetchedAt,
    });
typedef $$StandardsCacheTableUpdateCompanionBuilder =
    StandardsCacheCompanion Function({
      Value<int> clubId,
      Value<String> bodyJson,
      Value<String?> etag,
      Value<DateTime> fetchedAt,
    });

class $$StandardsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $StandardsCacheTable> {
  $$StandardsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyJson => $composableBuilder(
    column: $table.bodyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StandardsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $StandardsCacheTable> {
  $$StandardsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyJson => $composableBuilder(
    column: $table.bodyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StandardsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $StandardsCacheTable> {
  $$StandardsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get bodyJson =>
      $composableBuilder(column: $table.bodyJson, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$StandardsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StandardsCacheTable,
          StandardsCacheRow,
          $$StandardsCacheTableFilterComposer,
          $$StandardsCacheTableOrderingComposer,
          $$StandardsCacheTableAnnotationComposer,
          $$StandardsCacheTableCreateCompanionBuilder,
          $$StandardsCacheTableUpdateCompanionBuilder,
          (
            StandardsCacheRow,
            BaseReferences<
              _$AppDatabase,
              $StandardsCacheTable,
              StandardsCacheRow
            >,
          ),
          StandardsCacheRow,
          PrefetchHooks Function()
        > {
  $$StandardsCacheTableTableManager(
    _$AppDatabase db,
    $StandardsCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StandardsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StandardsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StandardsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> clubId = const Value.absent(),
                Value<String> bodyJson = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => StandardsCacheCompanion(
                clubId: clubId,
                bodyJson: bodyJson,
                etag: etag,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> clubId = const Value.absent(),
                required String bodyJson,
                Value<String?> etag = const Value.absent(),
                required DateTime fetchedAt,
              }) => StandardsCacheCompanion.insert(
                clubId: clubId,
                bodyJson: bodyJson,
                etag: etag,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StandardsCacheTable, StandardsCacheRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StandardsCacheTable,
                    StandardsCacheRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StandardsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StandardsCacheTable,
      StandardsCacheRow,
      $$StandardsCacheTableFilterComposer,
      $$StandardsCacheTableOrderingComposer,
      $$StandardsCacheTableAnnotationComposer,
      $$StandardsCacheTableCreateCompanionBuilder,
      $$StandardsCacheTableUpdateCompanionBuilder,
      (
        StandardsCacheRow,
        BaseReferences<_$AppDatabase, $StandardsCacheTable, StandardsCacheRow>,
      ),
      StandardsCacheRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MembershipsTableTableManager get memberships =>
      $$MembershipsTableTableManager(_db, _db.memberships);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$PostsTableTableManager get posts =>
      $$PostsTableTableManager(_db, _db.posts);
  $$InboxItemsTableTableManager get inboxItems =>
      $$InboxItemsTableTableManager(_db, _db.inboxItems);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$VenuesTableTableManager get venues =>
      $$VenuesTableTableManager(_db, _db.venues);
  $$SessionSeriesTableTableManager get sessionSeries =>
      $$SessionSeriesTableTableManager(_db, _db.sessionSeries);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionPlansTableTableManager get sessionPlans =>
      $$SessionPlansTableTableManager(_db, _db.sessionPlans);
  $$MyAttendanceTableTableManager get myAttendance =>
      $$MyAttendanceTableTableManager(_db, _db.myAttendance);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$GroupMessagesTableTableManager get groupMessages =>
      $$GroupMessagesTableTableManager(_db, _db.groupMessages);
  $$ThreadStatesTableTableManager get threadStates =>
      $$ThreadStatesTableTableManager(_db, _db.threadStates);
  $$MemberCardsTableTableManager get memberCards =>
      $$MemberCardsTableTableManager(_db, _db.memberCards);
  $$MemberProfilesTableTableManager get memberProfiles =>
      $$MemberProfilesTableTableManager(_db, _db.memberProfiles);
  $$EventLocationsTableTableManager get eventLocations =>
      $$EventLocationsTableTableManager(_db, _db.eventLocations);
  $$StandardsCacheTableTableManager get standardsCache =>
      $$StandardsCacheTableTableManager(_db, _db.standardsCache);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The database for the active account. Watching [activeSubProvider] means switching
/// account disposes (closes) this database and opens the other account's file, and
/// every provider that watches this one rebuilds, so users' data never mix.
///
/// Only read this while signed in; the router guarantees that for app screens.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The database for the active account. Watching [activeSubProvider] means switching
/// account disposes (closes) this database and opens the other account's file, and
/// every provider that watches this one rebuilds, so users' data never mix.
///
/// Only read this while signed in; the router guarantees that for app screens.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The database for the active account. Watching [activeSubProvider] means switching
  /// account disposes (closes) this database and opens the other account's file, and
  /// every provider that watches this one rebuilds, so users' data never mix.
  ///
  /// Only read this while signed in; the router guarantees that for app screens.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'c53f99994ee018e22e8a8b76414168e87ed384fb';
