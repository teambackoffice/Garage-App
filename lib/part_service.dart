import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

class ServiceAndParts extends StatefulWidget {
  const ServiceAndParts({super.key});

  @override
  State<ServiceAndParts> createState() => _ServiceAndPartsState();
}

class _ServiceAndPartsState extends State<ServiceAndParts> {
  List<dynamic> _parts = [];
  List<bool> _isSelected = [];
  List<TextEditingController> _qtyControllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParts();
  }

  Future<void> _fetchParts() async {
    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_parts';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _parts = data['data'];
          _isSelected = List.generate(_parts.length, (_) => false);
          _qtyControllers = List.generate(_parts.length, (_) => TextEditingController(text: '0'));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load parts');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load parts: $e')));
    }
  }

  void _submitSelection() {
    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < _parts.length; i++) {
      int qty = int.tryParse(_qtyControllers[i].text) ?? 0;
      if (_isSelected[i] && qty > 0) {
        result.add({
          "item_name": _parts[i]['item_name'],
          "rate": _parts[i]['rate'],
          "qty": qty,
          "tax_rate": _parts[i]['tax_rate'] ?? 0.0,
        });
      }
    }

    double subtotal = _calculateTotalAmount();
    double taxAmount = _calculateTotalTax();
    double total = subtotal + taxAmount;

    Navigator.pop(context, {
      "items": result,
      "subtotal": subtotal,
      "tax": taxAmount,
      "total": total,
    });
  }

  String _calculateAmount(int index) {
    int qty = int.tryParse(_qtyControllers[index].text) ?? 0;
    double rate = (_parts[index]['rate'] as num?)?.toDouble() ?? 0.0;
    return (qty * rate).toStringAsFixed(2);
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (int i = 0; i < _parts.length; i++) {
      if (_isSelected[i]) {
        int qty = int.tryParse(_qtyControllers[i].text) ?? 0;
        double rate = (_parts[i]['rate'] as num?)?.toDouble() ?? 0.0;
        total += qty * rate;
      }
    }
    return total;
  }

  double _calculateTotalTax() {
    double totalTax = 0.0;
    for (int i = 0; i < _parts.length; i++) {
      if (_isSelected[i]) {
        int qty = int.tryParse(_qtyControllers[i].text) ?? 0;
        double tax = (_parts[i]['tax_rate'] as num?)?.toDouble() ?? 0.0;
        totalTax += qty * tax;
      }
    }
    return totalTax;
  }

  double _calculateTotalWithTax() => _calculateTotalAmount() + _calculateTotalTax();

  @override
  void dispose() {
    for (var c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Parts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 12,
              vertical: isTablet ? 16 : 8,
            ),
            itemCount: _parts.length,
            itemBuilder: (context, index) {
              final part = _parts[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _isSelected[index],
                          onChanged: (val) {
                            setState(() {
                              _isSelected[index] = val ?? false;
                              _qtyControllers[index].text = _isSelected[index] ? '1' : '0';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                part['item_name'],
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Price: ₹${part['rate']}, Tax: ₹${part['tax_rate'] ?? 0.0}",
                                style: TextStyle(
                                  fontSize: isTablet ? 15 : 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isSelected[index])
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    int current = int.tryParse(_qtyControllers[index].text) ?? 0;
                                    if (current > 1) {
                                      setState(() {
                                        _qtyControllers[index].text = (current - 1).toString();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextField(
                                    controller: _qtyControllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    int current = int.tryParse(_qtyControllers[index].text) ?? 0;
                                    setState(() {
                                      _qtyControllers[index].text = (current + 1).toString();
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                            Text(
                              "Total: ₹${_calculateAmount(index)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow("Subtotal", _calculateTotalAmount(), isTablet),
            _summaryRow("Tax Total", _calculateTotalTax(), isTablet),
            _summaryRow("Total", _calculateTotalWithTax(), isTablet),
            SizedBox(height: h*0.03),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  "Add Selected Parts",
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTablet ? 16 : 14)),
          Text("₹${value.toStringAsFixed(2)}", style: TextStyle(fontSize: isTablet ? 16 : 14)),
        ],
      ),
    );
  }
}
