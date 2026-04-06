import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String time;
  final String description;
  final String accountType;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.time,
    required this.description,
    required this.accountType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap({bool includeId = false}) => {
        if (includeId) 'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'isIncome': isIncome ? 1 : 0,
        'date': date.toIso8601String().split('T')[0],
        'time': time,
        'description': description,
        'accountType': accountType,
        'createdAt': createdAt.toIso8601String(),
      };

  static DateTime _parseDate(dynamic input) {
    if (input is DateTime) return input;
    if (input is Timestamp) return input.toDate();
    if (input is String) return DateTime.parse(input);
    throw ArgumentError('Unsupported date format: ${input.runtimeType}');
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
        id: map['id'].toString(),
        title: map['title'] ?? '',
        category: map['category'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        isIncome: map['isIncome'] == 1 || map['isIncome'] == true,
        date: _parseDate(map['date']),
        time: map['time'] ?? '',
        description: map['description'] ?? '',
        accountType: map['accountType'] ?? 'Cash',
        createdAt: _parseDate(map['createdAt'] ?? DateTime.now()),
      );
}
