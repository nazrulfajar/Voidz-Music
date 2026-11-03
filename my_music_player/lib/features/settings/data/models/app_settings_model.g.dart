// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppSettingsModelCollection on Isar {
  IsarCollection<AppSettingsModel> get appSettingsModels => this.collection();
}

const AppSettingsModelSchema = CollectionSchema(
  name: r'AppSettingsModel',
  id: -638838212012723081,
  properties: {
    r'appLanguageMode': PropertySchema(
      id: 0,
      name: r'appLanguageMode',
      type: IsarType.byte,
      enumMap: _AppSettingsModelappLanguageModeEnumValueMap,
    ),
    r'appThemeMode': PropertySchema(
      id: 1,
      name: r'appThemeMode',
      type: IsarType.byte,
      enumMap: _AppSettingsModelappThemeModeEnumValueMap,
    ),
    r'audioFocusPause': PropertySchema(
      id: 2,
      name: r'audioFocusPause',
      type: IsarType.bool,
    ),
    r'autoCacheEnabled': PropertySchema(
      id: 3,
      name: r'autoCacheEnabled',
      type: IsarType.bool,
    ),
    r'backendBaseUrl': PropertySchema(
      id: 4,
      name: r'backendBaseUrl',
      type: IsarType.string,
    ),
    r'cacheMigratedToSupportDir': PropertySchema(
      id: 5,
      name: r'cacheMigratedToSupportDir',
      type: IsarType.bool,
    ),
    r'crossfadeSeconds': PropertySchema(
      id: 6,
      name: r'crossfadeSeconds',
      type: IsarType.long,
    ),
    r'enableYoutubeSource': PropertySchema(
      id: 7,
      name: r'enableYoutubeSource',
      type: IsarType.bool,
    ),
    r'maxCacheSizeBytes': PropertySchema(
      id: 8,
      name: r'maxCacheSizeBytes',
      type: IsarType.long,
    ),
    r'preferredAudioQuality': PropertySchema(
      id: 9,
      name: r'preferredAudioQuality',
      type: IsarType.byte,
      enumMap: _AppSettingsModelpreferredAudioQualityEnumValueMap,
    ),
    r'resumeOnStartup': PropertySchema(
      id: 10,
      name: r'resumeOnStartup',
      type: IsarType.bool,
    ),
    r'wifiOnlyDownload': PropertySchema(
      id: 11,
      name: r'wifiOnlyDownload',
      type: IsarType.bool,
    )
  },
  estimateSize: _appSettingsModelEstimateSize,
  serialize: _appSettingsModelSerialize,
  deserialize: _appSettingsModelDeserialize,
  deserializeProp: _appSettingsModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appSettingsModelGetId,
  getLinks: _appSettingsModelGetLinks,
  attach: _appSettingsModelAttach,
  version: '3.1.0+1',
);

int _appSettingsModelEstimateSize(
  AppSettingsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.backendBaseUrl.length * 3;
  return bytesCount;
}

void _appSettingsModelSerialize(
  AppSettingsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.appLanguageMode.index);
  writer.writeByte(offsets[1], object.appThemeMode.index);
  writer.writeBool(offsets[2], object.audioFocusPause);
  writer.writeBool(offsets[3], object.autoCacheEnabled);
  writer.writeString(offsets[4], object.backendBaseUrl);
  writer.writeBool(offsets[5], object.cacheMigratedToSupportDir);
  writer.writeLong(offsets[6], object.crossfadeSeconds);
  writer.writeBool(offsets[7], object.enableYoutubeSource);
  writer.writeLong(offsets[8], object.maxCacheSizeBytes);
  writer.writeByte(offsets[9], object.preferredAudioQuality.index);
  writer.writeBool(offsets[10], object.resumeOnStartup);
  writer.writeBool(offsets[11], object.wifiOnlyDownload);
}

AppSettingsModel _appSettingsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppSettingsModel();
  object.appLanguageMode = _AppSettingsModelappLanguageModeValueEnumMap[
          reader.readByteOrNull(offsets[0])] ??
      AppLanguageMode.system;
  object.appThemeMode = _AppSettingsModelappThemeModeValueEnumMap[
          reader.readByteOrNull(offsets[1])] ??
      AppThemeMode.system;
  object.audioFocusPause = reader.readBool(offsets[2]);
  object.autoCacheEnabled = reader.readBool(offsets[3]);
  object.backendBaseUrl = reader.readString(offsets[4]);
  object.cacheMigratedToSupportDir = reader.readBool(offsets[5]);
  object.crossfadeSeconds = reader.readLong(offsets[6]);
  object.enableYoutubeSource = reader.readBool(offsets[7]);
  object.id = id;
  object.maxCacheSizeBytes = reader.readLong(offsets[8]);
  object.preferredAudioQuality =
      _AppSettingsModelpreferredAudioQualityValueEnumMap[
              reader.readByteOrNull(offsets[9])] ??
          AudioQuality.low;
  object.resumeOnStartup = reader.readBool(offsets[10]);
  object.wifiOnlyDownload = reader.readBool(offsets[11]);
  return object;
}

