// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_state_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQueueStateModelCollection on Isar {
  IsarCollection<QueueStateModel> get queueStateModels => this.collection();
}

const QueueStateModelSchema = CollectionSchema(
  name: r'QueueStateModel',
  id: -2865731356462994832,
  properties: {
    r'autoQueueIds': PropertySchema(
      id: 0,
      name: r'autoQueueIds',
      type: IsarType.string,
    ),
    r'currentPositionMs': PropertySchema(
      id: 1,
      name: r'currentPositionMs',
      type: IsarType.long,
    ),
    r'currentTrackId': PropertySchema(
      id: 2,
      name: r'currentTrackId',
      type: IsarType.string,
    ),
    r'queueSource': PropertySchema(
      id: 3,
      name: r'queueSource',
      type: IsarType.string,
    ),
    r'repeatMode': PropertySchema(
      id: 4,
      name: r'repeatMode',
      type: IsarType.byte,
      enumMap: _QueueStateModelrepeatModeEnumValueMap,
    ),
    r'shuffleEnabled': PropertySchema(
      id: 5,
      name: r'shuffleEnabled',
      type: IsarType.bool,
    ),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _queueStateModelEstimateSize,
  serialize: _queueStateModelSerialize,
  deserialize: _queueStateModelDeserialize,
  deserializeProp: _queueStateModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _queueStateModelGetId,
  getLinks: _queueStateModelGetLinks,
  attach: _queueStateModelAttach,
  version: '3.1.0+1',
);

int _queueStateModelEstimateSize(
  QueueStateModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.autoQueueIds;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.currentTrackId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.queueSource;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _queueStateModelSerialize(
  QueueStateModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.autoQueueIds);
  writer.writeLong(offsets[1], object.currentPositionMs);
  writer.writeString(offsets[2], object.currentTrackId);
  writer.writeString(offsets[3], object.queueSource);
  writer.writeByte(offsets[4], object.repeatMode.index);
  writer.writeBool(offsets[5], object.shuffleEnabled);
  writer.writeDateTime(offsets[6], object.updatedAt);
}

QueueStateModel _queueStateModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = QueueStateModel();
  object.autoQueueIds = reader.readStringOrNull(offsets[0]);
  object.currentPositionMs = reader.readLong(offsets[1]);
  object.currentTrackId = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.queueSource = reader.readStringOrNull(offsets[3]);
  object.repeatMode = _QueueStateModelrepeatModeValueEnumMap[
          reader.readByteOrNull(offsets[4])] ??
      RepeatMode.off;
  object.shuffleEnabled = reader.readBool(offsets[5]);
  object.updatedAt = reader.readDateTime(offsets[6]);
  return object;
}

P _queueStateModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (_QueueStateModelrepeatModeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          RepeatMode.off) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _QueueStateModelrepeatModeEnumValueMap = {
  'off': 0,
  'all': 1,
  'one': 2,
};
const _QueueStateModelrepeatModeValueEnumMap = {
  0: RepeatMode.off,
  1: RepeatMode.all,
  2: RepeatMode.one,
};

