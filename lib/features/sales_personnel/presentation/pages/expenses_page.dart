import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../domain/entities/sales_personnel_entities.dart';
import '../bloc/sales_personnel_bloc.dart';
import '../bloc/sales_personnel_event.dart';
import '../bloc/sales_personnel_state.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SalesPersonnelBloc>().add(const LoadExpensesEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.w700)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Record', icon: Icon(Icons.add_card_rounded, size: 20)),
            Tab(text: 'History', icon: Icon(Icons.history_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RecordExpenseForm(
            onSuccess: () {
              _tabController.animateTo(1);
              context.read<SalesPersonnelBloc>().add(const LoadExpensesEvent());
            },
          ),
          const _ExpensesList(),
        ],
      ),
    );
  }
}

class _RecordExpenseForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _RecordExpenseForm({required this.onSuccess});

  @override
  State<_RecordExpenseForm> createState() => _RecordExpenseFormState();
}

class _RecordExpenseFormState extends State<_RecordExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _expenseType = 'TRAVEL';
  DateTime _expenseDate = DateTime.now();
  final List<File> _receiptImages = [];
  final ImagePicker _picker = ImagePicker();

  static const List<Map<String, dynamic>> _expenseTypes = [
    {'value': 'TRAVEL', 'label': 'Travel', 'icon': Icons.directions_car_rounded},
    {'value': 'TRAIN', 'label': 'Train Ticket', 'icon': Icons.train_rounded},
    {'value': 'BUS', 'label': 'Bus Ticket', 'icon': Icons.directions_bus_rounded},
    {'value': 'HOTEL', 'label': 'Hotel Stay', 'icon': Icons.hotel_rounded},
    {'value': 'FOOD', 'label': 'Food & Meals', 'icon': Icons.restaurant_rounded},
    {'value': 'OTHER', 'label': 'Other', 'icon': Icons.receipt_long_rounded},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _captureReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null) setState(() => _receiptImages.add(File(image.path)));
  }

  Future<void> _pickReceiptFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => _receiptImages.add(File(image.path)));
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFDC2626))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SalesPersonnelBloc>().add(RecordExpenseEvent(
      expenseType: _expenseType,
      amount: double.parse(_amountController.text.trim()),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      receiptImageFiles: List.from(_receiptImages),
      expenseDate: _expenseDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesPersonnelBloc, SalesPersonnelState>(
      listener: (context, state) {
        if (state is ExpenseRecorded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense recorded!'), backgroundColor: Color(0xFFDC2626)),
          );
          _amountController.clear();
          _descriptionController.clear();
          setState(() => _receiptImages.clear());
          widget.onSuccess();
        } else if (state is SalesPersonnelError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expense Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _expenseTypes.map((type) {
                  final isSelected = _expenseType == type['value'];
                  return ChoiceChip(
                    avatar: Icon(type['icon'] as IconData, size: 18, color: isSelected ? const Color(0xFFDC2626) : Colors.grey[600]),
                    label: Text(type['label'] as String),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _expenseType = type['value'] as String),
                    selectedColor: const Color(0xFFFEE2E2),
                    labelStyle: TextStyle(color: isSelected ? const Color(0xFFDC2626) : Colors.grey[700], fontWeight: FontWeight.w600),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide(color: isSelected ? const Color(0xFFDC2626) : Colors.grey[300]!),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  if (double.tryParse(v) == null) return 'Enter valid amount';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFFDC2626)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2)),
                  filled: true, fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFFDC2626)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2)),
                  filled: true, fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFDC2626)),
                    const SizedBox(width: 12),
                    Text('${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}', style: const TextStyle(fontSize: 16)),
                    const Spacer(),
                    Text('Tap to change', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Receipt Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Capture bills using camera as proof', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  ..._receiptImages.asMap().entries.map((entry) => Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 80, height: 80, child: Image.file(entry.value, fit: BoxFit.cover))),
                    Positioned(right: 0, top: 0, child: GestureDetector(
                      onTap: () => setState(() => _receiptImages.removeAt(entry.key)),
                      child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)),
                    )),
                  ])),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(leading: const Icon(Icons.camera_alt, color: Color(0xFFDC2626)), title: const Text('Camera'), onTap: () { Navigator.pop(ctx); _captureReceipt(); }),
                      ListTile(leading: const Icon(Icons.photo_library, color: Color(0xFFDC2626)), title: const Text('Gallery'), onTap: () { Navigator.pop(ctx); _pickReceiptFromGallery(); }),
                    ]))),
                    child: Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3))),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, color: Color(0xFFDC2626), size: 24), SizedBox(height: 4), Text('Add', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11))])),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              BlocBuilder<SalesPersonnelBloc, SalesPersonnelState>(
                builder: (context, state) {
                  final isLoading = state is SalesPersonnelLoading;
                  return SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _submit,
                    icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
                    label: Text(isLoading ? 'Saving...' : 'Record Expense'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ));
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpensesList extends StatelessWidget {
  const _ExpensesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesPersonnelBloc, SalesPersonnelState>(
      builder: (context, state) {
        if (state is SalesPersonnelLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
        }
        if (state is ExpensesLoaded) {
          if (state.expenses.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No expenses recorded', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async { context.read<SalesPersonnelBloc>().add(const LoadExpensesEvent()); },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.expenses.length,
              itemBuilder: (context, index) => _buildExpenseCard(state.expenses[index]),
            ),
          );
        }
        return Center(child: ElevatedButton(
          onPressed: () => context.read<SalesPersonnelBloc>().add(const LoadExpensesEvent()),
          child: const Text('Load Expenses'),
        ));
      },
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'TRAIN': return Icons.train_rounded;
      case 'BUS': return Icons.directions_bus_rounded;
      case 'HOTEL': return Icons.hotel_rounded;
      case 'FOOD': return Icons.restaurant_rounded;
      case 'TRAVEL': return Icons.directions_car_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  Widget _buildExpenseCard(SalesExpense expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
          child: Icon(_getIcon(expense.expenseType), color: const Color(0xFFDC2626), size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.expenseType.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          if (expense.description != null && expense.description!.isNotEmpty)
            Text(expense.description!, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ])),
        Text('₹${expense.amount?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
      ]),
    );
  }
}
