import 'package:flutter/material.dart';

class PartPurchasePage extends StatelessWidget {
  const PartPurchasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          'Part Purchase',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Part Purchase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  child: const Text('View All Vendors Due'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.green),
                    const SizedBox(width: 6),
                    const Text('Paid')
                  ],
                ),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.orange),
                    const SizedBox(width: 6),
                    const Text('Partial Paid')
                  ],
                ),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.red),
                    const SizedBox(width: 6),
                    const Text('Credit')
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Column(
                      children: [
                        Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('₹0.00')
                      ],
                    ),
                    Column(
                      children: [
                        Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('₹0.00')
                      ],
                    ),
                    Column(
                      children: [
                        Text('CREDIT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('₹0.00')
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NET',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Income (by payment date)'),
                          SizedBox(height: 4),
                          Text('Expense'),
                          SizedBox(height: 4),
                          Text('Payable'),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('₹0.00'),
                          SizedBox(height: 4),
                          Text('₹0.00'),
                          SizedBox(height: 4),
                          Text('₹0.00 (Credit)'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '₹0.00',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}