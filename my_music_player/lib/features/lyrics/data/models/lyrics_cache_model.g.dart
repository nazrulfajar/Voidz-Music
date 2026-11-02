// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_cache_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLyricsCacheModelCollection on Isar {
  IsarCollection<LyricsCacheModel> get lyricsCacheModels => this.collection();
}

const LyricsCacheModelSchema = CollectionSchema(
  name: r'LyricsCacheModel',
  id: -2447507694338704551,
  properties: {
    r'fetchedAt': PropertySchema(
      id: 0,
      name: r'fetchedAt',
      type: IsarType.dateTime,
    ),
    r'lyricsType': PropertySchema(
      id: 1,
      name: r'lyricsType',
      type: IsarType.byte,
      enumMap: _LyricsCacheModellyricsTypeEnumValueMap,
    ),
    r'plainLyrics': PropertySchema(
      id: 2,
      name: r'plainLyrics',
      type: IsarType.string,
    ),
    r'sourceId': PropertySchema(
      id: 3,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'syncedLyrics': PropertySchema(
      id: 4,
      name: r'syncedLyrics',
      type: IsarType.string,
    )
  },
  estimateSize: _lyricsCacheModelEstimateSize,
  serialize: _lyricsCacheModelSerialize,
  deserialize: _lyricsCacheModelDeserialize,
  deserializeProp: _lyricsCacheModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'sourceId': IndexSchema(
      id: 2155220942429093580,
      name: r'sourceId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'sourceId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _lyricsCacheModelGetId,
  getLinks: _lyricsCacheModelGetLinks,
  attach: _lyricsCacheModelAttach,
  version: '3.1.0+1',
);

int _lyricsCacheModelEstimateSize(
  LyricsCacheModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.plainLyrics;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceId.length * 3;
  {
    final value = object.syncedLyrics;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _lyricsCacheModelSerialize(
  LyricsCacheModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.fetchedAt);
  writer.writeByte(offsets[1], object.lyricsType.index);
  writer.writeString(offsets[2], object.plainLyrics);
  writer.writeString(offsets[3], object.sourceId);
  writer.writeString(offsets[4], object.syncedLyrics);
}

LyricsCacheModel _lyricsCacheModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LyricsCacheModel();
  object.fetchedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.lyricsType = _LyricsCacheModellyricsTypeValueEnumMap[
          reader.readByteOrNull(offsets[1])] ??
      LyricsType.synced;
  object.plainLyrics = reader.readStringOrNull(offsets[2]);
  object.sourceId = reader.readString(offsets[3]);
  object.syncedLyrics = reader.readStringOrNull(offsets[4]);
  return object;
}

P _lyricsCacheModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (_LyricsCacheModellyricsTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          LyricsType.synced) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _LyricsCacheModellyricsTypeEnumValueMap = {
  'synced': 0,
  'plain': 1,
  'notFound': 2,
};
const _LyricsCacheModellyricsTypeValueEnumMap = {
  0: LyricsType.synced,
  1: LyricsType.plain,
  2: LyricsType.notFound,
};

Id _lyricsCacheModelGetId(LyricsCacheModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _lyricsCacheModelGetLinks(LyricsCacheModel object) {
  return [];
}

void _lyricsCacheModelAttach(
    IsarCollection<dynamic> col, Id id, LyricsCacheModel object) {
  object.id = id;
}

extension LyricsCacheModelByIndex on IsarCollection<LyricsCacheModel> {
  Future<LyricsCacheModel?> getBySourceId(String sourceId) {
    return getByIndex(r'sourceId', [sourceId]);
  }

  LyricsCacheModel? getBySourceIdSync(String sourceId) {
    return getByIndexSync(r'sourceId', [sourceId]);
  }

  Future<bool> deleteBySourceId(String sourceId) {
    return deleteByIndex(r'sourceId', [sourceId]);
  }

  bool deleteBySourceIdSync(String sourceId) {
    return deleteByIndexSync(r'sourceId', [sourceId]);
  }

  Future<List<LyricsCacheModel?>> getAllBySourceId(
      List<String> sourceIdValues) {
    final values = sourceIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'sourceId', values);
  }

  List<LyricsCacheModel?> getAllBySourceIdSync(List<String> sourceIdValues) {
    final values = sourceIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'sourceId', values);
  }

  Future<int> deleteAllBySourceId(List<String> sourceIdValues) {
    final values = sourceIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'sourceId', values);
  }

  int deleteAllBySourceIdSync(List<String> sourceIdValues) {
    final values = sourceIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sourceId', values);
  }

  Future<Id> putBySourceId(LyricsCacheModel object) {
    return putByIndex(r'sourceId', object);
  }

  Id putBySourceIdSync(LyricsCacheModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'sourceId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySourceId(List<LyricsCacheModel> objects) {
    return putAllByIndex(r'sourceId', objects);
  }

  List<Id> putAllBySourceIdSync(List<LyricsCacheModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'sourceId', objects, saveLinks: saveLinks);
  }
}

