// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyRecordCollection on Isar {
  IsarCollection<DailyRecord> get dailyRecords => this.collection();
}

const DailyRecordSchema = CollectionSchema(
  name: r'DailyRecord',
  id: -1016922496390167466,
  properties: {
    r'checkRecords': PropertySchema(
      id: 0,
      name: r'checkRecords',
      type: IsarType.objectList,
      target: r'CheckEntry',
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.string,
    ),
    r'message': PropertySchema(
      id: 2,
      name: r'message',
      type: IsarType.string,
    ),
    r'timeRecords': PropertySchema(
      id: 3,
      name: r'timeRecords',
      type: IsarType.objectList,
      target: r'TimeEntry',
    )
  },
  estimateSize: _dailyRecordEstimateSize,
  serialize: _dailyRecordSerialize,
  deserialize: _dailyRecordDeserialize,
  deserializeProp: _dailyRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'TimeEntry': TimeEntrySchema,
    r'CheckEntry': CheckEntrySchema
  },
  getId: _dailyRecordGetId,
  getLinks: _dailyRecordGetLinks,
  attach: _dailyRecordAttach,
  version: '3.1.0+1',
);

int _dailyRecordEstimateSize(
  DailyRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.checkRecords;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[CheckEntry]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              CheckEntrySchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.date.length * 3;
  {
    final value = object.message;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.timeRecords;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[TimeEntry]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              TimeEntrySchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  return bytesCount;
}

void _dailyRecordSerialize(
  DailyRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<CheckEntry>(
    offsets[0],
    allOffsets,
    CheckEntrySchema.serialize,
    object.checkRecords,
  );
  writer.writeString(offsets[1], object.date);
  writer.writeString(offsets[2], object.message);
  writer.writeObjectList<TimeEntry>(
    offsets[3],
    allOffsets,
    TimeEntrySchema.serialize,
    object.timeRecords,
  );
}

DailyRecord _dailyRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyRecord(
    checkRecords: reader.readObjectList<CheckEntry>(
      offsets[0],
      CheckEntrySchema.deserialize,
      allOffsets,
      CheckEntry(),
    ),
    date: reader.readStringOrNull(offsets[1]) ?? '',
    message: reader.readStringOrNull(offsets[2]),
    timeRecords: reader.readObjectList<TimeEntry>(
      offsets[3],
      TimeEntrySchema.deserialize,
      allOffsets,
      TimeEntry(),
    ),
  );
  object.id = id;
  return object;
}

P _dailyRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<CheckEntry>(
        offset,
        CheckEntrySchema.deserialize,
        allOffsets,
        CheckEntry(),
      )) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readObjectList<TimeEntry>(
        offset,
        TimeEntrySchema.deserialize,
        allOffsets,
        TimeEntry(),
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyRecordGetId(DailyRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyRecordGetLinks(DailyRecord object) {
  return [];
}

void _dailyRecordAttach(
    IsarCollection<dynamic> col, Id id, DailyRecord object) {
  object.id = id;
}

extension DailyRecordQueryWhereSort
    on QueryBuilder<DailyRecord, DailyRecord, QWhere> {
  QueryBuilder<DailyRecord, DailyRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailyRecordQueryWhere
    on QueryBuilder<DailyRecord, DailyRecord, QWhereClause> {
  QueryBuilder<DailyRecord, DailyRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<DailyRecord, DailyRecord, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<DailyRecord, DailyRecord, QAfterWhereClause> dateEqualTo(
      String date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterWhereClause> dateNotEqualTo(
      String date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DailyRecordQueryFilter
    on QueryBuilder<DailyRecord, DailyRecord, QFilterCondition> {
  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'checkRecords',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'checkRecords',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'checkRecords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'checkRecords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'checkRecords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'checkRecords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'checkRecords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'checkRecords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      messageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'message',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      messageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'message',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> messageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      messageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> messageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> messageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> messageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition> messageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timeRecords',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timeRecords',
      ));
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeRecords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeRecords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeRecords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeRecords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeRecords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeRecords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension DailyRecordQueryObject
    on QueryBuilder<DailyRecord, DailyRecord, QFilterCondition> {
  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      checkRecordsElement(FilterQuery<CheckEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'checkRecords');
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterFilterCondition>
      timeRecordsElement(FilterQuery<TimeEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'timeRecords');
    });
  }
}

extension DailyRecordQueryLinks
    on QueryBuilder<DailyRecord, DailyRecord, QFilterCondition> {}

extension DailyRecordQuerySortBy
    on QueryBuilder<DailyRecord, DailyRecord, QSortBy> {
  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }
}

extension DailyRecordQuerySortThenBy
    on QueryBuilder<DailyRecord, DailyRecord, QSortThenBy> {
  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QAfterSortBy> thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }
}