P _appSettingsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_AppSettingsModelappLanguageModeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          AppLanguageMode.system) as P;
    case 1:
      return (_AppSettingsModelappThemeModeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          AppThemeMode.system) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (_AppSettingsModelpreferredAudioQualityValueEnumMap[
              reader.readByteOrNull(offset)] ??
          AudioQuality.low) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AppSettingsModelappLanguageModeEnumValueMap = {
  'system': 0,
  'english': 1,
  'indonesian': 2,
};
const _AppSettingsModelappLanguageModeValueEnumMap = {
  0: AppLanguageMode.system,
  1: AppLanguageMode.english,
  2: AppLanguageMode.indonesian,
};
const _AppSettingsModelappThemeModeEnumValueMap = {
  'system': 0,
  'light': 1,
  'dark': 2,
};
const _AppSettingsModelappThemeModeValueEnumMap = {
  0: AppThemeMode.system,
  1: AppThemeMode.light,
  2: AppThemeMode.dark,
};
const _AppSettingsModelpreferredAudioQualityEnumValueMap = {
  'low': 0,
  'medium': 1,
  'high': 2,
};
const _AppSettingsModelpreferredAudioQualityValueEnumMap = {
  0: AudioQuality.low,
  1: AudioQuality.medium,
  2: AudioQuality.high,
};

Id _appSettingsModelGetId(AppSettingsModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appSettingsModelGetLinks(AppSettingsModel object) {
  return [];
}

void _appSettingsModelAttach(
    IsarCollection<dynamic> col, Id id, AppSettingsModel object) {
  object.id = id;
}

extension AppSettingsModelQueryWhereSort
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QWhere> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppSettingsModelQueryWhere
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QWhereClause> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
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

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause> idBetween(
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

extension AppSettingsModelQueryFilter
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QFilterCondition> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      appLanguageModeEqualTo(AppLanguageMode value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appLanguageMode',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      appLanguageModeGreaterThan(
    AppLanguageMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'appLanguageMode',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      appLanguageModeLessThan(
    AppLanguageMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'appLanguageMode',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      appLanguageModeBetween(
    AppLanguageMode lower,
    AppLanguageMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'appLanguageMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      appThemeModeEqualTo(AppThemeMode value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appThemeMode',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      appThemeModeGreaterThan(
    AppThemeMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'appThemeMode',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      appThemeModeLessThan(
    AppThemeMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'appThemeMode',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      appThemeModeBetween(
    AppThemeMode lower,
    AppThemeMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'appThemeMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      audioFocusPauseEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioFocusPause',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      autoCacheEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoCacheEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backendBaseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'backendBaseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'backendBaseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'backendBaseUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'backendBaseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'backendBaseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'backendBaseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'backendBaseUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backendBaseUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      backendBaseUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'backendBaseUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      cacheMigratedToSupportDirEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheMigratedToSupportDir',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      crossfadeSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'crossfadeSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      crossfadeSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'crossfadeSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      crossfadeSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'crossfadeSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      crossfadeSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'crossfadeSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      enableYoutubeSourceEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enableYoutubeSource',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      maxCacheSizeBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxCacheSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      maxCacheSizeBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxCacheSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      maxCacheSizeBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxCacheSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      maxCacheSizeBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxCacheSizeBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      preferredAudioQualityEqualTo(AudioQuality value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredAudioQuality',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      preferredAudioQualityGreaterThan(
    AudioQuality value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preferredAudioQuality',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      preferredAudioQualityLessThan(
    AudioQuality value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preferredAudioQuality',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      preferredAudioQualityBetween(
    AudioQuality lower,
    AudioQuality upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preferredAudioQuality',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      resumeOnStartupEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resumeOnStartup',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      wifiOnlyDownloadEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wifiOnlyDownload',
        value: value,
      ));
    });
  }
}

extension AppSettingsModelQueryObject
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QFilterCondition> {}

extension AppSettingsModelQueryLinks
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QFilterCondition> {}

extension AppSettingsModelQuerySortBy
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QSortBy> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByAppLanguageMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appLanguageMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByAppLanguageModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appLanguageMode', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByAppThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appThemeMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByAppThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appThemeMode', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByAudioFocusPause() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioFocusPause', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByAudioFocusPauseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioFocusPause', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByAutoCacheEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCacheEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByAutoCacheEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCacheEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByBackendBaseUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backendBaseUrl', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByBackendBaseUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backendBaseUrl', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByCacheMigratedToSupportDir() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheMigratedToSupportDir', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByCacheMigratedToSupportDirDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheMigratedToSupportDir', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByCrossfadeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'crossfadeSeconds', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByCrossfadeSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'crossfadeSeconds', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByEnableYoutubeSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableYoutubeSource', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByEnableYoutubeSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableYoutubeSource', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByMaxCacheSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCacheSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByMaxCacheSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCacheSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByPreferredAudioQuality() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAudioQuality', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByPreferredAudioQualityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAudioQuality', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByResumeOnStartup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resumeOnStartup', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByResumeOnStartupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resumeOnStartup', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByWifiOnlyDownload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wifiOnlyDownload', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByWifiOnlyDownloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wifiOnlyDownload', Sort.desc);
    });
  }
}

