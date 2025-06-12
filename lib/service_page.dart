import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  List<dynamic> _services = [];
  List<bool> _isSelected = [];
  List<TextEditingController> _qtyControllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_services';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);
    setState(() {
      _services = data['data'];
      _isSelected = List.generate(_services.length, (_) => false);
      _qtyControllers = List.generate(
        _services.length,
            (i) => TextEditingController(text: '1'),
      );
      _isLoading = false;
    });
  }

  void _submitSelection() {
    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < _services.length; i++) {
      if (_isSelected[i]) {
        int qty = int.tryParse(_qtyControllers[i].text) ?? 1;
        result.add({
          "item_name": _services[i]['item_name'],
          "rate": _services[i]['rate'],
          "qty": qty,
        });
      }
    }
    Navigator.pop(context, result);
  }

  String _calculateAmount(int index) {
    int qty = int.tryParse(_qtyControllers[index].text) ?? 1;
    double rate = _services[index]['rate']?.toDouble() ?? 0.0;
    return (qty * rate).toStringAsFixed(2);
  }

  void _incrementQuantity(int index) {
    setState(() {
      int currentQty = int.tryParse(_qtyControllers[index].text) ?? 1;
      _qtyControllers[index].text = (currentQty + 1).toString();
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      int currentQty = int.tryParse(_qtyControllers[index].text) ?? 1;
      if (currentQty > 1) {
        _qtyControllers[index].text = (currentQty - 1).toString();
      }
    });
  }
  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (int i = 0; i < _services.length; i++) {
      if (_isSelected[i]) {
        int qty = int.tryParse(_qtyControllers[i].text) ?? 1;
        double rate = _services[i]['rate']?.toDouble() ?? 0.0;
        subtotal += qty * rate;
      }
    }
    return subtotal;
  }

  double _calculateTax(double subtotal) {
    return 20.0; // Fixed tax amount
  }


  double _calculateTotal() {
    double subtotal = _calculateSubtotal();
    double tax = _calculateTax(subtotal);
    return subtotal + tax;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Select Services')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final item = _services[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
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
                          if (!_isSelected[index]) {
                            _qtyControllers[index].text = '1';
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
                            item['item_name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Price: ₹${item['rate']}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isSelected[index])
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _decrementQuantity(index),
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
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _incrementQuantity(index),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Total: ₹${_calculateAmount(index)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSelected.contains(true)) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Subtotal:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "₹${_calculateSubtotal().toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tax (18%):",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "₹${_calculateTax(_calculateSubtotal()).toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),


              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₹${_calculateTotal().toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity, // Makes the button take full width
              child: ElevatedButton(
                onPressed: _submitSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14), // Optional: Adds vertical padding
                ),
                child: const Text(
                  "Add Selected Services",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          ],
        ),
      ),

    );
  }
}
