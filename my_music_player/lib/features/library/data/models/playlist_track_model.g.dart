// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_track_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPlaylistTrackModelCollection on Isar {
  IsarCollection<PlaylistTrackModel> get playlistTrackModels =>
      this.collection();
}

const PlaylistTrackModelSchema = CollectionSchema(
  name: r'PlaylistTrackModel',
  id: 2547071716370683034,
  properties: {
    r'addedAt': PropertySchema(
      id: 0,
      name: r'addedAt',
      type: IsarType.dateTime,
    ),
    r'orderIndex': PropertySchema(
      id: 1,
      name: r'orderIndex',
      type: IsarType.long,
    ),
    r'playlistId': PropertySchema(
      id: 2,
      name: r'playlistId',
      type: IsarType.long,
    ),
    r'trackSourceId': PropertySchema(
      id: 3,
      name: r'trackSourceId',
      type: IsarType.string,
    )
  },
  estimateSize: _playlistTrackModelEstimateSize,
  serialize: _playlistTrackModelSerialize,
  deserialize: _playlistTrackModelDeserialize,
  deserializeProp: _playlistTrackModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'playlistId_trackSourceId': IndexSchema(
      id: -5910454114372768589,
      name: r'playlistId_trackSourceId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'playlistId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'trackSourceId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'orderIndex': IndexSchema(
      id: -6149432298716175352,
      name: r'orderIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'orderIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _playlistTrackModelGetId,
  getLinks: _playlistTrackModelGetLinks,
  attach: _playlistTrackModelAttach,
  version: '3.1.0+1',
);

int _playlistTrackModelEstimateSize(
  PlaylistTrackModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.trackSourceId.length * 3;
  return bytesCount;
}

void _playlistTrackModelSerialize(
  PlaylistTrackModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.addedAt);
  writer.writeLong(offsets[1], object.orderIndex);
  writer.writeLong(offsets[2], object.playlistId);
  writer.writeString(offsets[3], object.trackSourceId);
}

PlaylistTrackModel _playlistTrackModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlaylistTrackModel();
  object.addedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.orderIndex = reader.readLong(offsets[1]);
  object.playlistId = reader.readLong(offsets[2]);
  object.trackSourceId = reader.readString(offsets[3]);
  return object;
}

P _playlistTrackModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _playlistTrackModelGetId(PlaylistTrackModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _playlistTrackModelGetLinks(
    PlaylistTrackModel object) {
  return [];
}

void _playlistTrackModelAttach(
    IsarCollection<dynamic> col, Id id, PlaylistTrackModel object) {
  object.id = id;
}

extension PlaylistTrackModelByIndex on IsarCollection<PlaylistTrackModel> {
  Future<PlaylistTrackModel?> getByPlaylistIdTrackSourceId(
      int playlistId, String trackSourceId) {
    return getByIndex(r'playlistId_trackSourceId', [playlistId, trackSourceId]);
  }

  PlaylistTrackModel? getByPlaylistIdTrackSourceIdSync(
      int playlistId, String trackSourceId) {
    return getByIndexSync(
        r'playlistId_trackSourceId', [playlistId, trackSourceId]);
  }

  Future<bool> deleteByPlaylistIdTrackSourceId(
      int playlistId, String trackSourceId) {
    return deleteByIndex(
        r'playlistId_trackSourceId', [playlistId, trackSourceId]);
  }

  bool deleteByPlaylistIdTrackSourceIdSync(
      int playlistId, String trackSourceId) {
    return deleteByIndexSync(
        r'playlistId_trackSourceId', [playlistId, trackSourceId]);
  }

  Future<List<PlaylistTrackModel?>> getAllByPlaylistIdTrackSourceId(
      List<int> playlistIdValues, List<String> trackSourceIdValues) {
    final len = playlistIdValues.length;
    assert(trackSourceIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([playlistIdValues[i], trackSourceIdValues[i]]);
    }

    return getAllByIndex(r'playlistId_trackSourceId', values);
  }

  List<PlaylistTrackModel?> getAllByPlaylistIdTrackSourceIdSync(
      List<int> playlistIdValues, List<String> trackSourceIdValues) {
    final len = playlistIdValues.length;
    assert(trackSourceIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([playlistIdValues[i], trackSourceIdValues[i]]);
    }

    return getAllByIndexSync(r'playlistId_trackSourceId', values);
  }

  Future<int> deleteAllByPlaylistIdTrackSourceId(
      List<int> playlistIdValues, List<String> trackSourceIdValues) {
    final len = playlistIdValues.length;
    assert(trackSourceIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([playlistIdValues[i], trackSourceIdValues[i]]);
    }

    return deleteAllByIndex(r'playlistId_trackSourceId', values);
  }

  int deleteAllByPlaylistIdTrackSourceIdSync(
      List<int> playlistIdValues, List<String> trackSourceIdValues) {
    final len = playlistIdValues.length;
    assert(trackSourceIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([playlistIdValues[i], trackSourceIdValues[i]]);
    }

    return deleteAllByIndexSync(r'playlistId_trackSourceId', values);
  }

  Future<Id> putByPlaylistIdTrackSourceId(PlaylistTrackModel object) {
    return putByIndex(r'playlistId_trackSourceId', object);
  }

  Id putByPlaylistIdTrackSourceIdSync(PlaylistTrackModel object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'playlistId_trackSourceId', object,
        saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPlaylistIdTrackSourceId(
      List<PlaylistTrackModel> objects) {
    return putAllByIndex(r'playlistId_trackSourceId', objects);
  }

  List<Id> putAllByPlaylistIdTrackSourceIdSync(List<PlaylistTrackModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'playlistId_trackSourceId', objects,
        saveLinks: saveLinks);
  }
}

extension PlaylistTrackModelQueryWhereSort
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QWhere> {
  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhere>
      anyOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'orderIndex'),
      );
    });
  }
}

