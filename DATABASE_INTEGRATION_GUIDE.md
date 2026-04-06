# Database Integration Guide - Expenses Screen

## Overview
The **expenses_screen_new.dart** displays previous transactions from the database and allows users to insert new expense/income data. Here's the complete flow:

---

## 1. DATABASE STRUCTURE

### Table: `transactions`
```sql
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  date TEXT NOT NULL,
  time TEXT NOT NULL,
  isIncome INTEGER NOT NULL,        -- 1 for income, 0 for expense
  accountType TEXT NOT NULL,        -- Cash, Bank, Investment
  createdAt TEXT NOT NULL
)
```

### Models Used
- **ExpenseModel**: Represents a transaction (expense or income)

---

## 2. RETRIEVING PREVIOUS DATABASE DATA

### Flow: Database → UI Display

#### **Step 1: DatabaseHelper.getTransactions()**
Located in [database_helper.dart](database_helper.dart)

```dart
Future<List<ExpenseModel>> getTransactions({
  DateTime? startDate,
  DateTime? endDate,
  String? category,
  String? accountType,
  bool? isIncome,
}) async {
  Database db = await database;
  
  // Build WHERE clause for filtering
  String whereClause = '';
  List<dynamic> whereArgs = [];

  if (startDate != null && endDate != null) {
    whereClause += 'date BETWEEN ? AND ?';
    whereArgs.add(startDate.toIso8601String().split('T')[0]);
    whereArgs.add(endDate.toIso8601String().split('T')[0]);
  }

  if (category != null) {
    if (whereClause.isNotEmpty) whereClause += ' AND ';
    whereClause += 'category = ?';
    whereArgs.add(category);
  }

  if (accountType != null) {
    if (whereClause.isNotEmpty) whereClause += ' AND ';
    whereClause += 'accountType = ?';
    whereArgs.add(accountType);
  }

  if (isIncome != null) {
    if (whereClause.isNotEmpty) whereClause += ' AND ';
    whereClause += 'isIncome = ?';
    whereArgs.add(isIncome ? 1 : 0);
  }

  // Fetch and return results sorted by creation date
  final List<Map<String, dynamic>> maps = await db.query(
    'transactions',
    where: whereClause.isNotEmpty ? whereClause : null,
    whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    orderBy: 'createdAt DESC',
  );

  return List.generate(maps.length, (i) => ExpenseModel.fromMap(maps[i]));
}
```

#### **Step 2: ExpenseService Methods** (Convenience wrapper)
```dart
// Get today's transactions
Future<List<ExpenseModel>> getTodayTransactions() async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return await getTransactions(startDate: start, endDate: end);
}

// Get monthly transactions
Future<List<ExpenseModel>> getMonthlyTransactions(DateTime month) async {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  return await getTransactions(startDate: start, endDate: end);
}
```

#### **Step 3: ExpensesScreenNew - Display Data**

**In initState():**
```dart
@override
void initState() {
  super.initState();
  _loadBudgets();
  _loadMonthlyData();
}

Future<void> _loadMonthlyData() async {
  final now = DateTime.now();
  final summary = await _expenseService.getMonthlySummary(now);
  final overBudget = await _expenseService.isOverBudget(now);
  setState(() {
    _monthlySummary = summary;
    _isOverBudget = overBudget;
  });
}
```

**In build() - Fetch data for display:**
```dart
Future<List<ExpenseModel>> _getFilteredTransactions() async {
  final now = DateTime.now();
  if (_selectedTab == 0) {
    // Today's transactions
    return await _expenseService.getTodayTransactions();
  } else {
    // Monthly transactions
    return await _expenseService.getMonthlyTransactions(now);
  }
}
```

**FutureBuilder Example (pseudo-code):**
```dart
FutureBuilder<List<ExpenseModel>>(
  key: _refreshKey,
  future: _getFilteredTransactions(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: Text('No transactions found'));
    }
    
    final transactions = snapshot.data!;
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          title: Text('${transaction.title} - LKR ${transaction.amount}'),
          subtitle: Text(transaction.category),
        );
      },
    );
  },
)
```

---

## 3. INSERTING NEW EXPENSE/INCOME DATA

### Flow: User Input → Model → Database

#### **Step 1: User navigates to AddExpenseScreen**
```dart
// From ExpensesScreenNew - User presses "+ Add" button
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    ).then((_) {
      _refreshData(); // Refresh display after adding
    });
  },
  child: Icon(Icons.add),
)
```

#### **Step 2: Collect User Input in AddExpenseScreen**
```dart
class AddExpenseScreen extends StatefulWidget {
  // Form fields
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  
  String selectedCategory = '';
  String selectedAccountType = '';
  bool isIncome = false;
  DateTime selectedDate = DateTime.now();
  String selectedTime = TimeOfDay.now().format(context);
}
```

#### **Step 3: Create ExpenseModel from user input**
```dart
void _saveTransaction() {
  final expense = ExpenseModel(
    id: Uuid().v4(),  // Generate unique ID
    title: titleController.text,
    category: selectedCategory,
    amount: double.parse(amountController.text),
    isIncome: isIncome,
    date: selectedDate,
    time: selectedTime,
    description: descriptionController.text,
    accountType: selectedAccountType,
    createdAt: DateTime.now(),
  );

  // Call service to save
  _expenseService.addTransaction(expense);
}
```

