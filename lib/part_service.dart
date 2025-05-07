import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    const url =
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_all_parts';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _parts = data['data'];
          _isSelected = List.generate(_parts.length, (_) => false);
          _qtyControllers = List.generate(
            _parts.length,
                (i) => TextEditingController(text: '0'),
          );
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load parts');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load parts: $e')),
      );
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
        });
      }
    }
    Navigator.pop(context, result);
  }

  String _calculateAmount(int index) {
    int qty = int.tryParse(_qtyControllers[index].text) ?? 0;
    double rate = (_parts[index]['rate'] as num?)?.toDouble() ?? 0.0;
    return (qty * rate).toStringAsFixed(2);
  }

  @override
  void dispose() {
    for (var c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Parts'),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _parts.length,
        itemBuilder: (context, index) {
          final part = _parts[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
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
                          if (_isSelected[index]) {
                            _qtyControllers[index].text = '1';
                          } else {
                            _qtyControllers[index].text = '0';
                          }
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
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Price: ₹${part['rate']}",
                            style: TextStyle(
                                fontSize: w * 0.035,
                                color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isSelected[index]) const SizedBox(height: 8),
                if (_isSelected[index])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              int current =
                                  int.tryParse(_qtyControllers[index].text) ?? 0;
                              if (current > 1) {
                                setState(() {
                                  _qtyControllers[index].text =
                                      (current - 1).toString();
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
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              int current =
                                  int.tryParse(_qtyControllers[index].text) ?? 0;
                              setState(() {
                                _qtyControllers[index].text =
                                    (current + 1).toString();
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      Text(
                        "Total: ₹${_calculateAmount(index)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _submitSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Add Selected Parts",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
