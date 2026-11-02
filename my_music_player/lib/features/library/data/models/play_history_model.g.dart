// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPlayHistoryModelCollection on Isar {
  IsarCollection<PlayHistoryModel> get playHistoryModels => this.collection();
}

const PlayHistoryModelSchema = CollectionSchema(
  name: r'PlayHistoryModel',
  id: -5509593804520761484,
  properties: {
    r'playedAt': PropertySchema(
      id: 0,
      name: r'playedAt',
      type: IsarType.dateTime,
    ),
    r'trackSourceId': PropertySchema(
      id: 1,
      name: r'trackSourceId',
      type: IsarType.string,
    )
  },
  estimateSize: _playHistoryModelEstimateSize,
  serialize: _playHistoryModelSerialize,
  deserialize: _playHistoryModelDeserialize,
  deserializeProp: _playHistoryModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'trackSourceId': IndexSchema(
      id: -7455417843540305493,
      name: r'trackSourceId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'trackSourceId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'playedAt': IndexSchema(
      id: -3711549563919110219,
      name: r'playedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'playedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _playHistoryModelGetId,
  getLinks: _playHistoryModelGetLinks,
  attach: _playHistoryModelAttach,
  version: '3.1.0+1',
);

int _playHistoryModelEstimateSize(
  PlayHistoryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.trackSourceId.length * 3;
  return bytesCount;
}

void _playHistoryModelSerialize(
  PlayHistoryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.playedAt);
  writer.writeString(offsets[1], object.trackSourceId);
}

PlayHistoryModel _playHistoryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlayHistoryModel();
  object.id = id;
  object.playedAt = reader.readDateTime(offsets[0]);
  object.trackSourceId = reader.readString(offsets[1]);
  return object;
}

P _playHistoryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _playHistoryModelGetId(PlayHistoryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _playHistoryModelGetLinks(PlayHistoryModel object) {
  return [];
}

void _playHistoryModelAttach(
    IsarCollection<dynamic> col, Id id, PlayHistoryModel object) {
  object.id = id;
}

extension PlayHistoryModelQueryWhereSort
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QWhere> {
  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhere> anyPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'playedAt'),
      );
    });
  }
}

extension PlayHistoryModelQueryWhere
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QWhereClause> {
  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
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

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      trackSourceIdEqualTo(String trackSourceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'trackSourceId',
        value: [trackSourceId],
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      trackSourceIdNotEqualTo(String trackSourceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'trackSourceId',
              lower: [],
              upper: [trackSourceId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'trackSourceId',
              lower: [trackSourceId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'trackSourceId',
              lower: [trackSourceId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'trackSourceId',
              lower: [],
              upper: [trackSourceId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      playedAtEqualTo(DateTime playedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'playedAt',
        value: [playedAt],
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      playedAtNotEqualTo(DateTime playedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playedAt',
              lower: [],
              upper: [playedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playedAt',
              lower: [playedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playedAt',
              lower: [playedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playedAt',
              lower: [],
              upper: [playedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      playedAtGreaterThan(
    DateTime playedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'playedAt',
        lower: [playedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      playedAtLessThan(
    DateTime playedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'playedAt',
        lower: [],
        upper: [playedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterWhereClause>
      playedAtBetween(
    DateTime lowerPlayedAt,
    DateTime upperPlayedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'playedAt',
        lower: [lowerPlayedAt],
        includeLower: includeLower,
        upper: [upperPlayedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PlayHistoryModelQueryFilter
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QFilterCondition> {
  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
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

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
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

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
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

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      playedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'playedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      playedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'playedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      playedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'playedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      playedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'playedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackSourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trackSourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trackSourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trackSourceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'trackSourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'trackSourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'trackSourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'trackSourceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackSourceId',
        value: '',
      ));
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterFilterCondition>
      trackSourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'trackSourceId',
        value: '',
      ));
    });
  }
}

extension PlayHistoryModelQueryObject
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QFilterCondition> {}

extension PlayHistoryModelQueryLinks
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QFilterCondition> {}

extension PlayHistoryModelQuerySortBy
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QSortBy> {
  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      sortByPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playedAt', Sort.asc);
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      sortByPlayedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playedAt', Sort.desc);
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      sortByTrackSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackSourceId', Sort.asc);
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      sortByTrackSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackSourceId', Sort.desc);
    });
  }
}

extension PlayHistoryModelQuerySortThenBy
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QSortThenBy> {
  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      thenByPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playedAt', Sort.asc);
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      thenByPlayedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playedAt', Sort.desc);
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      thenByTrackSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackSourceId', Sort.asc);
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QAfterSortBy>
      thenByTrackSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackSourceId', Sort.desc);
    });
  }
}

extension PlayHistoryModelQueryWhereDistinct
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QDistinct> {
  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QDistinct>
      distinctByPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'playedAt');
    });
  }

  QueryBuilder<PlayHistoryModel, PlayHistoryModel, QDistinct>
      distinctByTrackSourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackSourceId',
          caseSensitive: caseSensitive);
    });
  }
}

extension PlayHistoryModelQueryProperty
    on QueryBuilder<PlayHistoryModel, PlayHistoryModel, QQueryProperty> {
  QueryBuilder<PlayHistoryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlayHistoryModel, DateTime, QQueryOperations>
      playedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'playedAt');
    });
  }

  QueryBuilder<PlayHistoryModel, String, QQueryOperations>
      trackSourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackSourceId');
    });
  }
}