extension PlaylistTrackModelQueryWhere
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QWhereClause> {
  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      playlistIdEqualToAnyTrackSourceId(int playlistId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'playlistId_trackSourceId',
        value: [playlistId],
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      playlistIdNotEqualToAnyTrackSourceId(int playlistId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playlistId_trackSourceId',
              lower: [],
              upper: [playlistId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playlistId_trackSourceId',
              lower: [playlistId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playlistId_trackSourceId',
              lower: [playlistId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playlistId_trackSourceId',
              lower: [],
              upper: [playlistId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      playlistIdGreaterThanAnyTrackSourceId(
    int playlistId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'playlistId_trackSourceId',
        lower: [playlistId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      playlistIdLessThanAnyTrackSourceId(
    int playlistId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'playlistId_trackSourceId',
        lower: [],
        upper: [playlistId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      playlistIdBetweenAnyTrackSourceId(
    int lowerPlaylistId,
    int upperPlaylistId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'playlistId_trackSourceId',
        lower: [lowerPlaylistId],
        includeLower: includeLower,
        upper: [upperPlaylistId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      playlistIdTrackSourceIdEqualTo(int playlistId, String trackSourceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'playlistId_trackSourceId',
        value: [playlistId, trackSourceId],
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      playlistIdEqualToTrackSourceIdNotEqualTo(
          int playlistId, String trackSourceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playlistId_trackSourceId',
              lower: [playlistId],
              upper: [playlistId, trackSourceId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playlistId_trackSourceId',
              lower: [playlistId, trackSourceId],
              includeLower: false,
              upper: [playlistId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playlistId_trackSourceId',
              lower: [playlistId, trackSourceId],
              includeLower: false,
              upper: [playlistId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'playlistId_trackSourceId',
              lower: [playlistId],
              upper: [playlistId, trackSourceId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      orderIndexEqualTo(int orderIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderIndex',
        value: [orderIndex],
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      orderIndexNotEqualTo(int orderIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderIndex',
              lower: [],
              upper: [orderIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderIndex',
              lower: [orderIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderIndex',
              lower: [orderIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderIndex',
              lower: [],
              upper: [orderIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      orderIndexGreaterThan(
    int orderIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderIndex',
        lower: [orderIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      orderIndexLessThan(
    int orderIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderIndex',
        lower: [],
        upper: [orderIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterWhereClause>
      orderIndexBetween(
    int lowerOrderIndex,
    int upperOrderIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderIndex',
        lower: [lowerOrderIndex],
        includeLower: includeLower,
        upper: [upperOrderIndex],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PlaylistTrackModelQueryFilter
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QFilterCondition> {
  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      addedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      addedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      addedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      addedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      orderIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      orderIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      orderIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      orderIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      playlistIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'playlistId',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      playlistIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'playlistId',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      playlistIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'playlistId',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      playlistIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'playlistId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
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

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      trackSourceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'trackSourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      trackSourceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'trackSourceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      trackSourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackSourceId',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterFilterCondition>
      trackSourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'trackSourceId',
        value: '',
      ));
    });
  }
}

extension PlaylistTrackModelQueryObject
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QFilterCondition> {}

extension PlaylistTrackModelQueryLinks
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QFilterCondition> {}

extension PlaylistTrackModelQuerySortBy
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QSortBy> {
  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      sortByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      sortByAddedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      sortByPlaylistId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playlistId', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      sortByPlaylistIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playlistId', Sort.desc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      sortByTrackSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackSourceId', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      sortByTrackSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackSourceId', Sort.desc);
    });
  }
}

extension PlaylistTrackModelQuerySortThenBy
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QSortThenBy> {
  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByAddedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByPlaylistId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playlistId', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByPlaylistIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playlistId', Sort.desc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByTrackSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackSourceId', Sort.asc);
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QAfterSortBy>
      thenByTrackSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackSourceId', Sort.desc);
    });
  }
}

extension PlaylistTrackModelQueryWhereDistinct
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QDistinct> {
  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QDistinct>
      distinctByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addedAt');
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QDistinct>
      distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QDistinct>
      distinctByPlaylistId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'playlistId');
    });
  }

  QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QDistinct>
      distinctByTrackSourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackSourceId',
          caseSensitive: caseSensitive);
    });
  }
}

extension PlaylistTrackModelQueryProperty
    on QueryBuilder<PlaylistTrackModel, PlaylistTrackModel, QQueryProperty> {
  QueryBuilder<PlaylistTrackModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlaylistTrackModel, DateTime, QQueryOperations>
      addedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addedAt');
    });
  }

  QueryBuilder<PlaylistTrackModel, int, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<PlaylistTrackModel, int, QQueryOperations> playlistIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'playlistId');
    });
  }

  QueryBuilder<PlaylistTrackModel, String, QQueryOperations>
      trackSourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackSourceId');
    });
  }
}