#### **Step 4: ExpenseService.addTransaction() - Save to Database**
```dart
Future<void> addTransaction(ExpenseModel transaction) async {
  // Insert into database
  await _dbHelper.insertTransaction(transaction);

  // Check for budget overspending (if it's an expense)
  if (!transaction.isIncome) {
    await _checkBudgetAlerts(transaction.date);
  }
}
```

#### **Step 5: DatabaseHelper.insertTransaction() - Execute INSERT**
```dart
Future<int> insertTransaction(ExpenseModel transaction) async {
  Database db = await database;
  
  // Convert model to Map
  Map<String, dynamic> data = {
    'title': transaction.title,
    'amount': transaction.amount,
    'category': transaction.category,
    'description': transaction.description,
    'date': transaction.date.toIso8601String().split('T')[0],
    'time': transaction.time,
    'isIncome': transaction.isIncome ? 1 : 0,
    'accountType': transaction.accountType,
    'createdAt': transaction.createdAt.toIso8601String(),
  };

  // Insert and return row ID
  return await db.insert('transactions', data);
}
```

---

## 4. DATA FLOW DIAGRAM

### **Reading Previous Data**
```
Database (SQLite)
    ↓
DatabaseHelper.getTransactions()
    ↓
ExpenseService.getTodayTransactions() / getMonthlyTransactions()
    ↓
ExpensesScreenNew._getFilteredTransactions()
    ↓
FutureBuilder → ListView/Display
    ↓
UI: Show Previous Transactions
```

### **Inserting New Data**
```
User Input (AddExpenseScreen)
    ↓
ExpenseModel Creation
    ↓
ExpenseService.addTransaction()
    ↓
DatabaseHelper.insertTransaction()
    ↓
Database.insert('transactions', data) → SQLite
    ↓
Data Saved
    ↓
_refreshData() → Reload Display
```

---

## 5. COMPLETE EXAMPLE: Adding & Displaying

### **Saving a new transaction:**
```dart
// Create expense
final newExpense = ExpenseModel(
  id: '1',
  title: 'Lunch',
  category: 'Food',
  amount: 850.00,
  isIncome: false,
  date: DateTime.now(),
  time: '12:30 PM',
  description: 'Lunch at restaurant',
  accountType: 'Cash',
  createdAt: DateTime.now(),
);

// Save to database
final expenseService = ExpenseService();
await expenseService.addTransaction(newExpense);

// Retrieve all today's transactions
List<ExpenseModel> todayTransactions = 
  await expenseService.getTodayTransactions();

print('Saved expense and retrieved ${todayTransactions.length} transactions');
```

### **Query examples:**
```dart
// Get all expenses (not income) for this month
await _expenseService.getTransactions(
  startDate: DateTime(2026, 4, 1),
  endDate: DateTime(2026, 4, 30),
  isIncome: false,
);

// Get all Food category transactions
await _expenseService.getTransactions(
  category: 'Food',
);

// Get only Bank account transactions
await _expenseService.getTransactions(
  accountType: 'Bank',
);

// Get income transactions in date range
await _expenseService.getTransactions(
  startDate: DateTime(2026, 3, 1),
  endDate: DateTime(2026, 4, 30),
  isIncome: true,
);
```

---

## 6. KEY FILES

| File | Purpose |
|------|---------|
| [database_helper.dart](database_helper.dart) | Database initialization & CRUD operations |
| [expense_model.dart](expense_model.dart) | Data model with toMap() & fromMap() |
| [expense_service.dart](expense_service.dart) | Business logic & convenience methods |
| [expenses_screen_new.dart](expenses_screen_new.dart) | UI - Display & refresh transactions |
| [add_expense_screen.dart](add_expense_screen.dart) | UI - User input for new transactions |

---

## 7. COMMON OPERATIONS

### Refresh after adding:
```dart
void _refreshData() {
  setState(() {
    _refreshKey = UniqueKey();  // Force FutureBuilder rebuild
  });
}
```

### Manual database query:
```dart
Database db = await DatabaseHelper().database;
final result = await db.query('transactions');
for (var row in result) {
  print('${row['title']}: LKR ${row['amount']}');
}
```

### Delete a transaction:
```dart
await _expenseService.deleteTransaction(transactionId);
_refreshData();
```

### Update a transaction:
```dart
expenseModel.amount = 1000;  // Modify
await _expenseService.updateTransaction(expenseModel);
_refreshData();
```

---

## Summary

✅ **Previous Data**: Loaded via `ExpenseService.getTransactions()` → `DatabaseHelper.getTransactions()` → SQLite query → Display in FutureBuilder

✅ **New Data**: User input → `ExpenseModel` → `ExpenseService.addTransaction()` → `DatabaseHelper.insertTransaction()` → SQLite INSERT

✅ **Refresh**: After insert, `_refreshData()` triggers FutureBuilder rebuild to show latest data
