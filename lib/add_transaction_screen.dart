import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/expense_service.dart';
import 'package:econosmart/expense_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool initialIsIncome;
  const AddTransactionScreen({super.key, this.initialIsIncome = false});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expenseService = ExpenseService();

  late bool _isIncome;
  String _selectedCategory = 'Food';
  String _selectedAccount = 'Cash';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _expenseCategories = [
    'Food',
    'Travel',
    'Bills',
    'Shopping',
    'Other'
  ];
  final List<String> _incomeCategories = [
    'Salary',
    'Business',
    'Investment',
    'Gift',
    'Other'
  ];
  final List<String> _accounts = ['Cash', 'Bank', 'Investment'];

  @override
  void initState() {
    super.initState();
    _isIncome = widget.initialIsIncome;
    _selectedCategory =
        _isIncome ? _incomeCategories[0] : _expenseCategories[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    final transaction = ExpenseModel(
      id: "0", // Database will generate actual ID
      title: _titleController.text.trim(),
      category: _selectedCategory,
      amount: amount,
      isIncome: _isIncome,
      date: _selectedDate,
      time: _selectedTime.format(context),
      description: _descriptionController.text.trim(),
      accountType: _selectedAccount,
      createdAt: DateTime.now(),
    );

    try {
      await _expenseService.addTransaction(transaction);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_isIncome ? "Income" : "Expense"} added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
      debugPrint('Database Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Add Transaction',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeToggle(),
              const SizedBox(height: 25),
              _buildInputField(
                  'Title', _titleController, Icons.edit, 'Enter title'),
              const SizedBox(height: 20),
              _buildInputField(
                  'Amount', _amountController, Icons.attach_money, '0.00',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: _buildDropdown(
                          'Category',
                          _isIncome ? _incomeCategories : _expenseCategories,
                          _selectedCategory,
                          (val) => setState(() => _selectedCategory = val!))),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _buildDropdown(
                          'Account',
                          _accounts,
                          _selectedAccount,
                          (val) => setState(() => _selectedAccount = val!))),
                ],
              ),
              const SizedBox(height: 20),
              _buildDateTimePicker(),
              const SizedBox(height: 20),
              _buildInputField('Description (Optional)', _descriptionController,
                  Icons.description, 'Add notes...',
                  maxLines: 3),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  onPressed: _saveTransaction,
                  child: Text('Save Transaction',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _toggleButton(false, 'Expense', Icons.arrow_upward, Colors.redAccent),
          _toggleButton(true, 'Income', Icons.arrow_downward, Colors.green),
        ],
      ),
    );
  }

  Widget _toggleButton(
      bool isIncome, String label, IconData icon, Color color) {
    bool isSelected = _isIncome == isIncome;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _isIncome = isIncome;
          _selectedCategory =
              isIncome ? _incomeCategories[0] : _expenseCategories[0];
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: isSelected ? color : Colors.grey,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      IconData icon, String hint,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppColors.textGrey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryTeal),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppColors.textGrey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(
                      value: e, child: Text(e, style: GoogleFonts.poppins())))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100));
              if (date != null) setState(() => _selectedDate = date);
            },
            child: _buildInfoBox(
                'Date',
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                Icons.calendar_today),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: InkWell(
            onTap: () async {
              final time = await showTimePicker(
                  context: context, initialTime: _selectedTime);
              if (time != null) setState(() => _selectedTime = time);
            },
            child: _buildInfoBox(
                'Time', _selectedTime.format(context), Icons.access_time),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppColors.textGrey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.primaryTeal),
            const SizedBox(width: 8),
            Text(value, style: GoogleFonts.poppins())
          ]),
        ),
      ],
    );
  }
}
