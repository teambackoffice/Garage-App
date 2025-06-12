import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentDuePage extends StatefulWidget {
  @override
  _PaymentDuePageState createState() => _PaymentDuePageState();
}

class _PaymentDuePageState extends State<PaymentDuePage> {
  List<dynamic> orders = [];
  bool isLoading = true;

  final String token = 'your-api-token-here'; // Replace with your actual token

  @override
  void initState() {
    super.initState();
    fetchPaymentDueOrders();
  }

  Future<void> fetchPaymentDueOrders() async {
    final url = Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.pay_sales_invoice');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'token $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        print("Error: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Exception: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchInvoiceDetails(String invoiceName) async {
    final url = Uri.parse('https://garage.teambackoffice.com/api/resource/Sales Invoice/$invoiceName');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'token $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Invoice: ${data["name"]}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${data["customer"]}'),
                  Text('Posting Date: ${data["posting_date"]}'),
                  Text('Due Date: ${data["due_date"]}'),
                  Text('Total: ₹${data["grand_total"]}'),
                  Text('Paid: ₹${data["paid_amount"]}'),
                  Text('Balance: ₹${data["outstanding_amount"]}'),
                  if (data["items"] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...data["items"].map<Widget>((item) => Text('- ${item["item_name"]}: ₹${item["amount"]}')).toList(),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
            ],
          ),
        );
      } else {
        print("Invoice fetch failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch invoice')));
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching invoice')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Due Orders'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text('No payment due orders'))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final invoices = order['sales_invoices'] as List<dynamic>;

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              title: Text('Customer: ${order["customer"] ?? "N/A"}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invoices.isNotEmpty)
                    ...invoices.map((invoice) => GestureDetector(
                      onTap: () => fetchInvoiceDetails(invoice['name']),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '- ${invoice["name"]} | ₹${invoice["grand_total"]}',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
