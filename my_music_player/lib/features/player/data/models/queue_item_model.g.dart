// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_item_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQueueItemModelCollection on Isar {
  IsarCollection<QueueItemModel> get queueItemModels => this.collection();
}

const QueueItemModelSchema = CollectionSchema(
  name: r'QueueItemModel',
  id: 7697088533452344119,
  properties: {
    r'originalIndex': PropertySchema(
      id: 0,
      name: r'originalIndex',
      type: IsarType.long,
    ),
    r'queueStateId': PropertySchema(
      id: 1,
      name: r'queueStateId',
      type: IsarType.long,
    ),
    r'shuffledIndex': PropertySchema(
      id: 2,
      name: r'shuffledIndex',
      type: IsarType.long,
    ),
    r'trackId': PropertySchema(
      id: 3,
      name: r'trackId',
      type: IsarType.string,
    )
  },
  estimateSize: _queueItemModelEstimateSize,
  serialize: _queueItemModelSerialize,
  deserialize: _queueItemModelDeserialize,
  deserializeProp: _queueItemModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'queueStateId': IndexSchema(
      id: 5228436574418467494,
      name: r'queueStateId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'queueStateId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'trackId': IndexSchema(
      id: -8614467705999066844,
      name: r'trackId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'trackId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _queueItemModelGetId,
  getLinks: _queueItemModelGetLinks,
  attach: _queueItemModelAttach,
  version: '3.1.0+1',
);

int _queueItemModelEstimateSize(
  QueueItemModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.trackId.length * 3;
  return bytesCount;
}

void _queueItemModelSerialize(
  QueueItemModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.originalIndex);
  writer.writeLong(offsets[1], object.queueStateId);
  writer.writeLong(offsets[2], object.shuffledIndex);
  writer.writeString(offsets[3], object.trackId);
}

QueueItemModel _queueItemModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = QueueItemModel();
  object.id = id;
  object.originalIndex = reader.readLong(offsets[0]);
  object.queueStateId = reader.readLong(offsets[1]);
  object.shuffledIndex = reader.readLongOrNull(offsets[2]);
  object.trackId = reader.readString(offsets[3]);
  return object;
}

P _queueItemModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _queueItemModelGetId(QueueItemModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _queueItemModelGetLinks(QueueItemModel object) {
  return [];
}

void _queueItemModelAttach(
    IsarCollection<dynamic> col, Id id, QueueItemModel object) {
  object.id = id;
}

extension QueueItemModelQueryWhereSort
    on QueryBuilder<QueueItemModel, QueueItemModel, QWhere> {
  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhere> anyQueueStateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'queueStateId'),
      );
    });
  }
}

extension QueueItemModelQueryWhere
    on QueryBuilder<QueueItemModel, QueueItemModel, QWhereClause> {
  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause>
      queueStateIdEqualTo(int queueStateId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'queueStateId',
        value: [queueStateId],
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause>
      queueStateIdNotEqualTo(int queueStateId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queueStateId',
              lower: [],
              upper: [queueStateId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queueStateId',
              lower: [queueStateId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queueStateId',
              lower: [queueStateId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queueStateId',
              lower: [],
              upper: [queueStateId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause>
      queueStateIdGreaterThan(
    int queueStateId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'queueStateId',
        lower: [queueStateId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause>
      queueStateIdLessThan(
    int queueStateId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'queueStateId',
        lower: [],
        upper: [queueStateId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause>
      queueStateIdBetween(
    int lowerQueueStateId,
    int upperQueueStateId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'queueStateId',
        lower: [lowerQueueStateId],
        includeLower: includeLower,
        upper: [upperQueueStateId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause>
      trackIdEqualTo(String trackId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'trackId',
        value: [trackId],
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterWhereClause>
      trackIdNotEqualTo(String trackId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'trackId',
              lower: [],
              upper: [trackId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'trackId',
              lower: [trackId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'trackId',
              lower: [trackId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'trackId',
              lower: [],
              upper: [trackId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension QueueItemModelQueryFilter
    on QueryBuilder<QueueItemModel, QueueItemModel, QFilterCondition> {
  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
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

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
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

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      originalIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      originalIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      originalIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      originalIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      queueStateIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queueStateId',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      queueStateIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'queueStateId',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      queueStateIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'queueStateId',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      queueStateIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'queueStateId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      shuffledIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'shuffledIndex',
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      shuffledIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'shuffledIndex',
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      shuffledIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shuffledIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      shuffledIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shuffledIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      shuffledIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shuffledIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      shuffledIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shuffledIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trackId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'trackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'trackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'trackId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'trackId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackId',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterFilterCondition>
      trackIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'trackId',
        value: '',
      ));
    });
  }
}

extension QueueItemModelQueryObject
    on QueryBuilder<QueueItemModel, QueueItemModel, QFilterCondition> {}

extension QueueItemModelQueryLinks
    on QueryBuilder<QueueItemModel, QueueItemModel, QFilterCondition> {}

extension QueueItemModelQuerySortBy
    on QueryBuilder<QueueItemModel, QueueItemModel, QSortBy> {
  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      sortByOriginalIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalIndex', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      sortByOriginalIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalIndex', Sort.desc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      sortByQueueStateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueStateId', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      sortByQueueStateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueStateId', Sort.desc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      sortByShuffledIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffledIndex', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      sortByShuffledIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffledIndex', Sort.desc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy> sortByTrackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackId', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      sortByTrackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackId', Sort.desc);
    });
  }
}

extension QueueItemModelQuerySortThenBy
    on QueryBuilder<QueueItemModel, QueueItemModel, QSortThenBy> {
  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      thenByOriginalIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalIndex', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      thenByOriginalIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalIndex', Sort.desc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      thenByQueueStateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueStateId', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      thenByQueueStateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueStateId', Sort.desc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      thenByShuffledIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffledIndex', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      thenByShuffledIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffledIndex', Sort.desc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy> thenByTrackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackId', Sort.asc);
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QAfterSortBy>
      thenByTrackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackId', Sort.desc);
    });
  }
}

extension QueueItemModelQueryWhereDistinct
    on QueryBuilder<QueueItemModel, QueueItemModel, QDistinct> {
  QueryBuilder<QueueItemModel, QueueItemModel, QDistinct>
      distinctByOriginalIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalIndex');
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QDistinct>
      distinctByQueueStateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'queueStateId');
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QDistinct>
      distinctByShuffledIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shuffledIndex');
    });
  }

  QueryBuilder<QueueItemModel, QueueItemModel, QDistinct> distinctByTrackId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackId', caseSensitive: caseSensitive);
    });
  }
}

extension QueueItemModelQueryProperty
    on QueryBuilder<QueueItemModel, QueueItemModel, QQueryProperty> {
  QueryBuilder<QueueItemModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<QueueItemModel, int, QQueryOperations> originalIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalIndex');
    });
  }

  QueryBuilder<QueueItemModel, int, QQueryOperations> queueStateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'queueStateId');
    });
  }

  QueryBuilder<QueueItemModel, int?, QQueryOperations> shuffledIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shuffledIndex');
    });
  }

  QueryBuilder<QueueItemModel, String, QQueryOperations> trackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackId');
    });
  }
}
