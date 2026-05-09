import 'package:hive/hive.dart';

part 'hive.g.dart';

@HiveType(typeId: 0)
class EntryModel extends HiveObject {
  @HiveField(5)
  final int? supabaseId;

  @HiveField(6)
  final bool isEdited;

  @HiveField(0)
  final String name;

  @HiveField(1)
  final int flatNo;

  @HiveField(2)
  final String mobileNumber;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final double amount;

  @HiveField(11)
  final double pending;

  @HiveField(7)
  final bool isCash;

  @HiveField(8)
  final String fromMonth;

  @HiveField(9)
  final String toMonth;

  @HiveField(10)
  final int year;

  EntryModel({
    this.supabaseId,
    this.isEdited = false,
    required this.name,
    required this.flatNo,
    required this.mobileNumber,
    required this.date,
    required this.amount,
    this.pending = 0,
    this.isCash = true, // Default to Cash
    required this.fromMonth,
    required this.toMonth,
    int? year,
  }) : year = year ?? DateTime.now().year;

  EntryModel copyWith({
    int? supabaseId,
    bool? isEdited,
    String? name,
    int? flatNo,
    String? mobileNumber,
    DateTime? date,
    double? amount,
    double? pending,
    bool? isCash,
    String? fromMonth,
    String? toMonth,
    int? year,
  }) {
    return EntryModel(
      supabaseId: supabaseId ?? this.supabaseId,
      isEdited: isEdited ?? this.isEdited,
      name: name ?? this.name,
      flatNo: flatNo ?? this.flatNo,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      pending: pending ?? this.pending,
      isCash: isCash ?? this.isCash,
      fromMonth: fromMonth ?? this.fromMonth,
      toMonth: toMonth ?? this.toMonth,
      year: year ?? this.year,
    );
  }
}