extension DailyRecordQueryWhereDistinct
    on QueryBuilder<DailyRecord, DailyRecord, QDistinct> {
  QueryBuilder<DailyRecord, DailyRecord, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyRecord, DailyRecord, QDistinct> distinctByMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }
}

extension DailyRecordQueryProperty
    on QueryBuilder<DailyRecord, DailyRecord, QQueryProperty> {
  QueryBuilder<DailyRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyRecord, List<CheckEntry>?, QQueryOperations>
      checkRecordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkRecords');
    });
  }

  QueryBuilder<DailyRecord, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyRecord, String?, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<DailyRecord, List<TimeEntry>?, QQueryOperations>
      timeRecordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeRecords');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TimeEntrySchema = Schema(
  name: r'TimeEntry',
  id: -8996794355716442839,
  properties: {
    r'categoryId': PropertySchema(
      id: 0,
      name: r'categoryId',
      type: IsarType.long,
    ),
    r'minutes': PropertySchema(
      id: 1,
      name: r'minutes',
      type: IsarType.long,
    )
  },
  estimateSize: _timeEntryEstimateSize,
  serialize: _timeEntrySerialize,
  deserialize: _timeEntryDeserialize,
  deserializeProp: _timeEntryDeserializeProp,
);

int _timeEntryEstimateSize(
  TimeEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _timeEntrySerialize(
  TimeEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.categoryId);
  writer.writeLong(offsets[1], object.minutes);
}

TimeEntry _timeEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimeEntry(
    categoryId: reader.readLongOrNull(offsets[0]) ?? 0,
    minutes: reader.readLongOrNull(offsets[1]) ?? 0,
  );
  return object;
}

P _timeEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TimeEntryQueryFilter
    on QueryBuilder<TimeEntry, TimeEntry, QFilterCondition> {
  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> categoryIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition>
      categoryIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> categoryIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> categoryIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> minutesEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> minutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> minutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> minutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TimeEntryQueryObject
    on QueryBuilder<TimeEntry, TimeEntry, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const CheckEntrySchema = Schema(
  name: r'CheckEntry',
  id: 4982355825040364664,
  properties: {
    r'checkBoxId': PropertySchema(
      id: 0,
      name: r'checkBoxId',
      type: IsarType.long,
    ),
    r'isCompleted': PropertySchema(
      id: 1,
      name: r'isCompleted',
      type: IsarType.bool,
    )
  },
  estimateSize: _checkEntryEstimateSize,
  serialize: _checkEntrySerialize,
  deserialize: _checkEntryDeserialize,
  deserializeProp: _checkEntryDeserializeProp,
);

int _checkEntryEstimateSize(
  CheckEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _checkEntrySerialize(
  CheckEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.checkBoxId);
  writer.writeBool(offsets[1], object.isCompleted);
}

CheckEntry _checkEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CheckEntry(
    checkBoxId: reader.readLongOrNull(offsets[0]) ?? 0,
    isCompleted: reader.readBoolOrNull(offsets[1]) ?? false,
  );
  return object;
}

P _checkEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension CheckEntryQueryFilter
    on QueryBuilder<CheckEntry, CheckEntry, QFilterCondition> {
  QueryBuilder<CheckEntry, CheckEntry, QAfterFilterCondition> checkBoxIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checkBoxId',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckEntry, CheckEntry, QAfterFilterCondition>
      checkBoxIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'checkBoxId',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckEntry, CheckEntry, QAfterFilterCondition>
      checkBoxIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'checkBoxId',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckEntry, CheckEntry, QAfterFilterCondition> checkBoxIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'checkBoxId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CheckEntry, CheckEntry, QAfterFilterCondition>
      isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }
}

extension CheckEntryQueryObject
    on QueryBuilder<CheckEntry, CheckEntry, QFilterCondition> {}