extension AppSettingsModelQuerySortThenBy
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QSortThenBy> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByAppLanguageMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appLanguageMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByAppLanguageModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appLanguageMode', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByAppThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appThemeMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByAppThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appThemeMode', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByAudioFocusPause() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioFocusPause', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByAudioFocusPauseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioFocusPause', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByAutoCacheEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCacheEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByAutoCacheEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCacheEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByBackendBaseUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backendBaseUrl', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByBackendBaseUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backendBaseUrl', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByCacheMigratedToSupportDir() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheMigratedToSupportDir', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByCacheMigratedToSupportDirDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheMigratedToSupportDir', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByCrossfadeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'crossfadeSeconds', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByCrossfadeSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'crossfadeSeconds', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByEnableYoutubeSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableYoutubeSource', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByEnableYoutubeSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableYoutubeSource', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByMaxCacheSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCacheSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByMaxCacheSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCacheSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByPreferredAudioQuality() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAudioQuality', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByPreferredAudioQualityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAudioQuality', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByResumeOnStartup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resumeOnStartup', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByResumeOnStartupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resumeOnStartup', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByWifiOnlyDownload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wifiOnlyDownload', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByWifiOnlyDownloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wifiOnlyDownload', Sort.desc);
    });
  }
}

extension AppSettingsModelQueryWhereDistinct
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByAppLanguageMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appLanguageMode');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByAppThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appThemeMode');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByAudioFocusPause() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioFocusPause');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByAutoCacheEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoCacheEnabled');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByBackendBaseUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backendBaseUrl',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByCacheMigratedToSupportDir() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cacheMigratedToSupportDir');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByCrossfadeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'crossfadeSeconds');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByEnableYoutubeSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enableYoutubeSource');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByMaxCacheSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxCacheSizeBytes');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByPreferredAudioQuality() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferredAudioQuality');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByResumeOnStartup() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resumeOnStartup');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByWifiOnlyDownload() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wifiOnlyDownload');
    });
  }
}

extension AppSettingsModelQueryProperty
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QQueryProperty> {
  QueryBuilder<AppSettingsModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppSettingsModel, AppLanguageMode, QQueryOperations>
      appLanguageModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appLanguageMode');
    });
  }

  QueryBuilder<AppSettingsModel, AppThemeMode, QQueryOperations>
      appThemeModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appThemeMode');
    });
  }

  QueryBuilder<AppSettingsModel, bool, QQueryOperations>
      audioFocusPauseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioFocusPause');
    });
  }

  QueryBuilder<AppSettingsModel, bool, QQueryOperations>
      autoCacheEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoCacheEnabled');
    });
  }

  QueryBuilder<AppSettingsModel, String, QQueryOperations>
      backendBaseUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backendBaseUrl');
    });
  }

  QueryBuilder<AppSettingsModel, bool, QQueryOperations>
      cacheMigratedToSupportDirProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheMigratedToSupportDir');
    });
  }

  QueryBuilder<AppSettingsModel, int, QQueryOperations>
      crossfadeSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'crossfadeSeconds');
    });
  }

  QueryBuilder<AppSettingsModel, bool, QQueryOperations>
      enableYoutubeSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enableYoutubeSource');
    });
  }

  QueryBuilder<AppSettingsModel, int, QQueryOperations>
      maxCacheSizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxCacheSizeBytes');
    });
  }

  QueryBuilder<AppSettingsModel, AudioQuality, QQueryOperations>
      preferredAudioQualityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredAudioQuality');
    });
  }

  QueryBuilder<AppSettingsModel, bool, QQueryOperations>
      resumeOnStartupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resumeOnStartup');
    });
  }

  QueryBuilder<AppSettingsModel, bool, QQueryOperations>
      wifiOnlyDownloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wifiOnlyDownload');
    });
  }
}
