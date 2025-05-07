import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  String? _amountLabel, _vendor, _repairOrder, _comment, _refNumber, _paymentChannel;
  String _paymentStatus = 'Paid';
  DateTime _expenseDate = DateTime.now();
  DateTime _paymentDate = DateTime.now();

  final TextEditingController _totalAmountController = TextEditingController();

  final List<String> _vendors = ['Vendor A', 'Vendor B'];
  final List<String> _channels = ['Cash', 'Card', 'Online'];

  Future<void> _pickDate({required bool isExpense}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpense ? _expenseDate : _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExpense) {
          _expenseDate = picked;
        } else {
          _paymentDate = picked;
        }
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    // Perform submit action here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Expense saved successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Expense', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField('Amount Label', onSaved: (val) => _amountLabel = val),
            _buildDropdown('Vendor', _vendors, (val) => setState(() => _vendor = val), value: _vendor),
            _buildTextField('Repair Order', enabled: false),
            _buildTextField('Total Amount', controller: _totalAmountController, keyboardType: TextInputType.number),
            _buildTextField('Comment', onSaved: (val) => _comment = val),
            _buildDatePickerField('Expense Date', _expenseDate, () => _pickDate(isExpense: true)),
            _buildTextField('Reference Number', onSaved: (val) => _refNumber = val),
            _buildPaymentToggle(),
            _buildDropdown('Payment Channel', _channels, (val) => setState(() => _paymentChannel = val), value: _paymentChannel),
            _buildDatePickerField('Payment Date', _paymentDate, () => _pickDate(isExpense: false)),
            const SizedBox(height: 10),
            _buildImageUpload(),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Expense'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Service'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Parts'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }

  Widget _buildTextField(String label,
      {bool enabled = true,
        TextInputType keyboardType = TextInputType.text,
        TextEditingController? controller,
        void Function(String?)? onSaved}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, void Function(String?) onChanged, {String? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(DateFormat('MMM dd yyyy').format(date)),
        ),
      ),
    );
  }

  Widget _buildPaymentToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => _paymentStatus = 'Paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _paymentStatus == 'Paid' ? Colors.green : Colors.grey.shade300,
              ),
              child: const Text('✔ PAID'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => _paymentStatus = 'Credit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _paymentStatus == 'Credit' ? Colors.green : Colors.grey.shade300,
              ),
              child: const Text('CREDIT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    return Row(
      children: [
        const Text("Image", style: TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.camera_alt),
          label: const Text("Add"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }
}