extension LyricsCacheModelQueryWhereSort
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QWhere> {
  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LyricsCacheModelQueryWhere
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QWhereClause> {
  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterWhereClause>
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

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterWhereClause>
      sourceIdEqualTo(String sourceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sourceId',
        value: [sourceId],
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterWhereClause>
      sourceIdNotEqualTo(String sourceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceId',
              lower: [],
              upper: [sourceId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceId',
              lower: [sourceId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceId',
              lower: [sourceId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceId',
              lower: [],
              upper: [sourceId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LyricsCacheModelQueryFilter
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QFilterCondition> {
  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      fetchedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      fetchedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      fetchedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      fetchedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fetchedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
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

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
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

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
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

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      lyricsTypeEqualTo(LyricsType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lyricsType',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      lyricsTypeGreaterThan(
    LyricsType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lyricsType',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      lyricsTypeLessThan(
    LyricsType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lyricsType',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      lyricsTypeBetween(
    LyricsType lower,
    LyricsType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lyricsType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'plainLyrics',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'plainLyrics',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plainLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plainLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plainLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plainLyrics',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'plainLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'plainLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'plainLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'plainLyrics',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plainLyrics',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      plainLyricsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'plainLyrics',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceId',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceId',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'syncedLyrics',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'syncedLyrics',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedLyrics',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncedLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncedLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncedLyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncedLyrics',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedLyrics',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterFilterCondition>
      syncedLyricsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncedLyrics',
        value: '',
      ));
    });
  }
}

extension LyricsCacheModelQueryObject
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QFilterCondition> {}

extension LyricsCacheModelQueryLinks
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QFilterCondition> {}

extension LyricsCacheModelQuerySortBy
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QSortBy> {
  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortByLyricsType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lyricsType', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortByLyricsTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lyricsType', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortByPlainLyrics() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plainLyrics', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortByPlainLyricsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plainLyrics', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortBySyncedLyrics() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedLyrics', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      sortBySyncedLyricsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedLyrics', Sort.desc);
    });
  }
}

extension LyricsCacheModelQuerySortThenBy
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QSortThenBy> {
  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenByLyricsType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lyricsType', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenByLyricsTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lyricsType', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenByPlainLyrics() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plainLyrics', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenByPlainLyricsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plainLyrics', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenBySyncedLyrics() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedLyrics', Sort.asc);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QAfterSortBy>
      thenBySyncedLyricsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedLyrics', Sort.desc);
    });
  }
}

extension LyricsCacheModelQueryWhereDistinct
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QDistinct> {
  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QDistinct>
      distinctByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fetchedAt');
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QDistinct>
      distinctByLyricsType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lyricsType');
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QDistinct>
      distinctByPlainLyrics({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plainLyrics', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QDistinct>
      distinctBySourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsCacheModel, QDistinct>
      distinctBySyncedLyrics({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedLyrics', caseSensitive: caseSensitive);
    });
  }
}

extension LyricsCacheModelQueryProperty
    on QueryBuilder<LyricsCacheModel, LyricsCacheModel, QQueryProperty> {
  QueryBuilder<LyricsCacheModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LyricsCacheModel, DateTime, QQueryOperations>
      fetchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fetchedAt');
    });
  }

  QueryBuilder<LyricsCacheModel, LyricsType, QQueryOperations>
      lyricsTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lyricsType');
    });
  }

  QueryBuilder<LyricsCacheModel, String?, QQueryOperations>
      plainLyricsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plainLyrics');
    });
  }

  QueryBuilder<LyricsCacheModel, String, QQueryOperations> sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<LyricsCacheModel, String?, QQueryOperations>
      syncedLyricsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedLyrics');
    });
  }
}
