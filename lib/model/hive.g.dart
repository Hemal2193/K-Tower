// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntryModelAdapter extends TypeAdapter<EntryModel> {
  @override
  final int typeId = 0;

  @override
  EntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EntryModel(
      supabaseId: fields[5] as int?,
      isEdited: fields[6] as bool,
      name: fields[0] as String,
      flatNo: fields[1] as int,
      mobileNumber: fields[2] as String,
      date: fields[3] as DateTime,
      amount: fields[4] as double,
      pending: (fields[11] as num?)?.toDouble() ?? 0,
      isCash: fields[7] as bool,
      fromMonth: fields[8] as String? ?? '',
      toMonth: fields[9] as String? ?? '',
      year:
          fields[10] as int? ??
          fields[11] as int? ??
          DateTime.now().year,
    );
  }

  @override
  void write(BinaryWriter writer, EntryModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(5)
      ..write(obj.supabaseId)
      ..writeByte(6)
      ..write(obj.isEdited)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.flatNo)
      ..writeByte(2)
      ..write(obj.mobileNumber)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(11)
      ..write(obj.pending)
      ..writeByte(7)
      ..write(obj.isCash)
      ..writeByte(8)
      ..write(obj.fromMonth)
      ..writeByte(9)
      ..write(obj.toMonth)
      ..writeByte(10)
      ..write(obj.year);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