Id _queueStateModelGetId(QueueStateModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _queueStateModelGetLinks(QueueStateModel object) {
  return [];
}

void _queueStateModelAttach(
    IsarCollection<dynamic> col, Id id, QueueStateModel object) {
  object.id = id;
}

extension QueueStateModelQueryWhereSort
    on QueryBuilder<QueueStateModel, QueueStateModel, QWhere> {
  QueryBuilder<QueueStateModel, QueueStateModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension QueueStateModelQueryWhere
    on QueryBuilder<QueueStateModel, QueueStateModel, QWhereClause> {
  QueryBuilder<QueueStateModel, QueueStateModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension QueueStateModelQueryFilter
    on QueryBuilder<QueueStateModel, QueueStateModel, QFilterCondition> {
  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'autoQueueIds',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'autoQueueIds',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoQueueIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'autoQueueIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'autoQueueIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'autoQueueIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'autoQueueIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'autoQueueIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'autoQueueIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'autoQueueIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoQueueIds',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      autoQueueIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'autoQueueIds',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentPositionMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentPositionMs',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentPositionMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentPositionMs',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentPositionMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentPositionMs',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentPositionMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentPositionMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currentTrackId',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currentTrackId',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentTrackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentTrackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentTrackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentTrackId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currentTrackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currentTrackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currentTrackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currentTrackId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentTrackId',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      currentTrackIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currentTrackId',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'queueSource',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'queueSource',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queueSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'queueSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'queueSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'queueSource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'queueSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'queueSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'queueSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'queueSource',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queueSource',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      queueSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'queueSource',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      repeatModeEqualTo(RepeatMode value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatMode',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      repeatModeGreaterThan(
    RepeatMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repeatMode',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      repeatModeLessThan(
    RepeatMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repeatMode',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      repeatModeBetween(
    RepeatMode lower,
    RepeatMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repeatMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      shuffleEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shuffleEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension QueueStateModelQueryObject
    on QueryBuilder<QueueStateModel, QueueStateModel, QFilterCondition> {}

extension QueueStateModelQueryLinks
    on QueryBuilder<QueueStateModel, QueueStateModel, QFilterCondition> {}

extension QueueStateModelQuerySortBy
    on QueryBuilder<QueueStateModel, QueueStateModel, QSortBy> {
  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByAutoQueueIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoQueueIds', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByAutoQueueIdsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoQueueIds', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByCurrentPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPositionMs', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByCurrentPositionMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPositionMs', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByCurrentTrackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentTrackId', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByCurrentTrackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentTrackId', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByQueueSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueSource', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByQueueSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueSource', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByRepeatMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatMode', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByRepeatModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatMode', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByShuffleEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffleEnabled', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByShuffleEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffleEnabled', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension QueueStateModelQuerySortThenBy
    on QueryBuilder<QueueStateModel, QueueStateModel, QSortThenBy> {
  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByAutoQueueIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoQueueIds', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByAutoQueueIdsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoQueueIds', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByCurrentPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPositionMs', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByCurrentPositionMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPositionMs', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByCurrentTrackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentTrackId', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByCurrentTrackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentTrackId', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByQueueSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueSource', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByQueueSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueSource', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByRepeatMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatMode', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByRepeatModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatMode', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByShuffleEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffleEnabled', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByShuffleEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffleEnabled', Sort.desc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension QueueStateModelQueryWhereDistinct
    on QueryBuilder<QueueStateModel, QueueStateModel, QDistinct> {
  QueryBuilder<QueueStateModel, QueueStateModel, QDistinct>
      distinctByAutoQueueIds({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoQueueIds', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QDistinct>
      distinctByCurrentPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentPositionMs');
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QDistinct>
      distinctByCurrentTrackId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentTrackId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QDistinct>
      distinctByQueueSource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'queueSource', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QDistinct>
      distinctByRepeatMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatMode');
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QDistinct>
      distinctByShuffleEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shuffleEnabled');
    });
  }

  QueryBuilder<QueueStateModel, QueueStateModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension QueueStateModelQueryProperty
    on QueryBuilder<QueueStateModel, QueueStateModel, QQueryProperty> {
  QueryBuilder<QueueStateModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<QueueStateModel, String?, QQueryOperations>
      autoQueueIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoQueueIds');
    });
  }

  QueryBuilder<QueueStateModel, int, QQueryOperations>
      currentPositionMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentPositionMs');
    });
  }

  QueryBuilder<QueueStateModel, String?, QQueryOperations>
      currentTrackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentTrackId');
    });
  }

  QueryBuilder<QueueStateModel, String?, QQueryOperations>
      queueSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'queueSource');
    });
  }

  QueryBuilder<QueueStateModel, RepeatMode, QQueryOperations>
      repeatModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatMode');
    });
  }

  QueryBuilder<QueueStateModel, bool, QQueryOperations>
      shuffleEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shuffleEnabled');
    });
  }

  QueryBuilder<QueueStateModel, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
